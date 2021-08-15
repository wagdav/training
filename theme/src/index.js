import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-fullscreen';
import 'leaflet-fullscreen/dist/leaflet.fullscreen.css';

import 'leaflet-gpx';
import PinIconStart from 'leaflet-gpx/pin-icon-start.png';
import PinIconEnd from 'leaflet-gpx/pin-icon-end.png';
import PinShadow from 'leaflet-gpx/pin-shadow.png';

function addTrace(element) {
    var map = L.map(element);
    var gpx = element.getAttribute("data-gpx-trace");

    map.addControl(new L.Control.Fullscreen({
        pseudoFullscreen: true
    }));

    var url = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    var attrib = 'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
    var osm = new L.TileLayer(url, {
            minZoom: 8,
            maxZoom: 16,
            attribution: attrib
        })
        .addTo(map);

    new L.GPX(gpx, {
            async: true,
            marker_options: {
                startIconUrl: PinIconStart,
                endIconUrl: PinIconEnd,
                shadowUrl: PinShadow,
            },
        })
        .on('loaded', function(e) {
            map.fitBounds(e.target.getBounds());
        })
        .addTo(map);
}

Array
    .from(document.getElementsByClassName("gpx-trace"))
    .forEach(addTrace);
