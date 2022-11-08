// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/BaronBase.sol";

contract BaronDirector is BaronBase, ERC20, ReentrancyGuard {
    constructor() ERC20("BaronD", "BARON-D") {}

    // Tokens are not fractionalized.
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // This allows the operator to add directors.
    function mintTo(address[] calldata directors, uint256[] calldata amounts)
        external
        nonReentrant
        onlyOperator
    {
        for (uint256 i = 0; i < directors.length; i++) {
            require(amounts[i] > 0, "amount must be nonzero");
            _mint(directors[i], amounts[i]);
        }
    }

    // This allows the operator to remove directors.
    function burnFrom(address[] calldata directors, uint256[] calldata amounts)
        external
        nonReentrant
        onlyOperator
    {
        for (uint256 i = 0; i < directors.length; i++) {
            require(amounts[i] > 0, "amount must be nonzero");
            _burn(directors[i], amounts[i]);
        }
    }
}