// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./../interfaces/ITransferProxy.sol";
import "./../interfaces/IERC721LazyMint.sol";
import "./../librairies/LibERC721LazyMint.sol";
import "./../operator/OperatorRole.sol";

/// @notice ERC721 Lazy Mint Transfer Proxy Contract
contract ERC721LazyMintTransferProxy is OperatorRole, ITransferProxy {
    /// @notice Transfer method for ERC721 lazy minted nft
    /// @param asset asset to transfer
    /// @param from address to transfer from
    /// @param to address to transfer to
    function transfer(LibAsset.Asset memory asset, address from, address to) external override onlyOperator {
        require(asset.value == 1, "ERC721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(
            asset.assetType.data,
            (address, LibERC721LazyMint.Mint721Data)
        );
        IERC721LazyMint(token).transferFromOrMint(data, from, to);
    }
}