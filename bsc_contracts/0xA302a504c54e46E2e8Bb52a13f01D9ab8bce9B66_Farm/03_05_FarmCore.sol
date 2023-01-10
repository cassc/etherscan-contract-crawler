// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

abstract contract FarmCore is Context, Ownable {

     /**
     * @dev Enum variable type
     */
    enum Network{ BSC, AVAX }

    /**
     * @dev Struct variable type
     */
    struct FarmService {
        string name;
        Network network;
        bool isActive;
    }

    struct FarmPair {
        uint256 farmServiceId;
        uint256 farmPoolId;
        address contractAddress;
        Network network;
        bool isActive;
    }

    struct FarmPool {
        uint256 farmPairId;
        string name;
        address depositAddress;
        address withdrawAddress;
        IERC20 firstToken;
        IERC20 secondToken;
        bool isActive;
        bool isFarmMoving;
    }

     /**
     * @dev Mapping data for quick access by index or address.
     */
    mapping(uint256 => FarmService) public farmServices;
    mapping(uint256 => FarmPair) public farmPairs;
    mapping(uint256 => FarmPool) public farmPools;

    /**
     * @dev Counters for mapped data. Used to store the length of the data.
     */
    uint256 public farmPairsCount;
    uint256 public farmPoolsCount;
    uint256 public farmServicesCount;

    /**
     * @dev All events. Used to track changes in the contract
     */
    event AdminIsAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MINTVLUpdated(uint256 value);
    event CAPYUpdated(uint256 value);
    event MINAPYUpdated(uint256 value);
    event ServiceDisabled();
    event ServiceEnabled();
    event FarmServiceChanged(string name, Network network);
    event FarmPoolChanged(string name);
    event FarmPairChanged(uint256 farmPairId, address indexed contractAddress);
    event FarmToFarmMovingStart(uint256 time, uint256 farmPairId);
    event FarmToFarmMovingEnd(uint256 time, uint256 farmPairId);

    /**
     * @dev Admins data
     */
    mapping(address => bool) public isAdmin;
    address[] public adminsList;
    uint256 public adminsCount;

    /**
     * @dev Core data
     */
    bool public serviceDisabled;
    uint256 public MINTVL;
    uint256 public CAPY;
    uint256 public MINAPY;
    uint256 public servicePercent;

    /**
     * @dev Throws if called when variable (`serviceDisabled`) is equals (`true`).
     */
    modifier onlyWhenServiceEnabled() {
        require(serviceDisabled == false, "FarmContract: Currently service is disabled. Try again later.");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Access denied!");
        _;
    }

    /**
     * @dev Set deposit address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function setDepositAddress(uint256 _farmPoolId, address _address) external onlyWhenServiceEnabled onlyOwner {
       farmPools[_farmPoolId].depositAddress = _address;
    }

    /**
     * @dev Set withdraw address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function setWithdrawAddress(uint256 _farmPoolId, address _address) external onlyWhenServiceEnabled onlyOwner {
       farmPools[_farmPoolId].withdrawAddress = _address;
    }

    /**
     * @dev Set service percent.
     *
     * NOTE: Can only be called by the admin.
     */
    function setServicePercent(uint256 _percent) external onlyWhenServiceEnabled onlyAdmin {
       servicePercent = _percent;
    }

    /**
     * @dev Start moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function startFarmToFarm(uint256 _farmPoolId, uint256 _newFarmPairId) external onlyWhenServiceEnabled onlyOwner {
        farmPools[_farmPoolId].farmPairId = _newFarmPairId;
        farmPools[_farmPoolId].isFarmMoving = true;
        emit FarmToFarmMovingStart(block.timestamp, _farmPoolId);
    }

    /**
     * @dev End moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function endFarmToFarm(uint256 _farmPoolId) external onlyWhenServiceEnabled onlyOwner {
         farmPools[_farmPoolId].isFarmMoving = false;
        emit FarmToFarmMovingEnd(block.timestamp, _farmPoolId);
    }

    /**
     * @dev Gives administrator rights to the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function addAdmin(address _address) public onlyWhenServiceEnabled onlyOwner {
        adminsList.push(_address);
        isAdmin[_address] = true;
        adminsCount++;
        emit AdminIsAdded(_address);
    }

    /**
     * @dev Removes administrator rights from the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function removeAdmin(address _address, uint256 _index) external onlyWhenServiceEnabled onlyOwner {
        isAdmin[_address] = false;
        adminsList[_index] = adminsList[adminsList.length - 1];
        adminsList.pop();
        adminsCount--;
        emit AdminRemoved(_address);
    }

    /**
     * @dev Disable all callable methods of service except (`enableService()`).
     *
     * NOTE: Can only be called by the admin address.
     */
    function disableService() external onlyWhenServiceEnabled onlyAdmin {
        serviceDisabled = true;
        emit ServiceDisabled();
    }

    /**
     * @dev Enable all callable methods of service.
     *
     * NOTE: Can only be called by the admin address.
     */
    function enableService() external onlyAdmin {
        serviceDisabled = false;
        emit ServiceEnabled();
    }

    /**
     * @dev Sets new value for (`MINTVL`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setMINTVL(uint256 _value) external onlyWhenServiceEnabled onlyAdmin {
        MINTVL = _value;
        emit MINTVLUpdated(_value);
    }

    /**
     * @dev Sets new value for (`CAPY`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setCAPY(uint256 _value) external onlyWhenServiceEnabled onlyAdmin {
        CAPY = _value;
        emit CAPYUpdated(_value);
    }

    /**
     * @dev Sets new value for (`MINAPY`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setMINAPY(uint256 _value) external onlyWhenServiceEnabled onlyAdmin {
        MINAPY = _value;
        emit MINAPYUpdated(_value);
    }

    /**
     * @dev Adds or update (`FarmService`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setFarmService(
        uint256 _id,
        string memory _name,
        Network _network,
        bool _isActive
    ) external onlyWhenServiceEnabled onlyAdmin {

        if (bytes(farmServices[_id].name).length == 0) {
            farmServicesCount++;
        }

        farmServices[_id] = FarmService(_name, _network, _isActive);

        emit FarmServiceChanged(_name, _network);
    } 

    /**
     * @dev Adds or update (`Farm Pool`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setFarmPool(
        uint256 _id,
        uint256 _farmPairId,
        string memory _name,
        IERC20 _firstToken,
        IERC20 _secondToken,
        bool _isActive
    ) external onlyWhenServiceEnabled onlyAdmin {

        if (bytes(farmPools[_id].name).length == 0) {
            farmPoolsCount++;
        }

        farmPools[_id] = FarmPool(
            _farmPairId,
            _name,
            farmPools[_id].depositAddress,
            farmPools[_id].withdrawAddress,
            _firstToken,
            _secondToken,
            _isActive,
            farmPools[_id].isFarmMoving
        );

        emit FarmPoolChanged(_name);
    } 

    /**
     * @dev Adds or update (`Farm Pair`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setFarmPair(
        uint256 _id,
        uint256 _farmServiceId,
        uint256 _farmPoolId,
        address _contractAddress,
        Network _network,
        bool _isActive
    ) external onlyWhenServiceEnabled onlyAdmin {

        require(farmServices[_farmServiceId].isActive == true, "Farm service with this ID does not exist or inactive!");

        if (farmPairs[_id].contractAddress == address(0)) {
            farmPairsCount++;
        }

        farmPairs[_id] = FarmPair(
            _farmServiceId,
            _farmPoolId,
            _contractAddress,
            _network,
            _isActive
        );

        emit FarmPairChanged(_id, _contractAddress);
    }
}