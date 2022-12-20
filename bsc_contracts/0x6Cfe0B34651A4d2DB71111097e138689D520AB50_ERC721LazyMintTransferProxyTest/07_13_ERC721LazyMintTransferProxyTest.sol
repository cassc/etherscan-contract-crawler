// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "../domino/ITransferProxy.sol";
import "../domino/LibERC721LazyMint.sol";
import "../contracts/IERC721LazyMint.sol";
import "../domino/OperatorRole.sol";

contract ERC721LazyMintTransferProxyTest is OperatorRole, ITransferProxy {
    function transfer(LibAsset.Asset memory asset, address from, address to) override onlyOperator external {
        require(asset.value == 1, "erc721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(asset.assetType.data, (address, LibERC721LazyMint.Mint721Data));
        IERC721LazyMint(token).transferFromOrMint(data, from, to);
    }
}