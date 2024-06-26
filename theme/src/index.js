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
    var gpxs = element.getAttribute("data-gpx-trace").split(",").map(item => item.trim());

    map.addControl(new L.Control.Fullscreen({
        pseudoFullscreen: true
    }));

    var url = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    var attrib = 'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, SRTM | Map style © <a href="https://opentopomap.org">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)';
    var osm = new L.TileLayer(url, {
            minZoom: 8,
            maxZoom: 16,
            attribution: attrib
        })
        .addTo(map);

    var bounds = new L.latLngBounds();
    for (var i = 0; i < gpxs.length; i++) {
        var first = i == 0;
        var last = i == gpxs.length - 1;

        var g = new L.GPX(gpxs[i], {
                marker_options: {
                    startIconUrl: PinIconStart,
                    endIconUrl: PinIconEnd,
                    shadowUrl: PinShadow,
                },
            })

        g.addTo(map);
        bounds.extend(g.getBounds());
    }

    map.fitBounds(bounds);
}

Array
    .from(document.getElementsByClassName("gpx-trace"))
    .forEach(addTrace);
