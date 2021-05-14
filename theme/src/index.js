import L from 'leaflet';
import omnivore from '@mapbox/leaflet-omnivore';
import 'leaflet-fullscreen';

import 'leaflet/dist/leaflet.css';
import 'leaflet-fullscreen/dist/leaflet.fullscreen.css';

var map = L.map('trace');

map.addControl(new L.Control.Fullscreen({
    pseudoFullscreen: true
}));

var url = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
var attrib ='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
var osm = new L.TileLayer(
    url,
    {
        minZoom: 8,
        maxZoom: 16,
        attribution: attrib
    })
    .addTo(map);

var href = document.getElementById("gpx").href;
var gpxLayer = omnivore.gpx(href)
    .on('ready', function() {
        map.fitBounds(gpxLayer.getBounds());
    })
    .addTo(map);
