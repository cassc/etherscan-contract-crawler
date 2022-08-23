// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC20 } from "../../../deps/oz_c_4_7_2/IERC20.sol";

import { IIkaniERC20 } from "../../../erc20/interfaces/IIkaniERC20.sol";

import { IS2Storage } from "../../v2/impl/IS2Storage.sol";

/**
 * @title IS2_1Erc20
 * @author Cyborg Labs, LLC
 *
 * @notice Handles interactions with the ERC20 token.
 */
abstract contract IS2_1Erc20 is
    IS2Storage
{
    //---------------- Constants ----------------//

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable REWARDS_ERC20;

    uint256 private constant REWARDS_CONVERSION_FACTOR = 1e6;

    //---------------- Constructor ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address rewardsErc20
    ) {
        REWARDS_ERC20 = rewardsErc20;
    }

    //---------------- Internal Functions ----------------//

    function _issueRewards(
        address recipient,
        uint256 rewardsAmount
    )
        internal
        returns (uint256)
    {
        uint256 erc20Amount = _getErc20Amount(rewardsAmount);
        // Note: Not using SafeERC20, to save a bit of gas, since this is our own token.
        IERC20(REWARDS_ERC20).transfer(
            recipient,
            erc20Amount
        );
        return erc20Amount;
    }

    function _burnErc20(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        IIkaniERC20(REWARDS_ERC20).burnWithPermit(
            owner,
            burnAmount,
            burnReceipt,
            burnReceiptData,
            deadline,
            v,
            r,
            s
        );
    }

    function _getErc20Amount(
        uint256 rewardsAmount
    )
        internal
        pure
        returns (uint256)
    {
        return rewardsAmount * REWARDS_CONVERSION_FACTOR;
    }
}