// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibUtil } from "../Libraries/LibUtil.sol";
import { ZeroAddress, LengthMissmatch, NotInitialized } from "../Errors/GenericErrors.sol";

/// @title ERC20 Proxy
/// @notice Proxy contract for safely transferring ERC20 tokens for swaps/executions
contract ERC20Proxy is Ownable {
    /// Storage ///
    address public diamond;

    /// Events ///
    event DiamondSet(address diamond);

    /// Constructor
    constructor(address _owner, address _diamond) {
        transferOwnership(_owner);
        diamond = _diamond;
    }

    function setDiamond(address _diamond) external onlyOwner {
        if (_diamond == address(0)) revert ZeroAddress();
        diamond = _diamond;

        emit DiamondSet(_diamond);
    }

    /// @dev Transfers tokens from user to the diamond and calls it
    /// @param tokens Addresses of tokens that should be sent to the diamond
    /// @param amounts Corresponding amounts of tokens
    /// @param facetCallData Calldata that should be passed to the diamond
    /// Should contain any cross-chain related function
    function startViaRubic(
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory facetCallData
    ) external payable {
        if (diamond == address(0)) revert NotInitialized();

        uint256 tokensLength = tokens.length;
        if (tokensLength != amounts.length) revert LengthMissmatch();

        for (uint256 i = 0; i < tokensLength; ) {
            LibAsset.transferFromERC20(
                tokens[i],
                msg.sender,
                diamond,
                amounts[i]
            );

            unchecked {
                ++i;
            }
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = diamond.call{ value: msg.value }(
            facetCallData
        );
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }
    }
}