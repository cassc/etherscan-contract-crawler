//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PresaleFactory is OwnableUpgradeable {

    IERC20Upgradeable public _gotAddress;
    IERC20 public _usdtAddress;

    uint256 public softCap;
    uint256 public hardCap;

    uint256 public startTime;
    uint256 public endTime;

    mapping (address => uint256) private _userPaidUSDT;

    uint256 public Total_Deposit_Amount;

    uint256 public tokensPerUSDT;

    function  initialize ()  public initializer {
        __Ownable_init();
        _gotAddress = IERC20Upgradeable(0x5cfD92D2A82bA56c3B8195Ba40610Fe196A64b45);
        _usdtAddress = IERC20(0x55d398326f99059fF775485246999027B3197955);
        softCap = 2000000_000000000000000000; //2M USDT
        hardCap = 3000000_000000000000000000; //3M USDT
        startTime = 1664582400;
        endTime =   1672444800;
        Total_Deposit_Amount = 0;
        tokensPerUSDT = 1_000000000000000000;
    }

    function buyTokensByUSDT(uint256 _amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "PresaleFactory: Not presale period");

        // token amount user want to buy
        uint256 tokenAmount = _amount / tokensPerUSDT;
        
        // transfer USDT to here
        _usdtAddress.transferFrom(msg.sender, address(this), _amount);

        Total_Deposit_Amount += _amount;

        // add USDT user bought
        _userPaidUSDT[msg.sender] += _amount;

        _gotAddress.transfer(msg.sender, (_amount * 10 ** 18) / tokensPerUSDT );

        emit Presale(address(this), msg.sender, tokenAmount);
    }

    function withdrawAll() external onlyOwner{
        require(block.timestamp > endTime);
        require(Total_Deposit_Amount >= softCap);
        uint256 balance = _usdtAddress.balanceOf(address(this));
        _usdtAddress.approve(address(this), balance);
        _usdtAddress.transfer(owner(), balance);

        emit WithdrawAll (msg.sender, balance);
    }

    function withdrawToken() public onlyOwner returns (bool) {
        require(block.timestamp > endTime);
        uint256 balance = _gotAddress.balanceOf(address(this));
        _gotAddress.approve(address(this), balance);
        return _gotAddress.transfer(msg.sender, balance);
    }

    function getUserPaidUSDT () public view returns (uint256) {
        return _userPaidUSDT[msg.sender];
    }

    function setTokensPerUsdt(uint256 _tokensPerUSDT) public onlyOwner {
        tokensPerUSDT = _tokensPerUSDT;
    }

    function setHardCap(uint256 _hardCap) public onlyOwner {
        hardCap = _hardCap;
    }

    function setSoftCap(uint256 _softCap) public onlyOwner {
        softCap = _softCap;
    }

    function softCapReached() public view returns (bool) {
        return Total_Deposit_Amount >= softCap;
    }

    event Presale(address _from, address _to, uint256 _amount);
    event SetStartTime(uint256 _time);
    event SetEndTime(uint256 _time);
    event WithdrawAll(address addr, uint256 usdt);

    receive() payable external {}

    fallback() payable external {}
}