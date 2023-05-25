// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CitaDAO is ERC20 {
    uint256 private constant DECIMALS = 18;
    uint256 private constant TOKEN_WEI = 10**uint256(DECIMALS);

    uint256 private constant INITIAL_WHOLE_TOKENS = uint256(1 * (10**10));
    uint256 private constant INITIAL_SUPPLY =
        uint256(INITIAL_WHOLE_TOKENS) * uint256(TOKEN_WEI);

    /**
     * @dev Constructor that gives specified ownerAddress all of existing tokens.
     */
    constructor(address ownerAddress) public ERC20("CitaDAO", "KNIGHT") {
        _mint(ownerAddress, INITIAL_SUPPLY);
    }
}