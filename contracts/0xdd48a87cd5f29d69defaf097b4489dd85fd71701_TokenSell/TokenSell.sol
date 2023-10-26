/**
 *Submitted for verification at Etherscan.io on 2023-10-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function maxSupply() external view returns (uint256);
    function totalMint() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSell {
    using SafeMath for uint256;
    address private usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //we're gonna use usdt to buy dnd
    address private dnd = 0xff81FCa7921aF4F6cd4F03D4441DD11618Fe571a;
    uint256 private leftDnd;
    uint256 public feeRate;
    address public feeReceiver;
    uint256 public price;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not a contract owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    
    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    event Buy(address indexed user,uint256 amount,address indexed referral);

    function getLeftDnd() public view returns(uint256) {
         return IERC20(dnd).balanceOf(address(this));
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price * 1e18;
    }

    function setFeeRate(uint256 _feeRate) public onlyOwner {
        require(_feeRate>0 && _feeRate < 100, 'invlalid _feeRate');
        require(feeReceiver != address(0), 'feeReceiver not set');
        feeRate = _feeRate;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function claim(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        uint _startBal = IERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (IERC20(_asset).balanceOf(address(this)) - _startBal);
    }

    function buy(uint256 _amount, address _referral) public {
        uint256 allowance = IERC20(usdt).allowance(msg.sender, address(this));
        require(allowance >= _amount, 'too less allowance');

        require(price > 0, "price not set");
        uint256 dndAmount = _amount.mul(1e12).mul(1e18).div(price);
        require(getLeftDnd() >= dndAmount, "not enough token to sell");

        safeTransferFrom(usdt, _amount);
        uint256 feeAmount = dndAmount.mul(feeRate).div(100);
        if (feeAmount > 0) {
            IERC20(dnd).transfer(feeReceiver, feeAmount);
        }
        uint256 userAmount = dndAmount.sub(feeAmount);
        IERC20(dnd).transfer(msg.sender, userAmount);
        emit Buy(msg.sender, _amount, _referral);
    }
}