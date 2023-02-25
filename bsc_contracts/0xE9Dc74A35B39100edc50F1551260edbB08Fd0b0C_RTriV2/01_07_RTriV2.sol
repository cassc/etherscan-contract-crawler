// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Escrow.sol";

import "./interfaces/IRTriV2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RTriV2 token which allows users to fairly claim USDC using the Escrow contract
 * @author Kama#3842, Prisma Shield, https://prismashield.com
 * @notice This token is non-transferrable. The total supply of 587,000 represents the
 *         587,000 USDC owed to users who were affected by the Aequinox USDC/USDT/BUSD
 *         gauge incident. Your balance of the RTriV2 token represents the amount of
 *         USDC you are owed, and it will allow you to claim USDC from the Escrow contract
 *         based on your share of the RTriV2 token
 */
contract RTriV2 is ERC20, IRTriV2 {
    address public constant AIRDROPPER =
        0xf7fa6A0642E2593F7BDd7b2E0A2673600d53BBE9;
    Escrow public immutable ESCROW;
    uint256 public constant MINT_AMOUNT = 587000e18;

    constructor() ERC20("Recovery Trifecta V2", "rTRIV2") {
        _mint(AIRDROPPER, MINT_AMOUNT);
        ESCROW = new Escrow(this);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(
            from == AIRDROPPER || from == address(0) || to == address(0),
            "RTriV2: token non-transferrable"
        );
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == address(ESCROW), "RTriV2: burn only callable by Escrow");
        _burn(account, amount);
    }
}