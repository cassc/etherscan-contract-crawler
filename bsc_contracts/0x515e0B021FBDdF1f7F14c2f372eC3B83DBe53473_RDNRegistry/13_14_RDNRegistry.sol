// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {WithdrawAnyERC20Token} from "../Utils/WithdrawAnyERC20Token.sol";
import {IRDNRegistry} from "./interfaces/IRDNRegistry.sol";

// Parent 0 address restricted
// Default level 1

contract RDNRegistry is IRDNRegistry, AccessControlEnumerable, WithdrawAnyERC20Token {

    // admin role for userlevel change (setLevel function)
    bytes32 public constant SETLEVEL_ROLE = keccak256("SETLEVEL_ROLE");
    // admin role for userlevel change (levelUp function)
    bytes32 public constant LEVELUP_ROLE = keccak256("LEVELUP_ROLE");
    // admin role for changing factors contract address
    bytes32 public constant FACTORSADDRESS_ROLE = keccak256("FACTORSADDRESS_ROLE");
    // admin role for RDNPOS contract
    bytes32 public constant TARIFFUPDATE_ROLE = keccak256("TARIFFUPDATE_ROLE");
    // admin role for RDNPOS contract 
    bytes32 public constant ACTIVEUNTILLUPDATE_ROLE = keccak256("ACTIVEUNTILLUPDATE_ROLE");
    // admin role fore points rate updating
    bytes32 public constant POINTSRATEUPDATE_ROLE = keccak256("POINTSRATEUPDATE_ROLE");
    // admin role for RDNDistributors configuration
    bytes32 public constant SETDISTRIBUTOR_ROLE = keccak256("SETDISTRIBUTOR_ROLE");
    // admin role for adding custom users
    bytes32 public constant ADDUSERBYADMIN_ROLE = keccak256("ADDUSERBYADMIN_ROLE");

    // actual userAddress => userId
    mapping (address => uint) public userId;
    // users registry
    User[] public users;
    // gas saving counter
    uint public usersCount;
    mapping(uint => uint[]) public children;

    // addresses granted to change userAddress for userId;
    mapping(uint => mapping(address => bool)) public changeAddressAccess;
    mapping(uint => address[]) public changeAddressAddresses;

    // actual factors contract
    address public factorsAddress;

    // token => rate (rate is 1/USDprice for token, based in token.decimals)
    mapping (address => uint) public pointsRate;

    // actual RDNDistributors registry. token => RDNDistributor
    mapping (address => address) public distributors;

    // when new user created
    event UserAdded(uint indexed userId, uint indexed parentId, address indexed userAddress);
    // when users level updated
    event UserLevelUpdated(uint indexed userId, uint levelBefore, uint levelAfter);
    // when users tariff updated
    event UserTariffUpdated(uint indexed userId, uint tariffBefore, uint tariffAfter);
    // when users activeUntill updated
    event UserActiveUntillUpdated(uint indexed userId, uint activeUntill);
    // when tokens points rate value updated
    event PointsRateUpdated(address indexed token, uint rate);
    // when userAddress changed
    event UserAddressChanged(uint indexed userId, address indexed userAddress, address indexed sender, address oldAddress);
    // when granted change user address
    event GrantedUserAddressChange(uint indexed userId, address indexed grantedAddress);
    // when revoked access to change user address
    event RevokedUserAddressChange(uint indexed userId, address indexed revokedAddress);

    /*
     * @notice Constructor
     * @param _root: userAdrress for userId = 1
     * @param _admin: default admin
    */
    constructor (address _root, address _admin) WithdrawAnyERC20Token(_admin, false) {
        // add 0 user. No one user can reference 0 in parentId, excluding user 1.
        User memory _zeroUser = User(0, address(0), 0, 0, 0, block.timestamp);
        users.push(_zeroUser);
        userId[address(0)] = 0;
        
        //add root user (userId 1), referencing parantId=0.
        User memory _rootUser = User(12, _root, 0, 7, block.timestamp + 36500 days, block.timestamp);
        users.push(_rootUser);
        userId[_root] = 1;
        children[0].push(1);

        usersCount = 2;

        // default roles setup
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETLEVEL_ROLE, _admin);
        _setupRole(LEVELUP_ROLE, _admin);
        _setupRole(FACTORSADDRESS_ROLE, _admin);
        _setupRole(TARIFFUPDATE_ROLE, _admin);
        _setupRole(ACTIVEUNTILLUPDATE_ROLE, _admin);
        _setupRole(POINTSRATEUPDATE_ROLE, _admin);
        _setupRole(SETDISTRIBUTOR_ROLE, _admin);
        _setupRole(ADDUSERBYADMIN_ROLE, _admin);
    }

    ///////////////////////////////////////
    // public user functions
    ///////////////////////////////////////
    
    /* 
     * @notice user registration
     * @param _parentId: registered user with tariff > 0
    */
    function register(uint _parentId) external {
        _addUser(msg.sender, _parentId);
    }

    /*
     * @notice user or granted addresses can change userAddress
    */
    function changeAddress(uint _userId, address _newAddress) public hasChangeAddressAccess(_userId) {
        require(!isRegisteredByAddress(_newAddress), "user already registered");
        emit UserAddressChanged(_userId, _newAddress, msg.sender, users[_userId].userAddress);
        users[_userId].userAddress = _newAddress;
    }

    /*
     * @notice user can grant other addresses to change userAddress
    */
    function grantChangeAddressAccess(address _grantedAddress) public onlyRegisteredByAddress(msg.sender) {
        uint _userId = userId[msg.sender];
        changeAddressAddresses[_userId].push(_grantedAddress);
        changeAddressAccess[_userId][_grantedAddress] = true;
        emit GrantedUserAddressChange(_userId, _grantedAddress);
    }

    /*
    * @notice user can revoke changeAddressAccess. Granted address can revoke its own access
    */
    function revokeChangeAddressAccess(uint _userId, address _grantedAddress) public {
        require(users[_userId].userAddress == msg.sender || _grantedAddress == msg.sender, "Access denied");
        changeAddressAccess[_userId][_grantedAddress] = false;
        emit RevokedUserAddressChange(_userId, _grantedAddress);
    }

    //////////////////////////////////////
    // admin functions
    //////////////////////////////////////

    function levelUp(uint _userId, uint _level) public onlyRole(LEVELUP_ROLE) onlyValidUser(_userId) {
        require(_level > users[_userId].level, "_level must be greater");
        emit UserLevelUpdated(_userId, users[_userId].level, _level);
        users[_userId].level = _level;
    }

    function setLevel(uint _userId, uint _level) public onlyRole(SETLEVEL_ROLE) onlyValidUser(_userId) {
        emit UserLevelUpdated(_userId, users[_userId].level, _level);
        users[_userId].level = _level;
    }

    function setFactorsAddress(address _factorsAddress) public onlyRole(FACTORSADDRESS_ROLE) {
        factorsAddress = _factorsAddress;
    }

    function setTariff(uint _userId, uint _tariff) public onlyRole(TARIFFUPDATE_ROLE) onlyValidUser(_userId) {
        emit UserTariffUpdated(_userId, users[_userId].tariff, _tariff);
        users[_userId].tariff = _tariff;
    }

    function setActiveUntill(uint _userId, uint _activeUntill) public onlyRole(ACTIVEUNTILLUPDATE_ROLE) onlyValidUser(_userId) {
        users[_userId].activeUntill = _activeUntill;
        emit UserActiveUntillUpdated(_userId, _activeUntill);
    }

    function setPointsRate(address _token, uint _rate) public onlyRole(POINTSRATEUPDATE_ROLE) {
        pointsRate[_token] = _rate;
        emit PointsRateUpdated(_token, _rate);
    }

    function setDistributor(address _token, address _distributor) public onlyRole(SETDISTRIBUTOR_ROLE) {
        distributors[_token] = _distributor;
    }

    function grantCompleteAdmin(address _admin) public {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(SETLEVEL_ROLE, _admin);
        grantRole(LEVELUP_ROLE, _admin);
        grantRole(FACTORSADDRESS_ROLE, _admin);
        grantRole(TARIFFUPDATE_ROLE, _admin);
        grantRole(ACTIVEUNTILLUPDATE_ROLE, _admin);
        grantRole(POINTSRATEUPDATE_ROLE, _admin);
        grantRole(SETDISTRIBUTOR_ROLE, _admin);
        grantRole(ADDUSERBYADMIN_ROLE, _admin);
    }

    function revokeCompleteAdmin(address _admin) public {
        revokeRole(SETLEVEL_ROLE, _admin);
        revokeRole(LEVELUP_ROLE, _admin);
        revokeRole(FACTORSADDRESS_ROLE, _admin);
        revokeRole(TARIFFUPDATE_ROLE, _admin);
        revokeRole(ACTIVEUNTILLUPDATE_ROLE, _admin);
        revokeRole(POINTSRATEUPDATE_ROLE, _admin);
        revokeRole(SETDISTRIBUTOR_ROLE, _admin);
        revokeRole(ADDUSERBYADMIN_ROLE, _admin);
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /*
     * @notice sender must have 3 roles
    */
    function addUserByAdmin(uint _parentId, address _userAddress, uint _tariff, uint _activeUntill) public onlyRole(ADDUSERBYADMIN_ROLE) {
        (uint _userId) = _addUser(_userAddress, _parentId);
        setTariff(_userId, _tariff);
        setActiveUntill(_userId, _activeUntill);
    }

    //////////////////////////////////////
    // private functions
    //////////////////////////////////////

    function _addUser(address _userAddress, uint _parentId) private returns(uint) {
        require(!isRegisteredByAddress(_userAddress), "user already registered");
        require(isRegistered(_parentId), "_parentId not found");
        require(users[_parentId].tariff > 0, "_parentId can not be parent");
        User memory _user = User(1, _userAddress, _parentId, 0, 0, block.timestamp);
        users.push(_user);
        usersCount += 1;
        userId[_userAddress] = usersCount - 1;
        children[_parentId].push(usersCount - 1);
        emit UserAdded(usersCount - 1, _parentId, _userAddress);
        return (usersCount - 1);
    }


    //////////////////////////////////////
    // modifiers
    //////////////////////////////////////


    modifier onlyRegisteredByAddress(address _userAddress) {
        require(isRegisteredByAddress(_userAddress), "user not registered");
        _;
    }

    modifier onlyRegistered(uint _userId) {
        require(isRegistered(_userId), "user not registered");
        _;
    }

    modifier onlyValidUser(uint _userId) {
        require(isValidUser(_userId), "invalid userId");
        _;
    }

    modifier hasChangeAddressAccess(uint _userId) {
        require(users[_userId].userAddress == msg.sender || changeAddressAccess[_userId][msg.sender], "Access denied");
        _;
    }


    //////////////////////////////////////
    // public getters and checkers
    //////////////////////////////////////

    /*
     * @notice 0 user is also registered
    */
    function isRegistered(uint _userId) public view returns(bool) {
        if (_userId < usersCount) {
            return true;
        }
        return false;
    }

    /*
     * @notice 0 user is not valid
    */
    function isValidUser(uint _userId) public view returns(bool) {
        if ((_userId > 0) && (_userId < usersCount)) {
            return true;
        }
        return false;
    }

    function isRegisteredByAddress(address _userAddress) public view returns(bool) {
        if (userId[_userAddress] != 0 || _userAddress == address(0)) {
            return true;
        }
        return false;
    }

    function isActive(uint _userId) public view returns(bool) {
        return (users[_userId].activeUntill > block.timestamp);
    }

    function getParentId(uint _userId) public view returns(uint) {
        return users[_userId].parentId;
    }

    function getLevel(uint _userId) public view returns(uint) {
        return users[_userId].level;
    }

    function getTariff(uint _userId) public view returns(uint) {
        return users[_userId].tariff;
    }

    function getActiveUntill(uint _userId) public view returns(uint) {
        return users[_userId].activeUntill;
    }

    function getUserAddress(uint _userId) public view returns(address) {
        return users[_userId].userAddress;
    }

    function getAllUsers() public view returns(User[] memory) {
        return users;
    }

    function getUser(uint _userId) public view returns(User memory) {
        return users[_userId];
    }

    function getUserIdByAddress(address _userAddress) public view returns(uint) {
        return userId[_userAddress];
    }

    function getUsersCount() public view returns(uint) {
        return usersCount;
    }

    function getChildren(uint _userId) public view returns(uint[] memory) {
        return children[_userId];
    }

    function getPointsRate(address _token) public view returns(uint) {
        return pointsRate[_token];
    }

    function getDistributor(address _token) public view returns(address) {
        require (distributors[_token] != address(0), "Distributor not found");
        return distributors[_token];
    }

    function isHasChangeAddressAccess(uint _userId, address _grantedAddress) public view returns(bool) {
        return (users[_userId].userAddress == _grantedAddress || changeAddressAccess[_userId][_grantedAddress]);
    }

    function getGrantedChangeAddress(uint _userId) public view returns(address[] memory) {
        return changeAddressAddresses[_userId];
    }


}