// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {OwnableUninitialized} from "./vendor/common/OwnableUninitialized.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// solhint-disable-next-line max-states-count
contract FeeTreasury is OwnableUninitialized, Initializable {
    using SafeERC20 for IERC20;

    address private immutable _weth;

    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX
    address private _lpToken;
    mapping(address => bool) private _whitelistedRouter;
    mapping(address => bool) private _whitelistedAdmin;
    address private _feeDistributor;
    address private _operationsCollector;
    uint32 private _twapDuration;
    uint24 private _maxTwapDelta;
    uint16 private _protocolFeeBPS;

    // APPPEND ADDITIONAL STATE VARS BELOW:
    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX

    constructor(address weth_) {
        _weth = weth_;
    }

    function withdrawTokens(IERC20[] calldata tokens, address target) external onlyOwner {
        for (uint256 i=0; i<tokens.length; i++) {
            uint256 bal = tokens[i].balanceOf(address(this));
            if (bal > 0) {
                tokens[i].safeTransfer(target, bal);
            }
        }
    }
}