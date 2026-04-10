const routes = [
  {
    id: 'route-101',
    name: 'City Center Loop',
    startPoint: 'Central Station',
    endPoint: 'Market Square',
    stops: ['Central Station', 'Museum', 'Town Hall', 'Market Square'],
    status: 'active',
  },
  {
    id: 'route-205',
    name: 'University Express',
    startPoint: 'Bus Depot',
    endPoint: 'University Gate',
    stops: ['Bus Depot', 'Library', 'Sports Complex', 'University Gate'],
    status: 'active',
  },
];

const vehicles = [
  {
    id: 'bus-12',
    vehicleNumber: 'PB-12-4587',
    routeId: 'route-101',
    latitude: 31.634,
    longitude: 74.872,
    speedKph: 38,
    occupancy: 63,
    status: 'on_route',
  },
  {
    id: 'bus-24',
    vehicleNumber: 'PB-24-9021',
    routeId: 'route-205',
    latitude: 31.622,
    longitude: 74.859,
    speedKph: 42,
    occupancy: 51,
    status: 'delayed',
  },
];

module.exports = {
  routes,
  vehicles,
};

