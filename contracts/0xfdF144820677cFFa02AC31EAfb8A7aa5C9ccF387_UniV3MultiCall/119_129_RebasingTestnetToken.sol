// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Errors} from "../Errors.sol";
import {TestnetToken} from "./TestnetToken.sol";

contract RebasingTestnetToken is TestnetToken {
    address[] public tokenHolders;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 initialMint,
        uint256 _mintCoolDownPeriod,
        uint256 _mintAmountPerCoolDownPeriod
    )
        TestnetToken(
            _name,
            _symbol,
            __decimals,
            initialMint,
            _mintCoolDownPeriod,
            _mintAmountPerCoolDownPeriod
        )
    {} // solhint-disable no-empty-blocks

    function rebase(
        int256 rebaseInBASE,
        uint256 maxIterations
    ) external onlyOwner {
        for (uint256 i; i < tokenHolders.length; ++i) {
            if (i > maxIterations) {
                break;
            }
            address tokenHolder = tokenHolders[i];
            if (rebaseInBASE > 0) {
                uint256 mintAmount = (balanceOf(tokenHolder) *
                    uint256(rebaseInBASE)) / 10 ** 18;
                _mint(tokenHolder, mintAmount);
            } else if (rebaseInBASE < 0 && rebaseInBASE >= -10 ** 18) {
                uint256 burnAmount = (balanceOf(tokenHolder) *
                    uint256(rebaseInBASE)) / 10 ** 18;
                _burn(tokenHolder, burnAmount);
            } else {
                revert("Invalid rebaseInBase!");
            }
        }
    }

    function testnetMint() public override {
        tokenHolders.push(msg.sender);
        super.testnetMint();
    }
}