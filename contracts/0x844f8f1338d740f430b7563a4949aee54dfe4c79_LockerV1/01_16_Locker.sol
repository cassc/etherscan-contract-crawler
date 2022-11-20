// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract LockerV1 is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    bytes32 public constant UNLOCK_ROLE = keccak256("UNLOCK_ROLE");
    IERC20Upgradeable token;

    struct LockerType {
        string name;
        uint256 timeLock;
        bool isLock;
        bool isExist;
    }

    struct TokenLock {
        uint256 expiration;
        bool status;
        uint256 amount;
    }

    string[] lockerTypeName;
    address[] ownerLockers;
    mapping(string => LockerType) lockerTypeList;
    mapping(address => mapping(uint256 => TokenLock)) userTokenLock;
    mapping(address => uint256[]) userTokenLockId;

    uint256 public lockReward;

    event LockerEvent(
        uint256 indexed _lockerId,
        address indexed _owner,
        uint256 _amount,
        uint256 _reward,
        uint256 _expiration,
        string _remark,
        bool _status
    );

    function initialize(address _token) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(LOCKER_ROLE, msg.sender);
        _grantRole(UNLOCK_ROLE, msg.sender);
        token = IERC20Upgradeable(_token);
    }

    function setLockReward(uint256 _lockReward)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockReward = _lockReward;
    }

    function setLockerType(
        string memory _locker,
        uint256 _timeLock,
        bool _lockStatus
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_locker).length > 0, "Locker Type: not empty");
        require(
            lockerTypeList[_locker].isExist == false,
            "Locker Type: already exist"
        );
        lockerTypeList[_locker] = LockerType(
            _locker,
            _timeLock,
            _lockStatus,
            true
        );
        lockerTypeName.push(_locker);
    }

    function unsetLockerType(string memory _locker, bool _exist)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockerTypeList[_locker].isExist = _exist;
    }

    function getLockerType(string memory _locker)
        public
        view
        returns (LockerType memory)
    {
        return lockerTypeList[_locker];
    }

    function getLockerTypeList() public view returns (LockerType[] memory) {
        LockerType[] memory _lists = new LockerType[](lockerTypeName.length);

        for (uint256 index = 0; index < lockerTypeName.length; index++) {
            _lists[index] = lockerTypeList[lockerTypeName[index]];
        }

        return _lists;
    }

    function lock(
        address _owner,
        uint256 _amount,
        string memory _locker
    ) external nonReentrant whenNotPaused onlyRole(LOCKER_ROLE) {
        require(address(_owner) != address(0), "Owner: non zero address");
        require(_amount > 0, "Amount: non zero");
        require(bytes(_locker).length > 0, "Locker: not empty");

        LockerType memory _lockerType = getLockerType(_locker);
        require(_lockerType.isExist == true, "Locker: not exist");

        uint256 _expiration = uint256(block.timestamp).add(
            _lockerType.timeLock
        );

        uint256 _lockerId = getLockersByOwner(_owner).length;

        userTokenLock[_owner][_lockerId] = TokenLock(
            _expiration,
            false,
            _amount
        );
        userTokenLockId[_owner].push(_lockerId);
        ownerLockers.push(_owner);

        emit LockerEvent(
            _lockerId,
            _owner,
            _amount,
            0,
            _expiration,
            "locked",
            false
        );
    }

    function unlock(address _owner, uint256 _lockerId)
        external
        nonReentrant
        onlyRole(UNLOCK_ROLE)
        whenNotPaused
    {
        require(
            userTokenLock[_owner][_lockerId].status == false,
            "Locker: can't unlock with locker id"
        );

        require(
            userTokenLock[_owner][_lockerId].amount > 0,
            "Locker: can't unlock with zero amount"
        );

        uint256 _expiration = userTokenLock[_owner][_lockerId].expiration;

        require(
            block.timestamp > _expiration,
            "Expiration: less than current time"
        );

        uint256 _amount = userTokenLock[_owner][_lockerId].amount;

        uint256 _reward = _amount.mul(lockReward).div(100);

        token.safeTransfer(_owner, _amount.add(_reward));
        userTokenLock[_owner][_lockerId].status = true;

        emit LockerEvent(
            _lockerId,
            _owner,
            _amount,
            _reward,
            _expiration,
            "unlocked",
            true
        );
    }

    function getLockersByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return userTokenLockId[_owner];
    }

    function getTokenLockByIndex(address _owner, uint256 _lockerId)
        public
        view
        returns (TokenLock memory)
    {
        TokenLock memory _tokenLock = userTokenLock[_owner][_lockerId];
        return _tokenLock;
    }

    function getOwnerLocker() public view returns (address[] memory) {
        return ownerLockers;
    }

    function adminWithdraw(uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            token.balanceOf(address(this)) >= _amount,
            "Launchpad: not enough token"
        );

        token.safeTransfer(msg.sender, _amount);
    }
}