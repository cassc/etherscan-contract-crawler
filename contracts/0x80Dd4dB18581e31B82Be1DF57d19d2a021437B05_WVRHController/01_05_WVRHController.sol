// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeMath.sol";
import "EnumerableSet.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface VotingEscrow {
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
}

interface GasEscrow {
    function create_gas(uint256 _value) external;
    function increase_amount(uint256 _value) external;
    function clear_gas() external;
}

interface Guild {
    function join_guild() external;
    function user_checkpoint(address addr) external returns (bool);
}

interface Minter {
    function mint() external;
}

interface WVRHStakePool{
    function notifyRewardAmount(uint256 reward) external;
}

contract WVRHController is Ownable {
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private operators;

    event ConvertToWVRH(address sender, uint256 amount);
    event ClaimVrh(uint256 bonusAmount, uint256 );

    address public vrhAddress;
    address public wvrhAddress;
    address public votingEscrowAddress;
    address public mohAddress;
    address public gasEscrowAddress;
    address public minterAddress;
    uint256 public MAXTIME = 4 * 365 * 86400;
    address public fundAddress;
    uint256 public fundRatio;
    uint256 private MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address public poolAddress;
    address public guildAddress;

    constructor(address _vrhAddress, address _wvrhAddress, address _votingEscrowAddress, address _mohAddress, address _gasEscrowAddress,
        address _minterAddress, address _fundAddress, uint256 _fundRatio, address _poolAddress){
        vrhAddress = _vrhAddress;
        wvrhAddress = _wvrhAddress;
        votingEscrowAddress = _votingEscrowAddress;

        mohAddress = _mohAddress;
        gasEscrowAddress = _gasEscrowAddress;

        minterAddress = _minterAddress;
        fundAddress = _fundAddress;
        fundRatio = _fundRatio;
        poolAddress = _poolAddress;

        IERC20(vrhAddress).approve(votingEscrowAddress, MAX_INT);
        IERC20(mohAddress).approve(gasEscrowAddress, MAX_INT);
    }

    function addOperator(address _operator) external onlyOwner {
        operators.add(_operator);
    }

    function deletedOperator(address _operator) external onlyOwner {
        operators.remove(_operator);
    }

    function isOperator(address _operator) public view returns (bool){
        return operators.contains(_operator);
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "not operator");
        _;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function setFundRatio(uint256 _fundRatio) external onlyOwner {
        fundRatio = _fundRatio;
    }


    function convertToWVRH(uint256 _amount) external{
        require(_amount > 0, "amount invalid");

        require(IERC20(vrhAddress).transferFrom(msg.sender, address(this), _amount));

        IERC20(wvrhAddress).mint(msg.sender, _amount);

        emit ConvertToWVRH(msg.sender, _amount);
    }

    function createVrhLock() external onlyOperator{
        uint256 balance = IERC20(vrhAddress).balanceOf(address(this));
        require(balance > 0, "balance invalid");
        VotingEscrow(votingEscrowAddress).create_lock(balance, block.timestamp + MAXTIME);
    }

    function increaseVrhAmount() external onlyOperator{
        uint256 balance = IERC20(vrhAddress).balanceOf(address(this));
        require(balance > 0, "balance invalid");
        VotingEscrow(votingEscrowAddress).increase_amount(balance);
    }

    function increaseVrhUnlockTime() external onlyOperator{
        VotingEscrow(votingEscrowAddress).increase_unlock_time(block.timestamp + MAXTIME);
    }

    function createGas() external onlyOperator{
        uint256 balance = IERC20(mohAddress).balanceOf(address(this));
        require(balance > 0, "balance invalid");
        GasEscrow(gasEscrowAddress).create_gas(balance);
    }

    function increaseGasAmount() external onlyOperator{
        uint256 balance = IERC20(mohAddress).balanceOf(address(this));
        require(balance > 0, "balance invalid");
        GasEscrow(gasEscrowAddress).increase_amount(balance);
    }

    function clearGas() external onlyOperator{
        GasEscrow(gasEscrowAddress).clear_gas();
    }


    function joinGuild(address _guildAddress) external onlyOperator{
        Guild(_guildAddress).join_guild();
        guildAddress = _guildAddress;
    }

    function updatePower() external onlyOperator{
        require( Guild(guildAddress).user_checkpoint(address(this)) );
    }

    function claimVrh() external onlyOperator{

        uint256 balanceBefore = IERC20(vrhAddress).balanceOf(address(this));
        Minter(minterAddress).mint();
        uint256 balanceAfter = IERC20(vrhAddress).balanceOf(address(this));

        uint256 bonus = balanceAfter.sub(balanceBefore);

        require(bonus > 0, "bonus invalid");

        uint256 fund = bonus.mul(fundRatio).div(1000);
        IERC20(vrhAddress).transfer(fundAddress, fund);

        uint256 poolAmount = bonus.sub(fund);
        IERC20(vrhAddress).transfer(poolAddress, poolAmount);
        WVRHStakePool(poolAddress).notifyRewardAmount(poolAmount);

    }

    function addExtraReward(uint256 _amount) external onlyOperator{
        require(_amount > 0, "amount invalid");

        require(IERC20(vrhAddress).transferFrom(fundAddress, poolAddress, _amount));

        WVRHStakePool(poolAddress).notifyRewardAmount(_amount);
    }

}