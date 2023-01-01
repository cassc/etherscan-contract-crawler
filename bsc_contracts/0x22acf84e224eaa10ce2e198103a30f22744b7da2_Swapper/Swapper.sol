/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(_owner == _msgSender(), "Ownable: caller is not owner");
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

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IPancakeV2Router02 is IPancakeRouter01 {

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


contract Swapper is Ownable {

    address public authorized;
    IPancakeV2Router02 public pancakeV2Router;

    modifier onlyAuthorized {
        require(authorized == msg.sender,"Error:Caller must be Authorized!");
        _;
    }

    
    constructor() {

        //Pancake Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //Pancake Testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        pancakeV2Router = IPancakeV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        authorized = msg.sender;
    
    }

    function swap(address _token) payable external onlyAuthorized {
        uint value = msg.value;
		address sender = msg.sender;
        uint ibT = IERC20(_token).balanceOf(address(this));
        brought(_token,value);
        uint rbT = IERC20(_token).balanceOf(address(this)) - ibT;
        sold(_token,rbT,sender);
    }  

    function brought(address _token, uint Rvalue) internal {
        address[] memory path = new address[](2);
        path[0] = pancakeV2Router.WETH();
        path[1] = address(_token);

        pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: Rvalue}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sold(address _token,uint tokenAmount,address _sender) internal {
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = pancakeV2Router.WETH();
        IERC20(_token).approve(address(pancakeV2Router), tokenAmount);
        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_sender),
            block.timestamp
        );
    }

    function setAuthorized(address _adr) external onlyOwner {
        authorized = _adr;   
    }

    function rescueToken(address _token) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(),balance);
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    receive() external payable {}

}