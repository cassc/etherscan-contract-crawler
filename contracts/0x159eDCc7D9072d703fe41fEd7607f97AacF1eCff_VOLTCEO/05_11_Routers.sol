// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router02.sol";

contract Bridge is Ownable {
    // This is a state variable called "count" that stores an unsigned integer value.
    // Buycount rule for the main contract with declared addresses for swaps, routers, bridges
    uint256 public count;
    uint256 public buyCount = 0;
    address public _uniswapV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public bridge = 0xC55e38152c2771A50936d252aa9b48a9dD0b5b62;
    IUniswapV2Router02 public _uniswapV2Router;

    // This event is emitted when the value of count is updated.
    event CountUpdated(uint256 newCount);

    // This is the constructor of the contract, which is called only once when the contract is deployed.
    constructor() {
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    // This is a public function called "incrementCount" that updates the value of the "count" variable.
    function incrementCount() public {
        // Increment the value of count by 1.
        count += 1;

        // Emit the CountUpdated event with the new value of count.
        emit CountUpdated(count);
    }
}