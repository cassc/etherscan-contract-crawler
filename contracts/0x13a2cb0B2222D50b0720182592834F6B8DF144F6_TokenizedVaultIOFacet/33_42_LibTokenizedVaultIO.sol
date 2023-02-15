// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibHelpers } from "./LibHelpers.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibERC20 } from "../../../erc20/LibERC20.sol";
import { ExternalDepositAmountCannotBeZero, ExternalWithdrawAmountCannotBeZero } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

/**
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
library LibTokenizedVaultIO {
    function _externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            revert ExternalDepositAmountCannotBeZero();
        }

        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        uint256 balanceBeforeTransfer = LibERC20.balanceOf(_externalTokenAddress, address(this));
        // Funds are transferred to entity
        LibERC20.transferFrom(_externalTokenAddress, msg.sender, address(this), _amount);

        uint256 balanceAfterTransfer = LibERC20.balanceOf(_externalTokenAddress, address(this));

        uint256 mintAmount = balanceAfterTransfer - balanceBeforeTransfer;

        // note: Only mint what has been collected.
        LibTokenizedVault._internalMint(_receiverId, internalTokenId, mintAmount);
    }

    function _externalWithdraw(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            revert ExternalWithdrawAmountCannotBeZero();
        }

        // withdraw from the user's entity
        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        // burn internal token
        LibTokenizedVault._internalBurn(_entityId, internalTokenId, _amount);

        // transfer AFTER burn
        LibERC20.transfer(address(_externalTokenAddress), _receiver, _amount);
    }
}