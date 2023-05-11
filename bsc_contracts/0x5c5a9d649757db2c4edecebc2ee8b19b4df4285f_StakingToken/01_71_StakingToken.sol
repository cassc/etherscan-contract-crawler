// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Address.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";
import "./RootedTransferGate.sol";

import "./ERC20.sol";

import "./Pausable.sol";
import "./TokensRecoverable.sol";

contract StakingToken is ERC20("SH33P Staking", "xSH33P"), Pausable, TokensRecoverable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ///////////////
    // MODIFIERS //
    ///////////////

    // Can only stake if you have no debt
    modifier zeroDebtOnly() {
        require(rootedTransferGate.recordedDebt(msg.sender) == 0, "PAY_DEBT_FIRST");
        _;
    }

    ///////////////////////////////
    // CONFIGURABLES & VARIABLES //
    ///////////////////////////////

    IERC20 public immutable rooted;
    RootedTransferGate public immutable rootedTransferGate;

    uint256 public totalStakers;
    uint256 public allTimeStaked;
    uint256 public allTimeUnstaked;

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////

    struct AddressRecords {
        uint256 totalStaked;
        uint256 totalUnstaked;
        uint256 lastStakedPrice;
        uint256 lastUnstakedPrice;
    }

    mapping(address => AddressRecords) public addressRecord;

    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////

    event StakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event UnstakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);

    ////////////////////////////
    // CONSTRUCTOR & FALLBACK //
    ////////////////////////////

    constructor(IERC20 _rooted, address _transferGate) {
        rooted = _rooted;
        rootedTransferGate = RootedTransferGate(_transferGate);
        _pause();
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Get stats of an address
    function statsOf(address _user) public view returns (uint256 _totalStaked, uint256 _totalUnstaked, uint256 _lastStakePrice, uint256 _lastUnstakePrice) {
        return (
            addressRecord[_user].totalStaked, 
            addressRecord[_user].totalUnstaked,
            addressRecord[_user].lastStakedPrice,
            addressRecord[_user].lastUnstakedPrice
        );
    }

    // Rate of xSH33P per SH33P staked
    function baseToStaked(uint256 _amount) public view returns (uint256 _stakedAmount) {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalRooted == 0) {
            return _amount;
        } else {
            return _amount.mul(totalShares).div(totalRooted);
        }
    }

    // Rate of SH33P per xSH33P redeemed
    function stakedToBase(uint256 _amount) public view returns (uint256 _baseAmount) {
        uint256 totalShares = this.totalSupply();
        return _amount.mul(rooted.balanceOf(address(this))).div(totalShares);
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Stake SH33P, get xSH33P
    function stake(uint256 amount) public zeroDebtOnly() whenNotPaused() returns (bool success) {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (addressRecord[msg.sender].totalStaked == 0) {
            totalStakers += 1;
        }

        if (totalShares == 0 || totalRooted == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 mintAmount = amount.mul(totalShares).div(totalRooted);
            _mint(msg.sender, mintAmount);
        }

        rooted.transferFrom(msg.sender, address(this), amount);

        addressRecord[msg.sender].lastStakedPrice = baseToStaked(1e18);
        addressRecord[msg.sender].totalStaked += amount;
        allTimeStaked += amount;

        emit StakeTokens(msg.sender, amount, block.timestamp);
        return true;
    }

    // Unstake xSH33P, get SH33P
    function unstake(uint256 amount) public zeroDebtOnly() returns (bool success) {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = amount.mul(rooted.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, amount);
        rooted.transfer(msg.sender, unstakeAmount);

        addressRecord[msg.sender].lastUnstakedPrice = stakedToBase(1e18);
        addressRecord[msg.sender].totalUnstaked += unstakeAmount;
        allTimeUnstaked += unstakeAmount;

        emit UnstakeTokens(msg.sender, amount, block.timestamp);
        return true;
    }

    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////

    // Pause
    function pause() public ownerOnly() {
        _pause();
    }

    // Unpause
    function unpause() public ownerOnly() {
        _unpause();
    }

    ///////////////////////////////////
    // INTERNAL & OVERRIDE FUNCTIONS //
    ///////////////////////////////////

    // Can recover any token except the staked token
    // Can recover staked token if paused (EMERGENCY ONLY)
    function canRecoverTokens(IERC20 token) internal override view returns (bool) {
        if (paused() == true) {
            return true;
        } else {
            return address(token) != address(rooted);
        }
    }
}