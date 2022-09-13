// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./contracts/ERC20.sol";
import "./access/Ownable.sol";
import "./interfaces/IBEP20Token.sol";

/**
 * @title Coin2Fish Contract for Coin2Fish Reborn Token
 * @author HeisenDev
 */
contract Coin2FishRebornStaking is ERC20, Ownable {
    string private _tokenName = "Coin2Fish Reborn Staking";
    string private tokenSymbol = "C2FR STK";
    mapping(address => uint) private _stakeRewards;
    mapping(address => uint) private _stakeAmount;
    mapping(address => uint) private _stakeStartDate;
    mapping(address => uint) private _stakeEndDate;
    mapping(address => uint) private _stakeType;

    event StakeC2FR(address indexed sender, uint amount, uint stakeType, uint _type);
    event Deposit(address indexed sender, uint amount);
    event Claim(address indexed sender, uint _amount);
    constructor() ERC20(_tokenName, tokenSymbol) {
        _mint(_msgSender(), 100000000 * 10 ** 18);
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }

    function stakeTokens(uint _amount, uint _type) external {
        require(_amount > 0, "Staking: You deposit send at least some tokens");
        IBEP20 _token = IBEP20(0x965eDD6B429B664082ce56FF31632446FF562d03);
        uint256 allowance = _token.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "Staking: Check the token allowance");
        _token.transferFrom(_msgSender(), address(0x965eDD6B429B664082ce56FF31632446FF562d03), _amount);
        uint256 duration = 0;
        uint256 rewards = 0;
        if (_type == 1) {
            duration = 7 days;
            rewards = 0;
        }
        if (_type == 2) {
            duration = 15 days;
            rewards = _amount * 5 / 100;
            _stakeType[_msgSender()] = 2;
        }
        if (_type == 3) {
            duration = 30 days;
            rewards = _amount * 10 / 100;
            _stakeType[_msgSender()] = 3;
        }
        _stakeRewards[_msgSender()] = _stakeRewards[_msgSender()] + rewards;
        _stakeAmount[_msgSender()] = _stakeAmount[_msgSender()] + _amount;
        uint _amountRewards = _amount + rewards;
        if (_stakeEndDate[_msgSender()] == 0) {
            _stakeStartDate[_msgSender()] = block.timestamp;
            _stakeEndDate[_msgSender()] = block.timestamp + duration;

        } else if (_stakeEndDate[_msgSender()] > block.timestamp && _stakeEndDate[_msgSender()] < (block.timestamp + duration)) {
            _stakeEndDate[_msgSender()] = block.timestamp + duration;
        } else if (_stakeEndDate[_msgSender()] > block.timestamp && _stakeEndDate[_msgSender()] > (block.timestamp + duration)) {
            _stakeEndDate[_msgSender()] = _stakeEndDate[_msgSender()];
        }
        super.transfer(_msgSender(), _amountRewards);
        emit StakeC2FR(_msgSender(), _amount, rewards, _type);
    }

    function stakeTokensBNB(uint _type) external payable {
        require(msg.value > 0, "Staking: You deposit send at least some BNB");
        IBEP20 wBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        IBEP20 C2FR = IBEP20(0x965eDD6B429B664082ce56FF31632446FF562d03);
        uint amountC2FR = C2FR.balanceOf(0x563f7e59b6ae806de190fd2399d44682f65C84b8);
        uint amountBNB = wBNB.balanceOf(0x563f7e59b6ae806de190fd2399d44682f65C84b8);
        uint price = amountBNB / amountC2FR;
        uint _amount = msg.value * price;
        uint duration = 0;
        uint rewards = 0;
        if (_type == 1) {
            duration = 7 days;
            rewards = 0;
        }
        if (_type == 2) {
            duration = 15 days;
            rewards = _amount * 5 / 100;
            _stakeType[_msgSender()] = 2;
        }
        if (_type == 3) {
            duration = 30 days;
            rewards = _amount * 1 / 100;
            _stakeType[_msgSender()] = 3;
        }
        _stakeRewards[_msgSender()] = _stakeRewards[_msgSender()] + rewards;
        _stakeAmount[_msgSender()] = _stakeAmount[_msgSender()] + _amount;
        uint _amountRewards = _amount + rewards;
        if (_stakeEndDate[_msgSender()] == 0) {
            _stakeStartDate[_msgSender()] = block.timestamp;
            _stakeEndDate[_msgSender()] = block.timestamp + duration;

        } else if (_stakeEndDate[_msgSender()] > block.timestamp && _stakeEndDate[_msgSender()] < (block.timestamp + duration)) {
            _stakeEndDate[_msgSender()] = block.timestamp + duration;
        } else if (_stakeEndDate[_msgSender()] > block.timestamp && _stakeEndDate[_msgSender()] > (block.timestamp + duration)) {
            _stakeEndDate[_msgSender()] = _stakeEndDate[_msgSender()];
        }
        super.transfer(_msgSender(), _amountRewards);
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
        emit StakeC2FR(_msgSender(), _amount, rewards, _type);
    }
    function claim() external {
        require(_stakeEndDate[_msgSender()] < block.timestamp, "Staking: Your stake is active, please wait");
        require(_stakeAmount[_msgSender()] > 0, "Staking: You don't have staked C2FR Tokens");
        uint _amount = _stakeAmount[_msgSender()] + _stakeRewards[_msgSender()];
        uint256 allowance = super.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "Staking: Check the C2FR Stake token allowance");
        super.transferFrom(_msgSender(), address(this), _amount);
        IBEP20 _token = IBEP20(0x965eDD6B429B664082ce56FF31632446FF562d03);
        _token.transfer(_msgSender(), _amount);
        _stakeRewards[_msgSender()] = 0;
        _stakeAmount[_msgSender()] = 0;
        _stakeStartDate[_msgSender()] = 0;
        _stakeEndDate[_msgSender()] = 0;
        emit Claim(_msgSender(), _amount);
    }
}