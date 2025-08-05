import React from 'react';
import { Routes, Route } from 'react-router-dom';
import './App.css';
import Home from './components/Home';
import ReportView from './components/ReportView';
import EncounterView from './components/EncounterView';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>WC Logs - Combat Log Analyzer</h1>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/reports/:reportId" element={<ReportView />} />
          <Route path="/reports/:reportId/encounters/:encounterId" element={<EncounterView />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;