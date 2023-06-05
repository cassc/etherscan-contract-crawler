/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}
contract teenCmtyEcologyV1 {
    address public constant Owner = 0x1834106592480233317193890309075231129966;
    modifier onlyOwner() {
        require(msg.sender == Owner, 'Not owner!');
        _;
    }
    mapping(address => uint256) public Discount;
    mapping(address => uint256) public stakingAmount;
    address public constant Teencoin = 0xFA2Ba20A47827555679DEA01fd4155C6FECbC39b;
    bool public ICO = true;
    uint256 public constant teencoinPerEth = 1000000;
    uint256 public unlockTime = 0;
    uint256 public totalStakingAmount = 0;
    constructor() {}
    receive() external payable {
        if(ICO) {
            uint256 Balance = IERC20(Teencoin).balanceOf(address(this));
            uint256 Amount = msg.value * teencoinPerEth * (100 + Discount[msg.sender]) / 100;
            require(Balance - Amount >= totalStakingAmount, 'Insufficient balance for total staking amount!');
            IERC20(Teencoin).transfer(msg.sender, Amount);
        }
    }
    function Staking() external returns (bool) {
        uint256 Amount = IERC20(Teencoin).balanceOf(msg.sender);
        IERC20(Teencoin).transferFrom(msg.sender, address(this), Amount);
        stakingAmount[msg.sender] += Amount;
        totalStakingAmount += Amount;
        return true;
    }
    function unStaking() external returns (bool) {
        require(block.timestamp > unlockTime, 'Time error!');
        uint256 Amount = stakingAmount[msg.sender];
        stakingAmount[msg.sender] = 0;
        totalStakingAmount -= Amount;
        IERC20(Teencoin).transfer(msg.sender, Amount);
        return true;
    }
    function setICO(bool boolean) external onlyOwner() returns (bool) {
        ICO = boolean;
        return true;
    }
    function setDiscount(address buyer, uint256 discount) external onlyOwner() returns (bool) {
        Discount[buyer] = discount;
        return true;
    }
    function setUnlockTime(uint256 unlocktime) external onlyOwner() returns (bool) {
        unlockTime = unlocktime;
        return true;
    }
    function Withdraw() external onlyOwner() returns (bool) {
        uint256 Balance = IERC20(Teencoin).balanceOf(address(this));
        if(Balance > totalStakingAmount) IERC20(Teencoin).transfer(msg.sender, Balance - totalStakingAmount);
        (bool Sent, bytes memory Data) = msg.sender.call{value: address(this).balance}('');
        require(Sent, 'Withdraw failed!');
        return true;
    }
}