/**
 * Forensic CDR/TDR/SDR Analyzer - Core Application Script
 * Manages forensic data state, CSV parsing, interactive mapping, network graphs, 
 * tower dump intersections, and mobile/desktop UI controls.
 */

// Global Application State
const state = {
  activeTab: 'dashboard',
  caseName: 'No Active Case',
  caseDescription: '',
  cdrRecords: [],
  tdrData: {}, // map of towerId -> array of records
  sdrDatabase: [], // array of SDR subscriber objects
  selectedNumber: null, // active suspect number under investigation
  
  // Mapping references
  map: null,
  mapMarkers: {},
  activePathLine: null,
  playbackMarker: null,
  playbackInterval: null,
  playbackIndex: 0,
  playbackSpeed: 1500, // ms per transition
  playbackData: [], // chronological call path data
  isPlaybackPlaying: false,

  // Network graph references
  network: null,
  networkData: { nodes: null, edges: null }
};

// Default center coordinates (New York City area for mock data)
const MAP_DEFAULT_CENTER = [40.7600, -73.9600];
const MAP_DEFAULT_ZOOM = 11;

document.addEventListener('DOMContentLoaded', () => {
  initUI();
  initMap();
  
  // Auto-load Mock Data on startup to wow the user immediately
  loadMockCase();
});

/**
 * Initialize UI listeners and navigation
 */
function initUI() {
  // Sidebar tab switching
  const menuItems = document.querySelectorAll('.menu-item');
  menuItems.forEach(item => {
    item.addEventListener('click', () => {
      const tabId = item.getAttribute('data-tab');
      switchTab(tabId);
    });
  });

  // Setup file input change listeners
  document.getElementById('cdr-file').addEventListener('change', (e) => handleCsvUpload(e, 'cdr'));
  document.getElementById('sdr-file').addEventListener('change', (e) => handleCsvUpload(e, 'sdr'));
  document.getElementById('tdr-file').addEventListener('change', (e) => handleCsvUpload(e, 'tdr'));
  document.getElementById('tower-file').addEventListener('change', (e) => handleCsvUpload(e, 'tower-registry'));
  document.getElementById('cdr-pdf-file').addEventListener('change', handlePdfUpload);

  // Map style dropdown listener
  const styleSelect = document.getElementById('map-style-select');
  if (styleSelect) {
    styleSelect.addEventListener('change', (e) => {
      setMapStyle(e.target.value);
    });
  }

  // Trigger file dialogs and manage drag-and-drop on zone elements
  document.querySelectorAll('.upload-zone').forEach(zone => {
    // Click to open dialog
    zone.addEventListener('click', (e) => {
      // Don't click file input if click was directly on input (avoids double fire)
      if (e.target.tagName !== 'INPUT') {
        const input = zone.querySelector('input[type="file"]');
        if (input) input.click();
      }
    });

    // Drag effects
    ['dragenter', 'dragover'].forEach(eventName => {
      zone.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        zone.classList.add('highlight');
      }, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
      zone.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        zone.classList.remove('highlight');
      }, false);
    });

    // Drop handler
    zone.addEventListener('drop', (e) => {
      const dt = e.dataTransfer;
      const files = dt.files;
      if (files && files.length > 0) {
        const input = zone.querySelector('input[type="file"]');
        if (input) {
          input.files = files;
          // Dispatch change event to trigger the parser handler
          const event = new Event('change', { bubbles: true });
          input.dispatchEvent(event);
        }
      }
    }, false);
  });

  // SDR search button
  document.getElementById('sdr-search-btn').addEventListener('click', performSdrSearch);
  document.getElementById('sdr-search-input').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') performSdrSearch();
  });

  // Tower intersection button
  document.getElementById('run-intersection-btn').addEventListener('click', runTowerIntersection);

  // Playback control buttons
  document.getElementById('play-btn').addEventListener('click', togglePlayback);
  document.getElementById('prev-btn').addEventListener('click', prevPlaybackStep);
  document.getElementById('next-btn').addEventListener('click', nextPlaybackStep);
  document.getElementById('speed-select').addEventListener('change', (e) => {
    state.playbackSpeed = parseInt(e.target.value);
    if (state.isPlaybackPlaying) {
      pausePlayback();
      playPlayback();
    }
  });
  document.getElementById('timeline-slider').addEventListener('input', (e) => {
    jumpToPlaybackStep(parseInt(e.target.value));
  });

  // Suspect filter clear button
  document.getElementById('clear-suspect-filter-btn').addEventListener('click', clearSuspectFilter);

  // CDR Card Drag and Drop Support
  const cdrCard = document.getElementById('cdr-card');
  if (cdrCard) {
    ['dragenter', 'dragover'].forEach(eventName => {
      cdrCard.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        cdrCard.classList.add('highlight');
      }, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
      cdrCard.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        cdrCard.classList.remove('highlight');
      }, false);
    });

    cdrCard.addEventListener('drop', (e) => {
      const dt = e.dataTransfer;
      const files = dt.files;
      if (files && files.length > 0) {
        const file = files[0];
        const fileName = file.name.toLowerCase();
        if (fileName.endsWith('.csv')) {
          const input = document.getElementById('cdr-file');
          if (input) {
            input.files = files;
            const event = new Event('change', { bubbles: true });
            input.dispatchEvent(event);
          }
        } else if (fileName.endsWith('.pdf')) {
          const input = document.getElementById('cdr-pdf-file');
          if (input) {
            input.files = files;
            const event = new Event('change', { bubbles: true });
            input.dispatchEvent(event);
          }
        } else {
          alert("Unsupported file format. Please drop a CDR CSV or PDF file.");
        }
      }
    }, false);
  }
}

/**
 * Switch navigation tabs
 */
function switchTab(tabId) {
  state.activeTab = tabId;
  
  // Update menu highlights
  document.querySelectorAll('.menu-item').forEach(item => {
    if (item.getAttribute('data-tab') === tabId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  // Update panel displays
  document.querySelectorAll('.tab-panel').forEach(panel => {
    if (panel.id === `${tabId}-tab`) {
      panel.classList.add('active');
    } else {
      panel.classList.remove('active');
    }
  });

  // Leaflet map needs size recalculations if shown
  if (tabId === 'map' && state.map) {
    setTimeout(() => {
      state.map.invalidateSize();
      fitMapToMarkers();
    }, 100);
  }

  // Network graph needs redraw if shown
  if (tabId === 'network') {
    setTimeout(renderNetworkGraph, 100);
  }
}

/**
 * Initialize Leaflet Map
 */
function initMap() {
  try {
    state.map = L.map('map-container', {
      zoomControl: true,
      attributionControl: false
    }).setView(MAP_DEFAULT_CENTER, MAP_DEFAULT_ZOOM);

    // Keep reference to tileLayer in state
    state.tileLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      maxZoom: 20
    }).addTo(state.map);
  } catch (err) {
    console.error("Leaflet Map loading failed:", err);
  }
}

function setMapStyle(style) {
  if (!state.map || !state.tileLayer) return;
  state.map.removeLayer(state.tileLayer);
  
  let urlTemplate = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  if (style === 'roadmap') {
    urlTemplate = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  } else if (style === 'satellite') {
    urlTemplate = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  } else if (style === 'terrain') {
    urlTemplate = 'https://mt1.google.com/vt/lyrs=t&x={x}&y={y}&z={z}';
  }
  
  state.tileLayer = L.tileLayer(urlTemplate, {
    maxZoom: 20
  }).addTo(state.map);
}

/**
 * Helper: Parse CSV String
 */
function detectDelimiter(firstLine) {
  const delimiters = [',', ';', '\t', '|'];
  let bestDelimiter = ',';
  let maxCount = -1;
  delimiters.forEach(d => {
    const count = (firstLine.match(new RegExp('\\' + d, 'g')) || []).length;
    if (count > maxCount) {
      maxCount = count;
      bestDelimiter = d;
    }
  });
  return bestDelimiter;
}

function normalizeCdrRow(row) {
  const normalized = {
    Timestamp: '',
    Caller: '',
    Recipient: '',
    Duration_Sec: '0',
    Type: 'Voice',
    Cell_Tower_ID: 'TWR-Unknown',
    IMEI: 'N/A',
    IMSI: 'N/A'
  };

  const keys = Object.keys(row);
  const findVal = (synonyms) => {
    const matchingKey = keys.find(k => {
      const cleanK = k.toLowerCase().replace(/[^a-z0-9]/g, '');
      return synonyms.some(syn => cleanK === syn.toLowerCase().replace(/[^a-z0-9]/g, ''));
    });
    return matchingKey ? row[matchingKey] : null;
  };

  normalized.Timestamp = findVal(['timestamp', 'datetime', 'date_time', 'date time', 'date', 'time', 'call_time', 'call date', 'calldate', 'setup_time', 'start_time', 'start time']) || '';
  normalized.Caller = findVal(['caller', 'calling_number', 'calling number', 'calling', 'caller_num', 'src', 'source', 'source_number', 'from', 'a_number', 'msisdn_a', 'msisdn']) || '';
  normalized.Recipient = findVal(['recipient', 'recipient_number', 'recipient number', 'dialed_number', 'dialed number', 'dialled_number', 'dialled number', 'dst', 'destination', 'dest', 'to', 'b_number', 'msisdn_b']) || '';
  normalized.Duration_Sec = findVal(['duration_sec', 'duration sec', 'duration', 'duration_seconds', 'duration seconds', 'duration_min', 'duration(sec)', 'call_duration', 'call duration']) || '0';
  normalized.Type = findVal(['type', 'call_type', 'call type', 'event_type', 'event type', 'sms/call', 'direction']) || 'Voice';
  normalized.Cell_Tower_ID = findVal(['cell_tower_id', 'cell tower id', 'tower_id', 'tower id', 'cell_id', 'cell id', 'cgi', 'lac', 'location', 'site_id', 'site id', 'tower', 'cell']) || 'TWR-Unknown';
  normalized.IMEI = findVal(['imei', 'imei_number', 'device_imei']) || 'N/A';
  normalized.IMSI = findVal(['imsi', 'imsi_number', 'sim_imsi']) || 'N/A';

  if (!normalized.Timestamp) {
    const fallbackKey = keys.find(k => k.toLowerCase().includes('date') || k.toLowerCase().includes('time'));
    if (fallbackKey) normalized.Timestamp = row[fallbackKey];
  }
  if (!normalized.Caller) {
    const fallbackKey = keys.find(k => k.toLowerCase().includes('call') || k.toLowerCase().includes('from') || k.toLowerCase().includes('src'));
    if (fallbackKey) normalized.Caller = row[fallbackKey];
  }
  if (!normalized.Recipient) {
    const fallbackKey = keys.find(k => k.toLowerCase().includes('recip') || k.toLowerCase().includes('to') || k.toLowerCase().includes('dest') || k.toLowerCase().includes('dst'));
    if (fallbackKey) normalized.Recipient = row[fallbackKey];
  }

  return normalized;
}

function normalizeTdrRow(row) {
  const normalized = {
    Timestamp: '',
    Phone_Number: '',
    IMSI: 'N/A',
    Signal_DBm: '-70'
  };

  const keys = Object.keys(row);
  const findVal = (synonyms) => {
    const matchingKey = keys.find(k => {
      const cleanK = k.toLowerCase().replace(/[^a-z0-9]/g, '');
      return synonyms.some(syn => cleanK === syn.toLowerCase().replace(/[^a-z0-9]/g, ''));
    });
    return matchingKey ? row[matchingKey] : null;
  };

  normalized.Timestamp = findVal(['timestamp', 'datetime', 'date_time', 'date time', 'date', 'time', 'call_time']) || '';
  normalized.Phone_Number = findVal(['phone_number', 'phone number', 'phone', 'number', 'mobile', 'msisdn']) || '';
  normalized.IMSI = findVal(['imsi', 'imsi_number']) || 'N/A';
  normalized.Signal_DBm = findVal(['signal_dbm', 'signal dbm', 'signal', 'power', 'dbm']) || '-70';

  return normalized;
}

function parseCSV(text) {
  const lines = text.split(/\r\n|\n/);
  if (lines.length === 0 || lines[0].trim() === '') return [];
  
  const delimiter = detectDelimiter(lines[0]);
  const headers = lines[0].split(delimiter).map(h => h.trim().replace(/^["']|["']$/g, ''));
  const results = [];
  
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    let insideQuote = false;
    let entries = [];
    let currentEntry = '';
    
    for (let char of line) {
      if (char === '"' || char === "'") {
        insideQuote = !insideQuote;
      } else if (char === delimiter && !insideQuote) {
        entries.push(currentEntry.trim());
        currentEntry = '';
      } else {
        currentEntry += char;
      }
    }
    entries.push(currentEntry.trim());

    if (entries.length === 0 || (entries.length === 1 && entries[0] === '')) continue;
    
    const obj = {};
    headers.forEach((header, index) => {
      let val = entries[index] || '';
      val = val.replace(/^["']|["']$/g, '');
      obj[header] = val;
    });
    results.push(obj);
  }
  
  return results;
}

function handleCsvUpload(event, type) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function(e) {
    const text = e.target.result;
    const parsed = parseCSV(text);
    
    if (parsed.length === 0) {
      alert("Failed to parse file. Please ensure it is a valid CSV.");
      return;
    }

    if (type === 'cdr') {
      state.cdrRecords = parsed.map(normalizeCdrRow);
      document.getElementById('cdr-file-status').innerHTML = `✓ loaded <strong>${parsed.length}</strong> calls`;
      processCdrData();
    } else if (type === 'sdr') {
      state.sdrDatabase = parsed;
      document.getElementById('sdr-file-status').innerHTML = `✓ loaded <strong>${parsed.length}</strong> subscribers`;
      updateDashboardStats();
    } else if (type === 'tdr') {
      // Create a simulated tower ID from filename or count
      const towerId = file.name.split('.')[0] || `TWR-${Math.floor(Math.random() * 1000)}`;
      state.tdrData[towerId] = parsed.map(normalizeTdrRow);
      document.getElementById('tdr-file-status').innerHTML = `✓ loaded tower dump <strong>${file.name}</strong> (${parsed.length} records)`;
      buildTowerIntersectionCheckboxes();
    } else if (type === 'tower-registry') {
      if (typeof MOCK_DATA === 'undefined') {
        MOCK_DATA = { towerRegistry: {} };
      }
      if (!MOCK_DATA.towerRegistry) {
        MOCK_DATA.towerRegistry = {};
      }
      parsed.forEach(row => {
        const idKey = Object.keys(row).find(k => k.toLowerCase() === 'cell_tower_id' || k.toLowerCase() === 'tower_id' || k.toLowerCase() === 'id');
        const nameKey = Object.keys(row).find(k => k.toLowerCase() === 'tower_name' || k.toLowerCase() === 'name');
        const latKey = Object.keys(row).find(k => k.toLowerCase() === 'latitude' || k.toLowerCase() === 'lat');
        const lngKey = Object.keys(row).find(k => k.toLowerCase() === 'longitude' || k.toLowerCase() === 'lng' || k.toLowerCase() === 'lon');
        
        if (idKey && latKey && lngKey) {
          const id = row[idKey];
          const name = nameKey ? row[nameKey] : `Tower ${id}`;
          const lat = parseFloat(row[latKey]);
          const lng = parseFloat(row[lngKey]);
          if (!isNaN(lat) && !isNaN(lng)) {
            MOCK_DATA.towerRegistry[id] = {
              name: name,
              lat: lat,
              lng: lng
            };
          }
        }
      });
      document.getElementById('tower-file-status').innerHTML = `✓ loaded <strong>${Object.keys(MOCK_DATA.towerRegistry).length}</strong> towers`;
      loadTowerMarkersOnMap();
      if (state.selectedNumber) {
        generateSuspectMapPath(state.selectedNumber);
      }
      buildTowerIntersectionCheckboxes();
    }
    
    updateDashboardStats();
  };
  reader.readAsText(file);
}

/**
 * Load Sample Mock Case ("Case Alpha")
 */
function loadMockCase() {
  if (typeof MOCK_DATA === 'undefined') {
    console.error("Mock data source file not loaded.");
    return;
  }

  // Load basic configurations
  state.caseName = MOCK_DATA.caseName;
  state.caseDescription = MOCK_DATA.description;
  
  // Update DOM case header values
  document.getElementById('case-title-badge').innerText = state.caseName;
  document.getElementById('db-case-title').innerText = state.caseName;
  document.getElementById('db-case-desc').innerText = state.caseDescription;
  
  // Load mock CDR
  state.cdrRecords = parseCSV(MOCK_DATA.cdrCsv);
  document.getElementById('cdr-file-status').innerHTML = `✓ Sample loaded (<strong>${state.cdrRecords.length}</strong> calls)`;

  // Load mock SDR
  state.sdrDatabase = MOCK_DATA.sdrDatabase;
  document.getElementById('sdr-file-status').innerHTML = `✓ Sample database loaded (<strong>${state.sdrDatabase.length}</strong> profiles)`;

  // Load mock TDR
  state.tdrData = {};
  MOCK_DATA.tdrTowers.forEach(t => {
    state.tdrData[t.id] = parseCSV(t.dumpCsv);
  });
  document.getElementById('tdr-file-status').innerHTML = `✓ loaded <strong>${MOCK_DATA.tdrTowers.length}</strong> tower dumps`;

  // Process and update displays
  processCdrData();
  buildTowerIntersectionCheckboxes();
  updateDashboardStats();

  // Draw visualizers
  renderNetworkGraph();
  loadTowerMarkersOnMap();
  
  // Auto select getaway driver suspect John Doe
  setSuspectUnderInvestigation("+1-555-0199");
}

/**
 * Process Call Detail Records
 */
function processCdrData() {
  if (state.cdrRecords.length === 0) return;

  // Build the call log table
  buildCdrTable();
  
  // Extract top contacts metric
  buildTopContactsList();
}

/**
 * Render CDR call log list
 */
function buildCdrTable(filterNum = null) {
  const tbody = document.getElementById('cdr-table-body');
  tbody.innerHTML = '';

  let records = state.cdrRecords;
  if (filterNum) {
    records = records.filter(r => r.Caller === filterNum || r.Recipient === filterNum);
  }

  records.forEach(r => {
    const tr = document.createElement('tr');
    
    // Highlight if belongs to target suspect
    const isSuspectCaller = state.selectedNumber && (r.Caller === state.selectedNumber);
    const isSuspectRecipient = state.selectedNumber && (r.Recipient === state.selectedNumber);
    
    if (isSuspectCaller || isSuspectRecipient) {
      tr.classList.add('highlight-suspect');
    }

    const callerClass = isSuspectCaller ? 'phone-num suspect' : 'phone-num';
    const recClass = isSuspectRecipient ? 'phone-num suspect' : 'phone-num';

    tr.innerHTML = `
      <td class="time-stamp">${r.Timestamp}</td>
      <td><span class="${callerClass}" onclick="setSuspectUnderInvestigation('${r.Caller}')">${r.Caller}</span></td>
      <td><span class="${recClass}" onclick="setSuspectUnderInvestigation('${r.Recipient}')">${r.Recipient}</span></td>
      <td>${r.Duration_Sec}s</td>
      <td><span class="badge badge-${r.Type.toLowerCase()}">${r.Type}</span></td>
      <td><span class="badge" style="background: rgba(245, 158, 11, 0.08); color: var(--accent-orange); border: 1px solid rgba(245, 158, 11, 0.25);">${r.Cell_Tower_ID}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

/**
 * Build list of top contacted phone numbers
 */
function buildTopContactsList() {
  const container = document.getElementById('top-contacts-list');
  container.innerHTML = '';

  const contactCounts = {};
  state.cdrRecords.forEach(r => {
    contactCounts[r.Caller] = (contactCounts[r.Caller] || 0) + 1;
    contactCounts[r.Recipient] = (contactCounts[r.Recipient] || 0) + 1;
  });

  // Sort contact list
  const sorted = Object.entries(contactCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  sorted.forEach(([number, count]) => {
    // Cross-ref with SDR to find name
    const sdr = state.sdrDatabase.find(s => s.phone === number);
    const displayName = sdr ? `${sdr.name} (${sdr.role || 'Associate'})` : 'Unknown Subject';

    const item = document.createElement('div');
    item.className = 'menu-item';
    if (state.selectedNumber === number) item.classList.add('active');
    
    item.style.justifyContent = 'space-between';
    item.style.padding = '10px 14px';
    item.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 2px;">
        <span class="phone-num ${sdr ? 'suspect' : ''}" style="font-size: 0.85rem;">${number}</span>
        <span style="font-size: 0.7rem; color: var(--text-dim);">${displayName}</span>
      </div>
      <span class="badge badge-voice">${count} interactions</span>
    `;
    item.addEventListener('click', () => setSuspectUnderInvestigation(number));
    container.appendChild(item);
  });
}

/**
 * Set target number under investigation
 */
function setSuspectUnderInvestigation(number) {
  state.selectedNumber = number;
  
  // Highlight in sidebar/tables
  document.getElementById('target-suspect-indicator').innerHTML = `
    Active Suspect: <span class="phone-num suspect" style="font-size: 0.95rem; margin-left: 6px;">${number}</span>
  `;
  document.getElementById('clear-suspect-filter-btn').style.display = 'inline-flex';

  // Update call logs, map paths and details
  buildCdrTable(number);
  buildTopContactsList();
  
  // Sync SDR Tab input and run search
  document.getElementById('sdr-search-input').value = number;
  performSdrSearch();

  // Regenerate Map paths and timeline
  generateSuspectMapPath(number);

  // Redraw Network to highlight active suspect
  renderNetworkGraph();

  // If on Dashboard, scroll down to the Call table
  if (state.activeTab === 'dashboard') {
    // Optionally redirect tab or keep on dashboard
  }
}

/**
 * Clear the current suspect filter
 */
function clearSuspectFilter() {
  state.selectedNumber = null;
  document.getElementById('target-suspect-indicator').innerHTML = 'Select a phone number to trace';
  document.getElementById('clear-suspect-filter-btn').style.display = 'none';
  
  // Reset lists
  buildCdrTable();
  buildTopContactsList();
  
  // Reset Map
  clearPlayback();
  if (state.activePathLine) {
    state.map.removeLayer(state.activePathLine);
    state.activePathLine = null;
  }
  
  renderNetworkGraph();
}

/**
 * Update Dashboard Stats Cards
 */
function updateDashboardStats() {
  // Total CDR calls
  document.getElementById('stat-total-calls').innerText = state.cdrRecords.length;
  
  // Unique suspects count (from SDR database)
  document.getElementById('stat-suspects-count').innerText = state.sdrDatabase.length;

  // Active Tower locations count
  const towers = new Set();
  state.cdrRecords.forEach(c => { if(c.Cell_Tower_ID) towers.add(c.Cell_Tower_ID); });
  Object.keys(state.tdrData).forEach(t => towers.add(t));
  document.getElementById('stat-towers-count').innerText = towers.size;

  // Overlaps count
  document.getElementById('stat-overlaps-count').innerText = Object.keys(state.tdrData).length;
}

/**
 * Vis.js Network Graph Drawer
 */
function renderNetworkGraph() {
  const container = document.getElementById('network-container');
  if (!container) return;

  if (typeof vis === 'undefined') {
    console.warn("vis.js is not loaded.");
    container.innerHTML = `
      <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; padding: 20px; text-align: center; color: var(--text-muted);">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width: 48px; height: 48px; stroke: var(--text-dim); margin-bottom: 12px;">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
        <span style="font-weight: 600; font-size: 0.95rem; margin-bottom: 4px; color: var(--text-main);">Visualization Offline</span>
        <span style="font-size: 0.8rem; max-width: 320px; line-height: 1.4;">Network Graph requires an active internet connection to load the Vis-Network library.</span>
      </div>
    `;
    return;
  }

  if (state.cdrRecords.length === 0) return;

  const nodesMap = {};
  const edgesMap = {};

  // Extract unique nodes and links from calls
  state.cdrRecords.forEach(call => {
    const caller = call.Caller;
    const recipient = call.Recipient;

    if (!nodesMap[caller]) {
      const sdr = state.sdrDatabase.find(s => s.phone === caller);
      nodesMap[caller] = {
        id: caller,
        label: sdr ? `${sdr.name}\n${caller}` : caller,
        color: caller === state.selectedNumber ? '#ef4444' : (sdr ? '#f59e0b' : '#06b6d4'),
        font: { color: '#f8fafc', size: 12, face: 'Inter' },
        shape: 'dot',
        size: caller === state.selectedNumber ? 22 : (sdr ? 16 : 12),
        borderWidth: 2,
        title: sdr ? `Suspect: ${sdr.name}\nRole: ${sdr.role || 'Unspecified'}` : `Call contact: ${caller}`
      };
    }

    if (!nodesMap[recipient]) {
      const sdr = state.sdrDatabase.find(s => s.phone === recipient);
      nodesMap[recipient] = {
        id: recipient,
        label: sdr ? `${sdr.name}\n${recipient}` : recipient,
        color: recipient === state.selectedNumber ? '#ef4444' : (sdr ? '#f59e0b' : '#06b6d4'),
        font: { color: '#f8fafc', size: 12, face: 'Inter' },
        shape: 'dot',
        size: recipient === state.selectedNumber ? 22 : (sdr ? 16 : 12),
        borderWidth: 2,
        title: sdr ? `Suspect: ${sdr.name}\nRole: ${sdr.role || 'Unspecified'}` : `Call contact: ${recipient}`
      };
    }

    // Connect them
    const edgeId = [caller, recipient].sort().join('-');
    if (!edgesMap[edgeId]) {
      edgesMap[edgeId] = {
        from: caller,
        to: recipient,
        value: 1,
        color: { color: '#334155', highlight: '#06b6d4' }
      };
    } else {
      edgesMap[edgeId].value += 1;
    }
  });

  const nodes = new vis.DataSet(Object.values(nodesMap));
  const edges = new vis.DataSet(Object.values(edgesMap));

  const data = { nodes, edges };
  const options = {
    nodes: {
      scaling: { min: 10, max: 30 }
    },
    edges: {
      scaling: { min: 1, max: 8 },
      smooth: { type: 'continuous' }
    },
    physics: {
      barnesHut: {
        gravitationalConstant: -2000,
        centralGravity: 0.3,
        springLength: 95
      }
    },
    interaction: {
      hover: true,
      tooltipDelay: 200
    }
  };

  // Build the network
  state.network = new vis.Network(container, data, options);

  // Click handler to trace node
  state.network.on("click", (params) => {
    if (params.nodes.length > 0) {
      const selectedNode = params.nodes[0];
      setSuspectUnderInvestigation(selectedNode);
    }
  });
}

/**
 * TDR: Populate tower dumps selection list
 */
function buildTowerIntersectionCheckboxes() {
  const container = document.getElementById('tower-intersection-list');
  container.innerHTML = '';

  const towerIds = Object.keys(state.tdrData);
  if (towerIds.length === 0) {
    container.innerHTML = `<span style="color: var(--text-dim); font-size: 0.85rem;">No tower dumps loaded.</span>`;
    return;
  }

  towerIds.forEach(id => {
    const label = document.createElement('label');
    label.className = 'tower-checkbox-item';
    
    // Cross check names if available in mock data registry
    let towerName = id;
    if (typeof MOCK_DATA !== 'undefined' && MOCK_DATA.towerRegistry[id]) {
      towerName = `${MOCK_DATA.towerRegistry[id].name} (${id})`;
    }

    label.innerHTML = `
      <input type="checkbox" name="tower-select" value="${id}" checked>
      <span>${towerName}</span>
      <span class="overlap-stat">${state.tdrData[id].length} SIMs</span>
    `;
    container.appendChild(label);
  });
}

/**
 * TDR: Execute intersection of numbers present in multiple towers
 */
function runTowerIntersection() {
  const checkedCheckboxes = document.querySelectorAll('input[name="tower-select"]:checked');
  const selectedTowers = Array.from(checkedCheckboxes).map(cb => cb.value);

  const resultsDiv = document.getElementById('intersection-results-area');
  const resultsTbody = document.getElementById('intersection-table-body');
  resultsTbody.innerHTML = '';

  if (selectedTowers.length < 2) {
    resultsDiv.style.display = 'none';
    alert("Please select at least 2 towers to compute intersection overlaps.");
    return;
  }

  // Find overlap
  const phonePresence = {}; // phone -> set of towerIds
  
  selectedTowers.forEach(tId => {
    const records = state.tdrData[tId] || [];
    records.forEach(rec => {
      const phone = rec.Phone_Number;
      if (!phonePresence[phone]) {
        phonePresence[phone] = new Set();
      }
      phonePresence[phone].add(tId);
    });
  });

  // Filter numbers present in ALL selected towers
  const intersectionResults = [];
  Object.entries(phonePresence).forEach(([phone, presenceSet]) => {
    if (presenceSet.size === selectedTowers.length) {
      // Find detail records for this number (timestamps and signals)
      const details = [];
      selectedTowers.forEach(tId => {
        const found = state.tdrData[tId].filter(r => r.Phone_Number === phone);
        found.forEach(f => {
          details.push({ tower: tId, time: f.Timestamp, signal: f.Signal_DBm });
        });
      });
      
      intersectionResults.push({
        phone,
        matchCount: presenceSet.size,
        details
      });
    }
  });

  if (intersectionResults.length === 0) {
    resultsDiv.style.display = 'block';
    resultsTbody.innerHTML = `
      <tr>
        <td colspan="4" style="text-align: center; color: var(--text-dim); padding: 32px 0;">
          No matching phone numbers found in all ${selectedTowers.length} selected tower dumps.
        </td>
      </tr>
    `;
    return;
  }

  // Populate results
  intersectionResults.forEach(res => {
    // Cross ref SDR
    const sdr = state.sdrDatabase.find(s => s.phone === res.phone);
    const nameStr = sdr ? sdr.name : 'Unknown';
    const roleStr = sdr ? `<span class="badge badge-suspect">${sdr.role || 'Suspect'}</span>` : '<span class="badge" style="background: rgba(255,255,255,0.05);">No SDR Record</span>';

    const tr = document.createElement('tr');
    tr.className = 'highlight-suspect'; // High highlight to show they matched all scenes
    tr.innerHTML = `
      <td>
        <span class="phone-num suspect" onclick="setSuspectUnderInvestigation('${res.phone}')">${res.phone}</span>
      </td>
      <td><strong>${nameStr}</strong></td>
      <td>${roleStr}</td>
      <td>
        <span class="badge" style="background: rgba(16, 185, 129, 0.12); color: var(--accent-green); border: 1px solid rgba(16, 185, 129, 0.25);">
          All ${res.matchCount} Towers Matched
        </span>
      </td>
    `;
    resultsTbody.appendChild(tr);
  });

  resultsDiv.style.display = 'block';
  
  // Update overlay stats count on dashboard
  document.getElementById('stat-overlaps-count').innerText = intersectionResults.length;
}

/**
 * SDR: Search subscriber directory
 */
function performSdrSearch() {
  const query = document.getElementById('sdr-search-input').value.trim();
  const cardContainer = document.getElementById('sdr-profile-container');
  const detailsDiv = document.getElementById('sdr-profile-details');
  const emptyDiv = document.getElementById('sdr-profile-empty');
  
  if (!query) {
    detailsDiv.style.display = 'none';
    emptyDiv.style.display = 'flex';
    return;
  }

  // Find by phone, name, or alternate phone
  const match = state.sdrDatabase.find(s => 
    s.phone.includes(query) || 
    s.name.toLowerCase().includes(query.toLowerCase()) || 
    (s.alternatePhone && s.alternatePhone.includes(query))
  );

  if (!match) {
    detailsDiv.style.display = 'none';
    emptyDiv.style.display = 'flex';
    emptyDiv.querySelector('.empty-state-title').innerText = "No Subscriber Record Found";
    emptyDiv.querySelector('.empty-state-desc').innerText = `No matches for '${query}' in the current SDR directory database.`;
    return;
  }

  // Populate details card
  emptyDiv.style.display = 'none';
  detailsDiv.style.display = 'block';

  document.getElementById('sdr-val-name').innerText = match.name;
  document.getElementById('sdr-val-phone').innerText = match.phone;
  document.getElementById('sdr-val-age').innerText = `${match.age || 'N/A'} / ${match.gender || 'N/A'}`;
  document.getElementById('sdr-val-id').innerText = `${match.idType || 'ID Proof'}: ${match.idNumber || 'N/A'}`;
  document.getElementById('sdr-val-address').innerText = match.address || 'Address Unknown';
  document.getElementById('sdr-val-activation').innerText = match.activationDate || 'N/A';
  document.getElementById('sdr-val-alternate').innerText = match.alternatePhone || 'None Registered';
  document.getElementById('sdr-val-notes').innerText = match.notes || 'No notes compiled.';

  // Draw custom avatar silhouette
  const avatarBox = document.getElementById('sdr-profile-avatar-svg');
  // Simple custom avatar generation based on name
  const isFemale = match.gender && match.gender.toLowerCase() === 'female';
  avatarBox.innerHTML = isFemale ? 
    `<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3 0 1.25-.76 2.32-1.85 2.77C14.07 11.23 15 12.5 15 14h-6c0-1.5.93-2.77 1.85-3.23C9.76 10.32 9 9.25 9 8c0-1.66 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08s5.97 1.09 6 3.08c-1.29 1.94-3.5 3.22-6 3.22z" fill="#ec4899"/>` : 
    `<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08s5.97 1.09 6 3.08c-1.29 1.94-3.5 3.22-6 3.22z" fill="#0ea5e9"/>`;

  // Update investigative title/role
  const roleTitle = document.getElementById('sdr-val-role');
  roleTitle.innerText = match.role || 'Subject of Investigation';
  if (match.role && match.role.toLowerCase().includes('suspect')) {
    roleTitle.style.background = 'rgba(239, 68, 68, 0.15)';
    roleTitle.style.color = '#ef4444';
    roleTitle.style.border = '1px solid rgba(239, 68, 68, 0.3)';
  } else {
    roleTitle.style.background = 'rgba(255, 255, 255, 0.05)';
    roleTitle.style.color = 'var(--text-main)';
    roleTitle.style.border = '1px solid var(--border-color)';
  }
}

/**
 * GIS Map: Load tower marker hubs on map
 */
function loadTowerMarkersOnMap() {
  if (!state.map) return;

  // Clear existing markers
  Object.values(state.mapMarkers).forEach(m => state.map.removeLayer(m));
  state.mapMarkers = {};

  const towersRegistry = (typeof MOCK_DATA !== 'undefined') ? MOCK_DATA.towerRegistry : {};

  Object.entries(towersRegistry).forEach(([id, t]) => {
    // Custom pulsing marker icon using HTML/CSS
    const customIcon = L.divIcon({
      html: `<div class="pulse-ring"></div><div style="background-color: var(--accent-orange); width: 10px; height: 10px; border-radius: 50%;"></div>`,
      className: 'tower-map-marker',
      iconSize: [24, 24]
    });

    const marker = L.marker([t.lat, t.lng], { icon: customIcon }).addTo(state.map);
    
    // Bind detailed popup
    marker.bindPopup(`
      <div style="color: var(--text-main); font-family: 'Inter', sans-serif;">
        <h4 style="color: var(--accent-orange); margin-bottom: 4px;">Cell Tower Hub</h4>
        <strong>${t.name}</strong><br>
        Tower ID: <code style="color: var(--accent-cyan); font-family: 'Fira Code';">${id}</code><br>
        Location: <code>${t.lat.toFixed(4)}, ${t.lng.toFixed(4)}</code>
      </div>
    `);

    state.mapMarkers[id] = marker;
  });

  fitMapToMarkers();
}

/**
 * Fit Map view bounds to tower markers
 */
function fitMapToMarkers() {
  if (!state.map) return;
  const markers = Object.values(state.mapMarkers);
  if (markers.length === 0) return;

  const group = new L.featureGroup(markers);
  state.map.fitBounds(group.getBounds().pad(0.15));
}

/**
 * GIS Map: Draw travel route path of suspect based on chronologic cell tower connects
 */
function generateSuspectMapPath(number) {
  if (!state.map) return;

  // Clear previous paths/markers
  clearPlayback();
  if (state.activePathLine) {
    state.map.removeLayer(state.activePathLine);
    state.activePathLine = null;
  }

  // Get chronological calls involving this number
  const timelineCalls = state.cdrRecords
    .filter(r => r.Caller === number || r.Recipient === number)
    .sort((a, b) => new Date(a.Timestamp) - new Date(b.Timestamp));

  if (timelineCalls.length === 0) {
    document.getElementById('map-timeline-panel').style.display = 'none';
    return;
  }

  const towersRegistry = (typeof MOCK_DATA !== 'undefined') ? MOCK_DATA.towerRegistry : {};
  const latlngs = [];
  const validPlaybackSteps = [];

  timelineCalls.forEach(call => {
    const tId = call.Cell_Tower_ID;
    let tower = towersRegistry[tId];
    
    // Fallback coordinate generator for unknown towers
    if (!tower && tId && tId !== 'TWR-Unknown') {
      let baseLat = MAP_DEFAULT_CENTER[0];
      let baseLng = MAP_DEFAULT_CENTER[1];
      const existingTowers = Object.values(towersRegistry);
      if (existingTowers.length > 0) {
        baseLat = existingTowers[0].lat;
        baseLng = existingTowers[0].lng;
      }
      
      let hash = 0;
      for (let i = 0; i < tId.length; i++) {
        hash = tId.charCodeAt(i) + ((hash << 5) - hash);
      }
      const latOffset = ((hash % 100) / 2000);
      const lngOffset = (((hash >> 8) % 100) / 2000);
      
      tower = {
        name: `${tId} (Estimated)`,
        lat: baseLat + latOffset,
        lng: baseLng + lngOffset
      };
      
      towersRegistry[tId] = tower;
      
      if (state.map && !state.mapMarkers[tId]) {
        const customIcon = L.divIcon({
          html: `<div class="pulse-ring" style="border-color: var(--accent-cyan);"></div><div style="background-color: var(--accent-cyan); width: 10px; height: 10px; border-radius: 50%;"></div>`,
          className: 'tower-map-marker',
          iconSize: [24, 24]
        });
        const marker = L.marker([tower.lat, tower.lng], { icon: customIcon }).addTo(state.map);
        marker.bindPopup(`
          <div style="color: var(--text-main); font-family: 'Inter', sans-serif;">
            <h4 style="color: var(--accent-cyan); margin-bottom: 4px;">Estimated Tower Hub</h4>
            <strong>${tower.name}</strong><br>
            Tower ID: <code style="color: var(--accent-cyan); font-family: 'Fira Code';">${tId}</code><br>
            Location: <code>${tower.lat.toFixed(4)}, ${tower.lng.toFixed(4)}</code>
          </div>
        `);
        state.mapMarkers[tId] = marker;
      }
    }

    if (tower) {
      const coord = [tower.lat, tower.lng];
      latlngs.push(coord);
      validPlaybackSteps.push({
        coord,
        time: call.Timestamp,
        towerName: tower.name,
        towerId: tId,
        type: call.Type,
        recipient: call.Caller === number ? call.Recipient : call.Caller,
        direction: call.Caller === number ? 'Outgoing' : 'Incoming'
      });
    }
  });

  if (latlngs.length < 2) {
    document.getElementById('map-timeline-panel').style.display = 'none';
    return;
  }

  // Draw dashed trace polyline
  state.activePathLine = L.polyline(latlngs, {
    color: '#06b6d4',
    weight: 3,
    dashArray: '8, 8',
    opacity: 0.75
  }).addTo(state.map);

  // Setup playback details
  state.playbackData = validPlaybackSteps;
  state.playbackIndex = 0;
  
  // Show play bar overlay
  document.getElementById('map-timeline-panel').style.display = 'flex';
  
  // Set slider boundaries
  const slider = document.getElementById('timeline-slider');
  slider.max = validPlaybackSteps.length - 1;
  slider.value = 0;
  
  // Show initial position
  jumpToPlaybackStep(0);
}

/**
 * Map Timeline Playback: Jump to step
 */
function jumpToPlaybackStep(index) {
  if (index < 0 || index >= state.playbackData.length) return;
  state.playbackIndex = index;

  const step = state.playbackData[index];
  
  // Update slider position
  document.getElementById('timeline-slider').value = index;

  // Update text labels
  document.getElementById('timeline-time').innerText = step.time;
  document.getElementById('timeline-tower-info').innerText = `${step.towerName} (${step.towerId})`;
  document.getElementById('timeline-desc').innerHTML = `
    ${step.direction} ${step.type} call to/from <strong class="phone-num" style="color:#f8fafc;">${step.recipient}</strong>
  `;

  // Draw or update moving target marker
  if (!state.playbackMarker) {
    const radarIcon = L.divIcon({
      html: `<div style="background-color: var(--accent-red); width: 14px; height: 14px; border-radius: 50%; border: 2px solid #ffffff; box-shadow: 0 0 10px rgba(239,68,68,0.8); z-index: 999;"></div>`,
      className: 'target-playback-marker',
      iconSize: [14, 14]
    });
    state.playbackMarker = L.marker(step.coord, { icon: radarIcon }).addTo(state.map);
  } else {
    state.playbackMarker.setLatLng(step.coord);
  }

  // Pan map to follow
  state.map.panTo(step.coord);
}

/**
 * Toggle map play/pause
 */
function togglePlayback() {
  if (state.isPlaybackPlaying) {
    pausePlayback();
  } else {
    playPlayback();
  }
}

function playPlayback() {
  if (state.playbackData.length === 0) return;
  state.isPlaybackPlaying = true;
  document.getElementById('play-btn').innerHTML = '⏸ Pause';

  state.playbackInterval = setInterval(() => {
    let nextIndex = state.playbackIndex + 1;
    if (nextIndex >= state.playbackData.length) {
      nextIndex = 0; // loop back
    }
    jumpToPlaybackStep(nextIndex);
  }, state.playbackSpeed);
}

function pausePlayback() {
  state.isPlaybackPlaying = false;
  document.getElementById('play-btn').innerHTML = '▶ Play';
  if (state.playbackInterval) {
    clearInterval(state.playbackInterval);
    state.playbackInterval = null;
  }
}

function prevPlaybackStep() {
  pausePlayback();
  let index = state.playbackIndex - 1;
  if (index < 0) index = state.playbackData.length - 1;
  jumpToPlaybackStep(index);
}

function nextPlaybackStep() {
  pausePlayback();
  let index = state.playbackIndex + 1;
  if (index >= state.playbackData.length) index = 0;
  jumpToPlaybackStep(index);
}

function clearPlayback() {
  pausePlayback();
  if (state.playbackMarker) {
    state.map.removeLayer(state.playbackMarker);
    state.playbackMarker = null;
  }
  state.playbackData = [];
  state.playbackIndex = 0;
}

/**
 * Handle PDF File Upload
 */
function handlePdfUpload(event) {
  const file = event.target.files[0];
  if (!file) return;

  if (typeof pdfjsLib === 'undefined') {
    alert("PDF library (pdf.js) is not loaded. Please connect to the internet to parse PDF files.");
    return;
  }

  // Set worker path
  pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.4.120/pdf.worker.min.js';

  const reader = new FileReader();
  reader.onload = async function(e) {
    const buffer = e.target.result;
    try {
      document.getElementById('cdr-file-status').innerHTML = `⏳ Initializing PDF reader...`;
      const pdf = await pdfjsLib.getDocument({ data: new Uint8Array(buffer) }).promise;
      let fullText = '';
      
      document.getElementById('cdr-file-status').innerHTML = `⏳ Reading pages (0/${pdf.numPages})...`;
      
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        
        // Map text items to strings and join
        const pageText = textContent.items.map(item => item.str).join(' ');
        fullText += pageText + '\n';
        
        document.getElementById('cdr-file-status').innerHTML = `⏳ Reading pages (${i}/${pdf.numPages})...`;
      }
      
      // Parse CDR records from extracted text
      const parsedRecords = parseCdrFromText(fullText);
      
      if (parsedRecords.length === 0) {
        alert("Heuristic scanner was unable to parse CDR entries from this PDF. Please verify it contains text call logs.");
        document.getElementById('cdr-file-status').innerHTML = `<span style="color:var(--accent-red)">✗ Failed to parse PDF</span>`;
        return;
      }
      
      state.cdrRecords = parsedRecords;
      document.getElementById('cdr-file-status').innerHTML = `✓ parsed PDF: loaded <strong>${parsedRecords.length}</strong> calls`;
      processCdrData();
      updateDashboardStats();
      
      // Re-render visualizers
      renderNetworkGraph();
      loadTowerMarkersOnMap();
    } catch (err) {
      console.error("PDF Parsing error: ", err);
      alert("Failed to parse PDF document: " + err.message);
      document.getElementById('cdr-file-status').innerHTML = `<span style="color:var(--accent-red)">✗ Error reading PDF</span>`;
    }
  };
  reader.readAsArrayBuffer(file);
}

/**
 * Heuristic CDR Regex Parser
 */
function parseCdrFromText(text) {
  const lines = text.split('\n');
  const records = [];
  
  // Date time matching with wide format support
  const datePattern = /\b\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}\b|\b\d{1,2}[-/.\s](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/.\s]\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/.\s]\d{1,2}[-,/.\s]+\d{2,4}\b/i;
  const timePattern = /\b\d{1,2}:\d{2}(?::\d{2})?(?:\s*[APap][Mm])?\b/;
  const candidatePattern = /\+?[\d\s-]{7,20}/g;

  lines.forEach(line => {
    const trimmed = line.trim();
    if (!trimmed) return;
    
    // Look for Date/Time matches
    const dateMatch = trimmed.match(datePattern);
    const timeMatch = trimmed.match(timePattern);
    if (!dateMatch || !timeMatch) return;
    
    const timestamp = `${dateMatch[0]} ${timeMatch[0]}`;
    
    // Strip date/time from phone matching string to prevent collision
    let lineForPhones = trimmed.replace(dateMatch[0], ' ').replace(timeMatch[0], ' ');
    
    const candidates = lineForPhones.match(candidatePattern) || [];
    const cleanPhones = [];
    
    candidates.forEach(c => {
      const digits = c.replace(/\D/g, '');
      if (digits.length >= 7 && digits.length <= 14) {
        cleanPhones.push(c.trim());
      }
    });
    
    if (cleanPhones.length === 0) return;
    const caller = cleanPhones[0];
    const recipient = cleanPhones.length > 1 ? cleanPhones[1] : 'Unknown';
    
    // Scan for call duration
    let durationSec = 45; // default fallback
    const durationWordMatch = trimmed.match(/\b(\d+)\s*(?:s|sec|seconds)\b/i);
    
    if (durationWordMatch) {
      durationSec = parseInt(durationWordMatch[1]);
    } else {
      const possibleNums = lineForPhones.match(/\b\d{1,4}\b/g) || [];
      for (let num of possibleNums) {
        const parsedNum = parseInt(num);
        if (parsedNum > 0 && parsedNum < 7200) {
          durationSec = parsedNum;
          break;
        }
      }
    }
    
    // Call Type (SMS vs Voice)
    let type = 'Voice';
    if (trimmed.match(/\b(SMS|TEXT|MESSAGE|MSG)\b/i)) {
      type = 'SMS';
    }
    
    // Cell Tower ID
    let towerId = 'TWR-Unknown';
    const towerMatch = trimmed.match(/\b(TWR-[\w-]+|Cell-[\w-]+)\b/i);
    if (towerMatch) {
      towerId = towerMatch[0];
    } else {
      if (typeof MOCK_DATA !== 'undefined') {
        const tKeys = Object.keys(MOCK_DATA.towerRegistry);
        for (let key of tKeys) {
          if (trimmed.includes(key)) {
            towerId = key;
            break;
          }
        }
      }
    }
    
    records.push({
      Timestamp: timestamp,
      Caller: caller,
      Recipient: recipient,
      Duration_Sec: durationSec.toString(),
      Type: type,
      Cell_Tower_ID: towerId,
      IMEI: 'N/A',
      IMSI: 'N/A'
    });
  });
  
  return records;
}
