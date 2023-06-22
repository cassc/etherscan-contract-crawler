// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ally is ERC20Burnable, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 ichi;

    string private constant NAME_ = "ICHI Ally";
    string private constant SYMBOL_ = "ALLY";
    uint256 private constant INITIAL_SUPPLY_ = 10000000 * 1e18;
    uint256 private constant PRECISION = 1e18;

    // start time and duration are unchangeable

    uint256 public immutable commencement;
    uint256 public immutable durationSeconds;

    event Deployed(address deployer, IERC20 ichi, uint256 commencement, uint256 durationDays);
    event ClaimIchi(address user, address to, uint256 ally, uint256 ichi);
    event EmergencyWithdrawal(IERC20 token, uint256 amount, address to);

    /// @notice following the airdrop, the deployer is required to burn any surplus Ally
    /// (because totalSupply() is used in calculations) and send ICHI to the contract.

    constructor(IERC20 ichi_, uint256 commencement_, uint256 durationDays_)
        ERC20(NAME_, SYMBOL_) 
    {
        require(commencement_ >= block.timestamp, 'Ally:constructor:: commencement_ cannot be in the past');
        ichi = ichi_;
        commencement = commencement_;
        durationSeconds = durationDays_.mul(1 days);
        _mint(msg.sender, INITIAL_SUPPLY_);
        emit Deployed(msg.sender, ichi_, commencement_, durationDays_);
    }

    // redeem ichi from this contract by burning Ally

    function claimIchi(uint256 amountAlly, address to) external returns(uint256 amountIchi) {
        require(commencement < block.timestamp, 'Ally:claimIchi:: must wait for the commencement date to pass');
        require(to != address(0), "Ally:claimIchi:: to cannot be the 0x0 address");
        require(amountAlly <= balanceOf(msg.sender), 'Ally:claimIchi:: insufficient Ally balance');
        require(amountAlly <= allowance(msg.sender, address(this)), 'Ally:claimIchi:: insufficent Ally allowance');
        amountIchi = ichiForAlly(amountAlly);
        _burn(msg.sender, amountAlly);
        ichi.transfer(to, amountIchi);
        emit ClaimIchi(msg.sender, to, amountAlly, amountIchi);
    }

    // owner may withdraw liquidity from this contract to recover errant tokens or cause an emergency stop.

    function emergencyWithdraw(IERC20 token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Ally:emergencyWithdraw:: to cannot be the 0x0 address");
        token.safeTransfer(to, amount);
        emit EmergencyWithdrawal(token, amount, to);
    }

    // duration period is complete

    function complete() public view returns(bool isComplete) {
        isComplete = ageSeconds() >= durationSeconds;
    }

    // seconds completed in full

    function ageSeconds() public view returns(uint256 elapsedSeconds) {
        if(block.timestamp <= commencement) return 0;
        elapsedSeconds = block.timestamp.sub(commencement);
    }

    // 1e18 = 1.00 = 100%

    function redeemablePercent() public view returns(uint256 p18) {
        if(complete()) return PRECISION;
        p18 = ageSeconds().mul(PRECISION).div(durationSeconds);
    }

    // at completion, based on current ICHI balance and unredeemed Ally token supply
    // it is permissible to send more ICHI to this contract for proportional, time-based distribution

    function ichiPerAlly() public view returns(uint256 p18) {
        uint circulatingAlly = totalSupply();
        p18 = ichiBalance().mul(PRECISION).div(circulatingAlly);
    }

    // present value, based on ally to redeem, value at completion and redeemable percent

    function ichiForAlly(uint256 amountAlly) public view returns(uint256 amountIchi) {
        amountIchi = amountAlly.mul(ichiPerAlly()).mul(redeemablePercent()).div(PRECISION).div(PRECISION);
    }

    // courtesy view functions

    function ichiBalance() public view returns(uint256 ichiOnHand) {
        ichiOnHand = ichi.balanceOf(address(this));
    }

    function userBalances(address user) public view returns(uint256 allyBalance, uint256 claimable, uint256 uponCompletion) {
        allyBalance = balanceOf(user);
        uponCompletion = allyBalance.mul(ichiPerAlly()).div(PRECISION);
        claimable = uponCompletion.mul(redeemablePercent()).div(PRECISION);
    }

}