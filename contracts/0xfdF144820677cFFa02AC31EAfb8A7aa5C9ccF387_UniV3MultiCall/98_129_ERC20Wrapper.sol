// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IAddressRegistry} from "../../interfaces/IAddressRegistry.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypesPeerToPeer} from "../../../peer-to-peer/DataTypesPeerToPeer.sol";
import {Errors} from "../../../Errors.sol";
import {IERC20Wrapper} from "../../interfaces/wrappers/ERC20/IERC20Wrapper.sol";
import {IWrappedERC20Impl} from "../../interfaces/wrappers/ERC20/IWrappedERC20Impl.sol";

/**
 * @dev ERC20Wrapper is a contract that wraps tokens from possibly multiple ERC20 contracts
 * IMPORTANT: This contract allows for wrapping tokens that are whitelisted with the address registry.
 */
contract ERC20Wrapper is ReentrancyGuard, IERC20Wrapper {
    using SafeERC20 for IERC20;
    address public immutable addressRegistry;
    address public immutable wrappedErc20Impl;
    address[] public tokensCreated;

    constructor(address _addressRegistry, address _wrappedErc20Impl) {
        if (_addressRegistry == address(0) || _wrappedErc20Impl == address(0)) {
            revert Errors.InvalidAddress();
        }
        addressRegistry = _addressRegistry;
        wrappedErc20Impl = _wrappedErc20Impl;
    }

    // token addresses must be unique and passed in increasing order.
    // token amounts must be non-zero.
    // minter must approve this contract to transfer all tokens to be wrapped.
    function createWrappedToken(
        address minter,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol
    ) external nonReentrant returns (address newErc20Addr) {
        if (msg.sender != addressRegistry) {
            revert Errors.InvalidSender();
        }
        if (minter == address(0) || minter == address(this)) {
            revert Errors.InvalidAddress();
        }
        // @dev: allow multiple wrappers with same underlyings to exist
        // note: in case a griefer wanted to lock-up a wrapper token one could easily create another one
        newErc20Addr = Clones.clone(wrappedErc20Impl);
        tokensCreated.push(newErc20Addr);

        // @dev: external call happens before state update due to minTokenAmount determination
        (
            uint256 numTokensToBeWrapped,
            uint256 minTokenAmount
        ) = _transferTokens(minter, tokensToBeWrapped, newErc20Addr);
        // @dev: case where numTokensToBeWrapped == 0 represents an IOU token
        IWrappedERC20Impl(newErc20Addr).initialize(
            minter,
            tokensToBeWrapped,
            numTokensToBeWrapped == 0 ? 10 ** 18 : minTokenAmount,
            name,
            symbol
        );
        emit ERC20WrapperCreated(
            newErc20Addr,
            minter,
            tokensCreated.length,
            tokensToBeWrapped
        );
    }

    function allTokensCreated() external view returns (address[] memory) {
        return tokensCreated;
    }

    function numTokensCreated() external view returns (uint256) {
        return tokensCreated.length;
    }

    function _transferTokens(
        address minter,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        address newErc20Addr
    ) internal returns (uint256 numTokensToBeWrapped, uint256 minTokenAmount) {
        minTokenAmount = type(uint256).max;
        address prevTokenAddress;
        address currAddress;
        numTokensToBeWrapped = tokensToBeWrapped.length;
        for (uint256 i; i < numTokensToBeWrapped; ) {
            if (
                !IAddressRegistry(addressRegistry).isWhitelistedERC20(
                    tokensToBeWrapped[i].tokenAddr
                )
            ) {
                revert Errors.NonWhitelistedToken();
            }
            currAddress = tokensToBeWrapped[i].tokenAddr;
            if (currAddress <= prevTokenAddress) {
                revert Errors.NonIncreasingTokenAddrs();
            }
            if (tokensToBeWrapped[i].tokenAmount == 0) {
                revert Errors.InvalidSendAmount();
            }
            minTokenAmount = minTokenAmount > tokensToBeWrapped[i].tokenAmount
                ? tokensToBeWrapped[i].tokenAmount
                : minTokenAmount;
            IERC20(tokensToBeWrapped[i].tokenAddr).safeTransferFrom(
                minter,
                newErc20Addr,
                tokensToBeWrapped[i].tokenAmount
            );
            prevTokenAddress = currAddress;
            unchecked {
                ++i;
            }
        }
    }
}