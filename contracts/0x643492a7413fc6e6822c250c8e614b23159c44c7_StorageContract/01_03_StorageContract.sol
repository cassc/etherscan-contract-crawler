// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StorageContract is Ownable {

    struct InstanceInfo {
        string name;
        string symbol;
        address creator;
    }
    
    address public factory; // The current factory address

    mapping(bytes32 => address) public getInstance; // keccak256("name", "symbol") => instance address
    mapping(address => InstanceInfo) private _instanceInfos;    // Instance address => InstanceInfo
    address[] public instances; // The array of all instances

    event FactorySet(address newFactory);
    event InstanceAdded(address newInstance);

    /**
    * @dev returns instance info
    * @param instanceId instance ID
    */
    function getInstanceInfo(
        uint256 instanceId
    ) external view returns(InstanceInfo memory) {
        require(instanceId < instances.length, "incorrect ID");
        address instance = instances[instanceId];
        return _instanceInfos[instance];
    }

    /**
    * @dev returns the count of instances
    */
    function instancesCount() external view returns (uint256) {
        return instances.length;
    }

    /** 
     * @notice Sets new factory address
     * @param _factory New factory address
     */
    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "incorrect address");
        factory = _factory;
        emit FactorySet(_factory);
    }

    /** 
     * @notice Adds new instance
     * @dev Can be called only by factory contract
     * @param instanceAddress New instance address
     * @param creator New instance creator
     * @param name New instance name
     * @param symbol New instance symbol
     */
    function addInstance(
        address instanceAddress,
        address creator,
        string memory name,
        string memory symbol
    ) external returns (uint256) {
        require(_msgSender() == factory, "only factory");
        getInstance[keccak256(abi.encodePacked(name, symbol))] = instanceAddress;
        instances.push(instanceAddress);
        _instanceInfos[instanceAddress] = InstanceInfo(
            name,
            symbol,
            creator
        );
        emit InstanceAdded(instanceAddress);
        return instances.length;
    }



}