// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../errors.sol";
import {ISwapFactory} from "../interfaces/ISwapFactory.sol";
import {OpFactory} from "../OpFactory.sol";
import {DefiOp} from "../DefiOp.sol";

contract SwapFactory is ISwapFactory, OpFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    address immutable OWNER;
    EnumerableSet.AddressSet private _whitelistedTokens;

    constructor(
        address opImplementation_,
        address[] memory initiallyWhitelistedTokens,
        address owner
    ) OpFactory(opImplementation_) {
        OWNER = owner;

        for (uint256 i = 0; i < initiallyWhitelistedTokens.length; i++) {
            _whitelistedTokens.add(initiallyWhitelistedTokens[i]);
        }
    }

    function whitelistToken(address token) external onlyOwner {
        _whitelistedTokens.add(token);
    }

    function blacklistToken(address token) external onlyOwner {
        _whitelistedTokens.remove(token);
    }

    function isTokenWhitelisted(address token) external view returns (bool) {
        return _whitelistedTokens.contains(token);
    }

    function whitelistedTokens() external view returns (address[] memory wt) {
        wt = new address[](_whitelistedTokens.length());
        for (uint256 i = 0; i < wt.length; i++) {
            wt[i] = _whitelistedTokens.at(i);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER, "Only owner");
        _;
    }
}