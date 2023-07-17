// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DCXLAUNCHPAD is Ownable { 

    IERC20 public token;
    uint256 public ethAmount;
    uint256 public usdtamount;
    address public adminaddress;
    address public usdtaddress;

    event coinTransfer(address useraddress, uint amount);
    event tokenTransfer(address useraddress, uint amount);
    mapping (address => uint256) public balances;
    mapping(address => Deposit) public deposits;

    struct Deposit {
        address user;
        uint amount;
        uint time;
        string currency;
    }

    constructor(address _adminaddress,address _usdtaddress) {
        adminaddress = _adminaddress;
        usdtaddress = _usdtaddress;
    }

    function ExchangeETHforToken(uint _usdtamount) public payable { 
        if(msg.value <= 0) {
            require(_usdtamount > 0,"Amount required"); 
            usdtamount = usdtamount + _usdtamount;
            IERC20(usdtaddress).transferFrom(msg.sender,adminaddress,_usdtamount); 
            deposits[msg.sender].user = msg.sender;
            deposits[msg.sender].amount = _usdtamount;
            deposits[msg.sender].time = block.timestamp;
            deposits[msg.sender].currency = "USDT";
            emit tokenTransfer(msg.sender, _usdtamount);
        } 
        else {
            uint256 amount = msg.value;
            ethAmount = ethAmount + amount;
            balances[msg.sender] = balances[msg.sender] + msg.value;
            payable(adminaddress).transfer(amount);

            deposits[msg.sender].user = msg.sender;
            deposits[msg.sender].amount = msg.value;
            deposits[msg.sender].currency = "ETH";
            deposits[msg.sender].time = block.timestamp;

            emit coinTransfer(msg.sender, ethAmount);
        }
    }

    function updateadmin(address admin) public onlyOwner {
        adminaddress = admin;
    }

    function updateusdtaddress(address _usdtaddress) public onlyOwner {
        usdtaddress = _usdtaddress;
    }

    function withdrawTokens(address beneficiary, address tokenAddress) public onlyOwner {
        require(IERC20(tokenAddress).transfer(beneficiary, IERC20(tokenAddress).balanceOf(address(this))));
    }

    function transferether(address useradminaddress) public onlyOwner {
        uint256 bal = address(this).balance;
		payable(useradminaddress).transfer(bal);
    }
}