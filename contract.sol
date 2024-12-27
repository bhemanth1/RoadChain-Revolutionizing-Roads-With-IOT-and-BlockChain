// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoltageReadings {
    // Constants
    uint256 private constant DECIMAL_PLACES = 4;
    uint256 private constant SCALING_FACTOR = 10 ** DECIMAL_PLACES;
    uint256 private constant MAX_VOLTAGE = 1000 * SCALING_FACTOR; // Max 1000V
    
    struct Reading {
        uint256 voltage;    // Voltage value (fixed-point format, 4 decimal places)
        string timestamp;   // Timestamp string
        address device;     // Address of the device that submitted the reading
    }
    
    // Storage
    Reading[] private readings;
    mapping(address => uint256[]) private deviceReadings;
    mapping(address => bool) private authorizedDevices;
    address private owner;
    
    // Events
    event NewReading(
        address indexed device,
        uint256 voltage,
        string timestamp,
        uint256 readingIndex
    );
    event DeviceAuthorized(address indexed device);
    event DeviceDeauthorized(address indexed device);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedDevices[msg.sender], "Device not authorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Authorization functions
    function authorizeDevice(address device) external onlyOwner {
        require(!authorizedDevices[device], "Device already authorized");
        authorizedDevices[device] = true;
        emit DeviceAuthorized(device);
    }
    
    function deauthorizeDevice(address device) external onlyOwner {
        require(authorizedDevices[device], "Device not authorized");
        authorizedDevices[device] = false;
        emit DeviceDeauthorized(device);
    }
    
    // Main functions
    function submitReading(uint256 _voltage, string calldata _timestamp) 
        external 
        onlyAuthorized 
    {
        require(_voltage <= MAX_VOLTAGE, "Voltage exceeds maximum allowed");
        require(bytes(_timestamp).length > 0, "Timestamp cannot be empty");
        
        Reading memory newReading = Reading({
            voltage: _voltage,
            timestamp: _timestamp,
            device: msg.sender
        });
        
        readings.push(newReading);
        uint256 readingIndex = readings.length - 1;
        deviceReadings[msg.sender].push(readingIndex);
        
        emit NewReading(msg.sender, _voltage, _timestamp, readingIndex);
    }
    
    // View functions
    function getTotalReadings() external view returns (uint256) {
        return readings.length;
    }
    
    function getDeviceReadingCount(address device) external view returns (uint256) {
        return deviceReadings[device].length;
    }
    
    function getReading(uint256 index) external view returns (
        uint256 voltage,
        string memory timestamp,
        address device
    ) {
        require(index < readings.length, "Reading index out of bounds");
        Reading storage reading = readings[index];
        return (reading.voltage, reading.timestamp, reading.device);
    }
    
    function getDeviceReadings(address device) external view returns (
        uint256[] memory voltages,
        string[] memory timestamps
    ) {
        uint256[] memory indices = deviceReadings[device];
        voltages = new uint256[](indices.length);
        timestamps = new string[](indices.length);
        
        for (uint256 i = 0; i < indices.length; i++) {
            Reading storage reading = readings[indices[i]];
            voltages[i] = reading.voltage;
            timestamps[i] = reading.timestamp;
        }
        
        return (voltages, timestamps);
    }
    
    function getLatestReading(address device) external view returns (
        uint256 voltage,
        string memory timestamp
    ) {
        uint256[] storage deviceIndices = deviceReadings[device];
        require(deviceIndices.length > 0, "No readings for this device");
        
        uint256 lastIndex = deviceIndices[deviceIndices.length - 1];
        Reading storage reading = readings[lastIndex];
        
        return (reading.voltage, reading.timestamp);
    }
    
    function isDeviceAuthorized(address device) external view returns (bool) {
        return authorizedDevices[device];
    }
}
