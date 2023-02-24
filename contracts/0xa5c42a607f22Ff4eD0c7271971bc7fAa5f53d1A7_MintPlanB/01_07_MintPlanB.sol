// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./OnlyContract.sol";

interface PlanB {
    function mint(address to,uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approveToMinter(address minter, address to, uint256 amount) external;
}

contract MintPlanB is ERC20, ERC20Burnable, OnlyContract {
    PlanB token;
    uint lockTime = 21 days;

    struct MintDeposit {
        uint256 total;
        uint256 nextReward;
        uint256 rewardAmount;
        uint8 freeGenesisNFT; 
    }

    mapping(address => MintDeposit) public minters;

    event Deposit(address indexed _minter, uint256 _total);
    event Mint(address indexed from, address indexed to, uint256 _value);

    constructor(address mintContract, address _token) OnlyContract(mintContract) ERC20("Mint PlanB DAO", "mtPLANB") {
        token = PlanB(_token);
    }

    modifier isMinter() {
        require(minters[msg.sender].nextReward < block.timestamp, "You are not allowed to mint yet.");
        require(minters[msg.sender].total > 0, "You are not a minter.");
        _;
    }

    function deposit(address _address, uint256 _total, uint256 _nextReward, uint256 _reward) public onlyContract() {
        MintDeposit storage minter = minters[_address];
        minter.total = _total;
        minter.nextReward = _nextReward;
        minter.rewardAmount = _reward;
        minter.freeGenesisNFT = 1;

        _mint(_address, _total);

        emit Deposit(_address, _total);
    }

    function mint() public isMinter() {
        MintDeposit storage minter = minters[msg.sender];
        token.mint(msg.sender, minter.rewardAmount);
        minter.nextReward = block.timestamp + lockTime;
        minter.total = minter.total - minter.rewardAmount;
        burn(minter.rewardAmount);

        emit Mint(address(0), msg.sender, minter.rewardAmount);
    }

    function nextReward() public view returns (uint256) {
        return minters[msg.sender].nextReward;
    }

    function hasFreeGenisisNFT() public view returns (uint8) {
        return minters[msg.sender].freeGenesisNFT;
    }
}