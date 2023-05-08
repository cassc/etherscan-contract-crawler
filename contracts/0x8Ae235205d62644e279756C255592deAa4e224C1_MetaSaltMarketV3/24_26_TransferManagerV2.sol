// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";
import "../common/lib/LibERC721LazyMint.sol";
import "../common/lib/LibERC1155LazyMint.sol";
import "../common/interfaces/IERC721LazyMint.sol";
import "./interfaces/IRoyaltyEngine.sol";
import "../common/interfaces/IERC1155LazyMint.sol";
import "../common/lib/LibAsset.sol";

contract TransferManagerV2 is Initializable, OwnableUpgradeable {    
    using SafeMathUpgradeable for uint;

    uint public protocolFee;    
    address public defaultFeeReceiver;            
    mapping (bytes4 => address) proxies;    
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;        

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

    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165Upgradeable(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function setRoyaltyRegister(address _newRoyaltyRegister) external onlyOwner{
        royaltyRegister = _newRoyaltyRegister;
    }

    function setTransferProxy(address transferERC721Proxy, address transferERC1155Proxy) external onlyOwner{
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
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, asset.value, "");
    }

    function getRoyaltyInfoERC721(LibAsset.Asset memory asset, uint256 price) internal view returns (address payable[] memory creators, uint256[] memory royaltyFees) {
        require(asset.value == 1, "erc721 value error");
        (address token, uint256 tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        (creators, royaltyFees) = IRoyaltyEngine(royaltyRegister).getRoyaltyView(token, tokenId, price);        
        return (creators, royaltyFees);
    }

    function getRoyaltyInfoERC721Lazy(LibAsset.Asset memory asset, uint256 price) internal view returns (address payable[] memory creators, uint256[] memory royaltyFees) {
        require(asset.value == 1, "erc721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(asset.assetType.data, (address, LibERC721LazyMint.Mint721Data));
        (creators, royaltyFees) = IRoyaltyEngine(royaltyRegister).getRoyaltyView(token, data.tokenId, price);    
        return (creators, royaltyFees);
    }

    function getRoyaltyInfoERC1155(LibAsset.Asset memory asset, uint256 price) internal view returns (address payable[] memory creators, uint256[] memory royaltyFees) {
        (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        (creators, royaltyFees) = IRoyaltyEngine(royaltyRegister).getRoyaltyView(token, tokenId, price);       
        return (creators, royaltyFees);
    }

    function getRoyaltyInfoERC1155Lazy(LibAsset.Asset memory asset, uint256 price) internal view returns (address payable[] memory creators, uint256[] memory royaltyFees) {
        (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(asset.assetType.data, (address, LibERC1155LazyMint.Mint1155Data));
        (creators, royaltyFees) = IRoyaltyEngine(royaltyRegister).getRoyaltyView(token, data.tokenId, price);    
        return (creators, royaltyFees);
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
    address public royaltyRegister;        
    uint256[45] private __gap;
}