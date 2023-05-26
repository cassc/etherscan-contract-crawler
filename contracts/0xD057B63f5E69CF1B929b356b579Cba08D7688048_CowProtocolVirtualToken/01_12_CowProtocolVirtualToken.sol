// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "./mixins/NonTransferrableErc20.sol";
import "./mixins/Vesting.sol";
import "./mixins/Claiming.sol";
import "./mixins/MerkleDistributor.sol";
import "./vendored/mixins/StorageAccessible.sol";

/// @dev The token that manages how the CoW Protocol governance token is
/// distributed to all different types of investors.
/// @title CoW Protocol Virtual Token
/// @author CoW Protocol Developers
contract CowProtocolVirtualToken is
    NonTransferrableErc20,
    Vesting,
    Claiming,
    MerkleDistributor,
    StorageAccessible
{
    string private constant ERC20_SYMBOL = "vCOW";
    string private constant ERC20_NAME = "CoW Protocol Virtual Token";

    constructor(
        bytes32 merkleRoot,
        address cowToken,
        address payable communityFundsTarget,
        address investorFundsTarget,
        address usdcToken,
        uint256 usdcPrice,
        address gnoToken,
        uint256 gnoPrice,
        address wrappedNativeToken,
        uint256 nativeTokenPrice,
        address teamController
    )
        NonTransferrableErc20(ERC20_NAME, ERC20_SYMBOL)
        Claiming(
            cowToken,
            communityFundsTarget,
            investorFundsTarget,
            usdcToken,
            usdcPrice,
            gnoToken,
            gnoPrice,
            wrappedNativeToken,
            nativeTokenPrice,
            teamController
        )
        MerkleDistributor(merkleRoot)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /// @dev Returns the sum of tokens that are either held as
    /// instantlySwappableBalance or will be vested in the future
    /// @param user The user for whom the balance is calculated
    /// @return Balance of the user
    function balanceOf(address user) public view returns (uint256) {
        return
            instantlySwappableBalance[user] +
            fullAllocation[user] -
            vestedAllocation[user];
    }

    /// @dev Returns the balance of a user assuming all vested tokens would
    /// have been converted into virtual tokens
    /// @param user The user for whom the balance is calculated
    /// @return Balance the user would have after calling `swapAll`
    function swappableBalanceOf(address user) public view returns (uint256) {
        return instantlySwappableBalance[user] + newlyVestedBalance(user);
    }
}