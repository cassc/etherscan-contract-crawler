// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./TheKindToken.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenMigration is ReentrancyGuard, Context, Ownable {
    struct UserInfo {
        uint256 claimedAmount;
        uint256 claimedIndex;
        uint256 migrateStartTime;
        uint256 claimedTillNow;
        bool migrated;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public whitelist;

    uint256[] public lockPercents = [5, 10, 15, 20, 20, 20, 10];
    uint256[] public lockDays = [
        180 days,
        270 days,
        365 days,
        390 days,
        420 days,
        450 days,
        540 days
    ];

    address public immutable deadWallet =
        0x000000000000000000000000000000000000dEaD;

    IBEP20 public tokenV1; //address of the old version
    IBEP20 public tokenV2; //address of the new version

    bool public migrationStarted;

    /// @notice Emits event every time someone migrates
    event MigrateActivation(address addr, uint256 amount);
    /// @notice Emits event every time someone whitelisted migrates
    event MigrateToV2(address addr, uint256 amount);

    /// @param _tokenV1 The address of old version
    /// @param _tokenV2 The address of new version
    constructor(address _tokenV1, address _tokenV2) {
        setTokenV1andV2(_tokenV1, _tokenV2);
    }

    receive() external payable {}

    /// @notice Enables the migration
    function startMigration() external onlyOwner returns (bool) {
        require(migrationStarted == false, "Migration is already enabled");
        migrationStarted = true;
        return migrationStarted;
    }

    /// @notice Disable the migration
    function stopMigration() external onlyOwner {
        require(migrationStarted == true, "Migration is already disabled");
        migrationStarted = false;
    }

    /// @notice register whitelist
    function registerToWhitelist(address[] memory _whitelist)
        external
        onlyOwner
    {
        for (uint i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    /// @notice set main factors of old version's token and new version's token
    function setTokenV1andV2(address _tokenV1, address _tokenV2)
        public
        onlyOwner
    {
        tokenV1 = IBEP20(_tokenV1);
        tokenV2 = IBEP20(_tokenV2);
    }

    /// @notice Withdraws remaining tokens
    /// Withdraws all the new tokens via several steps.
    /// Once completed all withdraw, initialize user info.
    function withdrawTokens() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(
            migrationStarted == true && user.claimedAmount > 0,
            "Impossible to withdraw tokens if migration still disabled"
        );
        require(user.migrated == false, "Migration Completed");
        uint256 claims = user.claimedIndex;
        if (claims < lockDays.length - 1) {
            require(
                    user.migrateStartTime + lockDays[claims] <= block.timestamp,
                "Impossible to withdraw tokens in this time"
            );
            uint256 withdrawAmount = (user.claimedAmount *
                lockPercents[claims]) / 100;
            tokenV2.transfer(msg.sender, withdrawAmount);
            user.claimedTillNow = user.claimedTillNow + withdrawAmount;
            user.claimedIndex = claims + 1;
        } else {
            require(
                    user.migrateStartTime + lockDays[claims] <= block.timestamp,
                "Impossible to withdraw tokens in this time"
            );
            uint256 withdrawAmount = (user.claimedAmount *
                lockPercents[claims]) / 100;
            tokenV2.transfer(msg.sender, withdrawAmount);
            user.claimedTillNow = user.claimedTillNow + withdrawAmount;
            user.claimedIndex = claims + 1;
            user.migrated = true;
        }
    }

    /// @notice Migrate activation from old version to new one
    /// Save sender's user info for withdraw delayed.
    ///   passing this contract address as "sender".
    ///   Old tokens will be sent to burn
    function migrate() external nonReentrant returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        require(migrationStarted == true, "Migration not started yet");
        require(whitelist[msg.sender] == true, "Not allowed migration for you");
        require(user.migrated == false, "Already migrated");
        uint256 userV1Balance = tokenV1.balanceOf(msg.sender);
        require(userV1Balance > 0, "The balance is greater than zero");
        uint256 userRemaing = (userV1Balance * 85) / 100;
        uint256 amtToMigrate = userRemaing / 1000;

        require(
            tokenV2.balanceOf(address(this)) >= amtToMigrate,
            "No enough V2 liquidity"
        );
        tokenV1.transferFrom(msg.sender, deadWallet, userV1Balance);
        user.claimedAmount = amtToMigrate;
        user.migrateStartTime = block.timestamp - (block.timestamp % 86400);
        emit MigrateActivation(msg.sender, amtToMigrate);
        return user.migrateStartTime;
    }

    function getInfoAmount(address _addr) external view returns (uint256) {
        UserInfo storage user = userInfo[_addr];
        if (user.migrateStartTime == 0 || user.migrated) return 0;
        return (user.claimedAmount * lockPercents[user.claimedIndex]) / 100;
    }

    function getInfoPeriod(address _addr) external view returns (uint256) {
        UserInfo storage user = userInfo[_addr];
        if (user.migrateStartTime == 0 || user.migrated) return 0;
        uint256 nextDay = lockDays[user.claimedIndex];
        return user.migrateStartTime + nextDay;
    }

    function getNextClaimTime(uint256 n) public view returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        if (user.migrateStartTime == 0 || user.migrated) return 0;
        return user.migrateStartTime + lockDays[n];
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }
}