// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./../interfaces/ITransferProxy.sol";
import "./../interfaces/IERC1155LazyMint.sol";
import "./../librairies/LibERC1155LazyMint.sol";
import "./../operator/OperatorRole.sol";

/// @notice ERC1155 Lazy Mint Transfer Proxy Contract
contract ERC1155LazyMintTransferProxy is OperatorRole, ITransferProxy {
    /// @notice Transfer method for ERC1155 lazy minted nft
    /// @param asset asset to transfer
    /// @param from address to transfer from
    /// @param to address to transfer to
    function transfer(LibAsset.Asset memory asset, address from, address to) external override onlyOperator {
        (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(
            asset.assetType.data,
            (address, LibERC1155LazyMint.Mint1155Data)
        );
        IERC1155LazyMint(token).transferFromOrMint(data, from, to, asset.value);
    }
}