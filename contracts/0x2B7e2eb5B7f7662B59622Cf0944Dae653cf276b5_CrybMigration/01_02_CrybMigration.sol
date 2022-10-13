//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrybMigration {

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);
    event TokenSwapped (address indexed account, uint256 indexed v1Amount, uint256 indexed v2Amount, uint256 swapTime);

    address public owner;

    IERC20 public crybTokenV1;
    IERC20 public crybTokenV2;

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not a owner");
        _;
    }

    constructor (IERC20 _crybTokenV1, IERC20 _crybTokenV2) {
        owner = msg.sender;
        crybTokenV1 = _crybTokenV1;
        crybTokenV2 = _crybTokenV2;
    }

    function swapToken(uint256 amount) external returns(bool) {
        require(amount >= 10**9,"Swapping: Amount less than minimum swap amount");
        crybTokenV1.transferFrom(msg.sender, address(this), amount);
        uint256 v2TokenAmt = amount / 10**9 ;
        crybTokenV2.transfer(msg.sender, v2TokenAmt);
        emit TokenSwapped(msg.sender, amount, v2TokenAmt, block.timestamp);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }
    
    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }
}