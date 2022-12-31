// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/**
 * Xeno Run Token Test
 * @author XenoBlockchain
 */

contract XenoRunTokenTest is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("XenoRunTokenTest", "XRT-T") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}