/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface rewardDividend {
    function deposit() external payable;
}

error InsufficientFunds();

contract Distributor is Ownable {

    using SafeMath for uint256;
    
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public companyWallet = address(0xc60bA9Abc6EE2610efeF914835F6CC4139CeA398);
    
    IDexRouter public irouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public tradix = IERC20(0x8954D907520532c1f0d89d42569232Fd0f995Fdf);
    rewardDividend public nftDiv = rewardDividend(0xa23F2D7c3defAb98A5Ce878de461f2E79f5e9C6F);
    rewardDividend public tokenDiv = rewardDividend(0x767047703303278e0b36E796369e27A772aD56d9);

    uint[4] public shareHolding = [20,17,33,30];  // wallet,dead,nft,token
    uint256 public deno = 100;

    event deposit(uint _value, uint timestamp);

    function forwarder(uint _value) internal {    
        
        if(_value == 0) { 
            revert InsufficientFunds(); 
        }

        uint companyShare = _value.mul(shareHolding[0]).div(deno);
        uint burnShare = _value.mul(shareHolding[1]).div(deno);
        uint nftShare = _value.mul(shareHolding[2]).div(deno);
        uint tokenShare = _value.sub(companyShare).sub(burnShare).sub(nftShare); 

        if(companyShare > 0) payable(companyWallet).transfer(companyShare);
        if(burnShare > 0) buybackAndBurn(burnShare);
        if(nftShare > 0) try nftDiv.deposit{value: nftShare}() {} catch {}
        if(tokenShare > 0) try tokenDiv.deposit{value: tokenShare}() {} catch {}

        emit deposit(_value,block.timestamp);
    }

    function setRouter(address _r) external onlyOwner {
        irouter = IDexRouter(_r);   
    }

    function setToken(address _t) external onlyOwner {
        tradix = IERC20(_t);
    }

    function setNftDiv(address _nft) external onlyOwner {
        nftDiv = rewardDividend(_nft);
    }

    function settTokenDiv(address _tk) external onlyOwner {
        tokenDiv = rewardDividend(_tk); 
    }

    function setDeno(uint _d) external onlyOwner {
        deno = _d;
    }

    function setHolding(uint _index,uint _value) external onlyOwner {
        shareHolding[_index] = _value;
    }

    function setCompanyWallet(address _wallet) external onlyOwner {
        companyWallet = _wallet;
    }

    function withdraw() external onlyOwner returns (bool os) {
        (os,) = payable(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawToken(address _token,uint _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender,_amount);
    }

    function buybackAndBurn(uint _value) private {

        address[] memory path = new address[](2);
        path[0] = irouter.WETH();
        path[1] = address(tradix);

        irouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _value}(
            0,
            path,
            address(deadAddress),
            block.timestamp
        );
    }

    receive() external payable {
        forwarder(msg.value);
    }

}