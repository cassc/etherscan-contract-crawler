// SPDX-License-Identifier: MIT
/**
    SUIT UP
    https://www.hazmatpepe.fun
    https://twitter.com/hazmat_pepe
    https://t.me/hazmatpepe
**/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract HazmatPepe is ERC20, Ownable {
    uint256 public _totalSupply = 100000000 * (10 ** uint256(decimals())); // Initial supply of 100,000,000 hazmat

    bool public oneBuyPerBlock = true; //Disable multiple buys per block at the start
    mapping(address => uint256) private originTxBlockMapping; //Map buys per origin tx

    constructor() ERC20("HazmatPepe", "HAZMAT") {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @notice Function to mint tokens
     * @param account The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    /**
     * @notice Function to burn tokens
     * @param amount The amount of tokens to burn.
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
    * @notice TransferFrom function
    * @param sender The address to send the tokens from.
    * @param recipient The address to receive the tokens.
    * @param amount The amount of tokens to transfer.
    * @return A boolean that indicates if the operation was successful.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(recipient != owner() && sender != owner()){
            if(oneBuyPerBlock){
                require(originTxBlockMapping[tx.origin] < block.number, "Only one buy per block allowed");
                originTxBlockMapping[tx.origin] = block.number;
            }
        }

        return super.transferFrom(sender, recipient, amount);
    }

     /**
     * @notice Function to remove all limits from contract
     */
    function setUnlimited() public onlyOwner{
        oneBuyPerBlock = false;
    }
}