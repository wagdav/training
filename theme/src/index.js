import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-fullscreen';
import 'leaflet-fullscreen/dist/leaflet.fullscreen.css';

import 'leaflet-gpx';
import PinIconStart from 'leaflet-gpx/icons/pin-icon-start.png';
import PinIconEnd from 'leaflet-gpx/icons/pin-icon-end.png';

function addTrace(element) {
    var map = L.map(element);
    var gpxs = element.getAttribute("data-gpx-trace").split(",").map(item => item.trim());

    map.addControl(new L.Control.Fullscreen({
        pseudoFullscreen: true
    }));

    var url = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    var attrib = 'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, SRTM | Map style © <a href="https://opentopomap.org">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)';
    var osm = new L.TileLayer(url, {
            minZoom: 4,
            maxZoom: 16,
            attribution: attrib
        })
        .addTo(map);

    var bounds = [];
    gpxs.forEach(gpx => {
        bounds.push(new Promise((resolve, reject) => {
            new L.GPX(gpx, {
                async: true,
                markers: {
                    startIcon: PinIconStart,
                    endIcon: PinIconEnd,
                },
            }).on('loaded', function(e) {
                resolve(e.target.getBounds());
            }).addTo(map);
        }));
    });

    Promise.all(bounds).then((values) => {
        var b = new L.latLngBounds();
        values.forEach((v) => b.extend(v));
        map.fitBounds(b);
    });
}

Array
    .from(document.getElementsByClassName("gpx-trace"))
    .forEach(addTrace);
