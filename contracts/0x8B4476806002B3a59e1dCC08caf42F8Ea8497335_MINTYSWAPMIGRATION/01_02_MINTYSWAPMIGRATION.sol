// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MINTYSWAPMIGRATION {

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);
    event TokenSwapped (address indexed account, uint256 indexed amount, uint256 indexed swapTime);

    address public owner;

    IERC20 public mintySwapV1;
    IERC20 public mintySwapV2;

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not a owner");
        _;
    }

    constructor (IERC20 _mintySwapV1, IERC20 _mintySwapV2) {
        owner = msg.sender;
        mintySwapV1 = _mintySwapV1;
        mintySwapV2 = _mintySwapV2;
    }

    function swapToken(uint256 amount) external returns(bool) {
        require(amount != 0,"Swapping: amount shouldn't be zero");
        mintySwapV1.transferFrom(msg.sender, address(this), amount);
        mintySwapV2.transfer(msg.sender, amount);
        emit TokenSwapped(msg.sender, amount, block.timestamp);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function recoverToken(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function recoverETH(address tokenAddress,uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }
}