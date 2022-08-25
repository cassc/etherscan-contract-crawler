// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
    function distribute(uint256 amount) external;
    function staking_contract_token() external view returns(address);
}

/**
 * Distributes Xi tokens to stakers at the rate of 250K Xi per week
 * Anyone can call the distribution function which computes the next distribution
 * Linearly
*/
contract XiDistributor is Pausable, Ownable {

    uint256 constant public DISTRIBUTION_AMOUNT = 250000 ether;
    uint256 constant public SECONDS_IN_ONE_WEEK = 7*24*3600; //604800
    uint256 constant public DISTRIBUTION_PER_SEC = DISTRIBUTION_AMOUNT / SECONDS_IN_ONE_WEEK;

    IERC20 public xiToken = IERC20(0x295B42684F90c77DA7ea46336001010F2791Ec8c);
    IStaking public staking = IStaking(0x3D91E3cD7C77FDb7251d77c76AF879B35AC16213);
    uint256 public lastCall = 1661156950; // timestamp of the last manual distribution

    constructor() Pausable() Ownable() {
        /// @dev create unlimited approval
        xiToken.approve(staking.staking_contract_token(), 2**256 - 1);
    }

    /**
     * @return res current pending xi distribution
    */
    function pending() public view returns (uint256 res) {
        res = (block.timestamp - lastCall) * DISTRIBUTION_PER_SEC;
    }

    /**
     * Call this to distribute pending XI to staking
    */
    function distribute() external whenNotPaused() {
        staking.distribute(pending());
        lastCall = block.timestamp;
    }

    function pause() external onlyOwner() {
        _pause();
    }

    function unpause() external onlyOwner() {
        _unpause();
    }

    function withdraw(address to, uint256 amount) external onlyOwner() {
        xiToken.transfer(to, amount);
    }
}