/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface DAPP {
    function distributeAllotment() external;
    function distributeTokenAllotment(address token) external;
    function setInternal(address _address1, address _address2) external;
    function distributeTokenPercent(address token, address receiver, uint256 amount) external;
    function distributeTokenAmount(address token, address receiver, uint256 amount) external;
    function rescueETHSplitPercent(uint256 amountPercentage, address _address1, address _address2) external;
    function distributeTokenSplitPercent(address token, address _address1, address _address2, uint256 percent) external;
    function rescueETH(uint256 amountPercentage, address receiver) external;
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

contract peppinoHold is DAPP, Auth {
    address address1;
    address address2;
    constructor() Auth(msg.sender) {}
    receive() external payable {}

    function setInternal(address _address1, address _address2) external override authorized {
        address1 = _address1; address2 = _address2;
    }

    function distributeAllotment() external override {
        uint256 amountETH = address(this).balance * 5000 / 10000;
        payable(address1).transfer(amountETH);
        payable(address2).transfer(address(this).balance);
    }

    function distributeTokenAllotment(address token) external override {
        uint256 tokenAmt = IERC20(token).balanceOf(address(this)) * 5000 / 10000;
        IERC20(token).transfer(address1, tokenAmt);
        IERC20(token).transfer(address2, IERC20(token).balanceOf(address(this)));

    }

    function distributeTokenSplitPercent(address token, address _address1, address _address2, uint256 percent) external override {
        uint256 tokenAmt = IERC20(token).balanceOf(address(this)) * percent / 100;
        IERC20(token).transfer(_address1, tokenAmt);
        IERC20(token).transfer(_address2, tokenAmt);

    }
    
    function distributeTokenPercent(address token, address receiver, uint256 percent) external override authorized {
        uint256 tokenAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, (tokenAmt * percent / 100));
    }

    function distributeTokenAmount(address token, address receiver, uint256 amount) external override authorized {
        IERC20(token).transfer(receiver, amount);
    }

    function rescueETHSplitPercent(uint256 amountPercentage, address _address1, address _address2) external override authorized {
        uint256 amountETH = address(this).balance * amountPercentage / 100;
        payable(_address1).transfer(amountETH);
        payable(_address2).transfer(amountETH);
    }

    function rescueETH(uint256 amountPercentage, address receiver) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(receiver).transfer(amountETH * amountPercentage / 100);
    }
}