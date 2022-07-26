// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./lib/LibERC721LazyMint.sol";
import "./lib/LibERC1155LazyMint.sol";
import "./interfaces/IERC721LazyMint.sol";
import "./interfaces/IERC1155LazyMint.sol";
import "./lib/LibAsset.sol";

abstract contract TransferManager is Initializable, OwnableUpgradeable {    
    using SafeMathUpgradeable for uint;

    uint public protocolFee;    
    address public defaultFeeReceiver;    
    mapping (bytes4 => address) proxies;

    function __TransferManager_init_unchained(        
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        address transferERC721Proxy,
        address transferERC1155Proxy        
    ) internal initializer {
        proxies[LibAsset.ERC721_ASSET_CLASS] = transferERC721Proxy;
        proxies[LibAsset.ERC1155_ASSET_CLASS] = transferERC1155Proxy;
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;        
    }

    function setTransferProxy(address transferERC721Proxy, address transferERC1155Proxy) public onlyOwner{
        proxies[LibAsset.ERC721_ASSET_CLASS] = transferERC721Proxy;
        proxies[LibAsset.ERC1155_ASSET_CLASS] = transferERC1155Proxy;
    }

    function setProtocolFee(uint newProtocolFee) external onlyOwner {
        protocolFee = newProtocolFee;
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver) external onlyOwner {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function getFeeReceiver() internal view returns (address) {
        return defaultFeeReceiver;
    }

    function transferERC721(LibAsset.Asset memory asset, address from, address to) internal {     
        (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        require(asset.value == 1, "erc721 value error");   
        IERC721Upgradeable(token).transferFrom(from, to, tokenId);
    }

    function transferERC1155(LibAsset.Asset memory asset, address from, address to) internal {     
        (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        require(asset.value == 1, "erc1155 value error");   
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, 1, "");
    }

    function getRoyaltyInfoERC721(LibAsset.Asset memory asset) internal returns (address, uint) {
        require(asset.value == 1, "erc721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(asset.assetType.data, (address, LibERC721LazyMint.Mint721Data));
        address creator = IERC721LazyMint(token).getCreator(data.tokenId);
        uint royaltyFee = IERC721LazyMint(token).getRoyaltyFee(data.tokenId);
        return (creator, royaltyFee);
    }

    function getRoyaltyInfoERC1155(LibAsset.Asset memory asset) internal returns (address, uint) {        
        (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(asset.assetType.data, (address, LibERC1155LazyMint.Mint1155Data));
        address creator = IERC1155LazyMint(token).getCreator(data.tokenId);
        uint royaltyFee = IERC1155LazyMint(token).getRoyaltyFee(data.tokenId);
        return (creator, royaltyFee);
    }

    function transferERC721LazyMint(LibAsset.Asset memory asset, address from, address to) internal {
        require(asset.value == 1, "erc721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(asset.assetType.data, (address, LibERC721LazyMint.Mint721Data));
        IERC721LazyMint(token).transferFromOrMint(data, from, to);
    }

    function transferERC1155LazyMint(LibAsset.Asset memory asset, address from, address to) internal {        
        (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(asset.assetType.data, (address, LibERC1155LazyMint.Mint1155Data));
        IERC1155LazyMint(token).transferFromOrMint(data, from, to, asset.value);
    }

    uint256[46] private __gap;
}