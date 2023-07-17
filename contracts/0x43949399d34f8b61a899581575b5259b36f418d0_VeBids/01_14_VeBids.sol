// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../library/DSMath.sol";
import "../library/LogExpMath.sol";
import "./VeERC20.sol";
import "../interfaces/IMasterBids.sol";
import "../interfaces/IVeBids.sol";

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

/// @title VeBids
/// @notice BIDS Waddle: the staking contract for BIDS, as well as the token used for governance.
/// Note Waddling does not seem to slow the BIDS, it only makes it sturdier.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once BIDS is sufficiently
/// distributed and the community can show to govern itself.
contract VeBids is Ownable, ReentrancyGuard, Pausable, VeERC20, IVe, IVeBids {
    using SafeERC20 for IERC20;
    using DSMath for uint256;

    uint256 constant WAD = 1e18;

    /// @notice the bids token
    IERC20 public bids;

    /// @notice the masterBids contract
    IMasterBids public masterBids;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake bids, they must be previously whitelisted to stake bids
    mapping(address => bool) public whitelist;

    uint32 public maxBreedingLength;
    uint32 public minLockDays;
    uint32 public maxLockDays;

    /// @notice user info mapping
    mapping(address => UserInfo) internal users;

    /// @notice Address of the Voter contract
    address public voter;
    /// @notice amount of vote used currently for each user
    mapping(address => uint256) public usedVote;

    event Enter(address addr, uint256 unlockTime, uint256 bidsAmount, uint256 veBIDSAmount, uint256 currentOnChainId);
    event Exit(
        address addr,
        uint256 unlockTime,
        uint256 bidsAmount,
        uint256 veBIDSAmount,
        uint256 removedOnChainId,
        uint256 previousHighestOnChainId
    );
    event SetMasterBIDS(address addr);
    event SetVoter(address addr);
    event SetWhiteList(address addr, bool stat);
    event SetMaxBreedingLength(uint256 len);
    event UpdateLockTime(
        address addr,
        uint256 slot,
        uint256 unlockTime,
        uint256 bidsAmount,
        uint256 originalVeBIDSAmount,
        uint256 newVeBIDSAmount
    );
    event Vote(address user, int256 delta);
    event SetLockDays(uint256 min, uint256 max);

    error VEBIDS_OVERFLOW();

    modifier onlyVoter() {
        require(msg.sender == voter, "VeBIDS: caller is not voter");
        _;
    }

    constructor(IERC20 _bids, IMasterBids _masterBids, uint32 _minLock, uint32 _maxLock) VeERC20("Vote Escrowed Bids", "veBIDS") {
        require(address(_masterBids) != address(0), "zero address");
        require(address(_bids) != address(0), "zero address");
        require(_maxLock <= 2922, "Max lock too high");
        require(_minLock > 0, "Minimum is at least 1 day");

        masterBids = _masterBids;
        bids = _bids;

        maxBreedingLength = 10000;
        minLockDays = _minLock;
        maxLockDays = _maxLock;
    }

    function _verifyVoteIsEnough(address _user) internal view {
        require(balanceOf(_user) >= usedVote[_user], "VeBIDS: not enough vote");
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice checks wether user _addr has bids staked
    /// @param _addr the user address to check
    /// @return true if the user has bids in stake, false otherwise
    function isUser(address _addr) external view returns (bool) {
        return balanceOf(_addr) > 0;
    }

    /// @notice return the amount of BIDS locked and veBIDS acquired by a user
    function getUserOverview(address _addr) external view returns (uint256 bidsLocked, uint256 veBIDSBalance) {
        UserInfo storage user = users[_addr];
        uint256 len = user.breedings.length;
        for (uint256 i = 0; i < len; i++) {
            bidsLocked += user.breedings[i].bidsAmount;
        }
        veBIDSBalance = balanceOf(_addr);
    }

    /// @notice return the user info
    function getUserInfo(address addr) external view returns (UserInfo memory) {
        return users[addr];
    }

    /// @dev explicitly override multiple inheritance
    function totalSupply() public view override(VeERC20,IVeBids) returns (uint256) {
        return super.totalSupply();
    }

    /// @dev explicitly override multiple inheritance
    function balanceOf(address account) public view override(VeERC20,IVeBids) returns (uint256) {
        return super.balanceOf(account);
    }

    function expectedVeBIDSAmount(uint256 amount, uint256 lockDays) public pure returns (uint256) {
        // veBIDS = BIDS * 0.026 * lockDays^0.5
        return amount.wmul(26162237992630200).wmul(LogExpMath.pow(lockDays * WAD, 50e16));
    }

    /// @notice lock BIDS into contract and mint veBIDS
    function mint(uint256 amount, uint256 lockDays) external virtual nonReentrant whenNotPaused returns (uint256 veBIDSAmount) {
        require(amount > 0, "amount to deposit cannot be zero");
        if (amount > uint256(type(uint104).max)) revert VEBIDS_OVERFLOW();

        _assertNotContract(msg.sender);

        uint256 originalLength = users[msg.sender].breedings.length;

        require(lockDays >= uint256(minLockDays) && lockDays <= uint256(maxLockDays), "lock days is invalid");
        require(originalLength < uint256(maxBreedingLength), "breed too much");

        uint256 unlockTime = block.timestamp + 86400 * lockDays; // seconds in a day = 86400
        veBIDSAmount = expectedVeBIDSAmount(amount, lockDays);

        if (unlockTime > uint256(type(uint48).max)) revert VEBIDS_OVERFLOW();
        if (veBIDSAmount > uint256(type(uint104).max)) revert VEBIDS_OVERFLOW();

        users[msg.sender].breedings.push(Breeding(uint48(unlockTime), uint104(amount), uint104(veBIDSAmount)));
        users[msg.sender].userTotalBidsLocked += amount;

        // Request BIDS from user
        bids.safeTransferFrom(msg.sender, address(this), amount);

        // event Mint(address indexed user, uint256 indexed amount) is emitted
        _mint(msg.sender, veBIDSAmount);

        emit Enter(msg.sender, unlockTime, amount, veBIDSAmount, originalLength); //length pre push is the onchain id.
    }

    function burn(uint256 slot) external nonReentrant whenNotPaused {
        uint256 length = users[msg.sender].breedings.length;
        require(slot < length, "wut?");

        Breeding memory breeding = users[msg.sender].breedings[slot];
        require(uint256(breeding.unlockTime) <= block.timestamp, "not yet meh");

        // remove slot
        if (slot != length - 1) {
            users[msg.sender].breedings[slot] = users[msg.sender].breedings[length - 1];
        }
        users[msg.sender].breedings.pop();
        users[msg.sender].userTotalBidsLocked -= breeding.bidsAmount;

        bids.safeTransfer(msg.sender, breeding.bidsAmount);

        // event Burn(address indexed user, uint256 indexed amount) is emitted
        _burn(msg.sender, breeding.veBIDSAmount);

        emit Exit(msg.sender, breeding.unlockTime, breeding.bidsAmount, breeding.veBIDSAmount, slot, length - 1);
    }

    /// @notice update the Bids lock days such that the end date is `now` + `lockDays`
    /// @param slot the veBids slot
    /// @param lockDays the new lock days (it should be larger than original lock days)
    function update(uint256 slot, uint256 lockDays) external nonReentrant whenNotPaused returns (uint256 newVeBidsAmount) {
        _assertNotContract(msg.sender);

        require(lockDays >= uint256(minLockDays) && lockDays <= uint256(maxLockDays), "lock days is invalid");

        uint256 length = users[msg.sender].breedings.length;
        require(slot < length, "slot position should be less than the number of slots");

        uint256 originalUnlockTime = uint256(users[msg.sender].breedings[slot].unlockTime);
        uint256 originalBidsAmount = uint256(users[msg.sender].breedings[slot].bidsAmount);
        uint256 originalVeBidsAmount = uint256(users[msg.sender].breedings[slot].veBIDSAmount);
        uint256 newUnlockTime = block.timestamp + 1 days * lockDays;
        newVeBidsAmount = expectedVeBIDSAmount(originalBidsAmount, lockDays);

        if (newUnlockTime > type(uint48).max) revert VEBIDS_OVERFLOW();
        if (newVeBidsAmount > type(uint104).max) revert VEBIDS_OVERFLOW();

        require(originalUnlockTime < newUnlockTime, "the new end date must be greater than existing end date");
        require(originalVeBidsAmount < newVeBidsAmount, "the new veBids amount must be greater than existing veBids amount");

        // change unlock time and veBids amount
        users[msg.sender].breedings[slot].unlockTime = uint48(newUnlockTime);
        users[msg.sender].breedings[slot].veBIDSAmount = uint104(newVeBidsAmount);

        _mint(msg.sender, newVeBidsAmount - originalVeBidsAmount);

        // emit event
        emit UpdateLockTime(msg.sender, slot, newUnlockTime, originalBidsAmount, originalVeBidsAmount, newVeBidsAmount);
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(whitelist[_addr], "Smart contract depositors not allowed");
        }
    }

    /// @notice hook called after token operation mint/burn
    /// @dev updates masterBids
    /// @param _account the account being affected
    /// @param _newBalance the newVeBIDSBalance of the user
    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        _verifyVoteIsEnough(_account);
        masterBids.updateFactor(_account, _newBalance);
    }

    function vote(address _user, int256 _voteDelta) external override onlyVoter {
        if (_voteDelta >= 0) {
            usedVote[_user] += uint256(_voteDelta);
            _verifyVoteIsEnough(_user);
        } else {
            // reverts if usedVote[_user] < -_voteDelta
            usedVote[_user] -= uint256(-_voteDelta);
        }
        emit Vote(_user, _voteDelta);
    }

    function setLockTimes(uint32 _minLock, uint32 _maxLock) external onlyOwner {
        require(_maxLock <= 2922, "Max lock too high");
        require(_minLock > 0, "Minimum is at least 1 day");
        minLockDays = _minLock;
        maxLockDays = _maxLock;
        emit SetLockDays(_minLock,_maxLock);
    }

    //Total locked bids acquired by user without iterations.
    function userLockedBids(address _user) external view returns (uint256 _lockedBids) {
        return users[_user].userTotalBidsLocked;
    }

    function userLocksCount(address _user) external view returns (uint256 _locksCount) {
        return users[_user].breedings.length;
    }

    function userLockInfo(address _user, uint256 _lockIndex) external view returns (uint256 _lockedBids, uint256 _veBidsReceived) {
        _lockedBids = users[_user].breedings[_lockIndex].bidsAmount;
        _veBidsReceived = users[_user].breedings[_lockIndex].veBIDSAmount;
    }

    /// @notice sets masterBids address
    /// @param _masterBids the new masterBids address
    function setMasterBIDS(IMasterBids _masterBids) external onlyOwner {
        require(address(_masterBids) != address(0), "zero address");
        masterBids = _masterBids;
        emit SetMasterBIDS(address(_masterBids));
    }

    /// @notice sets voter contract address
    /// @param _voter the new NFT contract address
    function setVoter(address _voter) external onlyOwner {
        require(address(_voter) != address(0), "zero address");
        voter = _voter;
        emit SetVoter(_voter);
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(address _whitelist, bool _stat) external onlyOwner {
        whitelist[_whitelist] = _stat;
        emit SetWhiteList(address(_whitelist), _stat);
    }

    function setMaxBreedingLength(uint256 _maxBreedingLength) external onlyOwner {
        if (_maxBreedingLength > type(uint32).max) revert VEBIDS_OVERFLOW();
        maxBreedingLength = uint32(_maxBreedingLength);
        emit SetMaxBreedingLength(_maxBreedingLength);
    }
}