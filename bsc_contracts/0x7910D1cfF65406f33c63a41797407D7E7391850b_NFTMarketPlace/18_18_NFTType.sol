// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
interface INFTType {
    function isERC1155(address nftAddress) external returns (bool);
    function isERC721(address nftAddress) external returns (bool);
}
contract NFTType is INFTType, IERC165 {
    using ERC165Checker for address;
    bytes4 public constant IID_ITEST = type(INFTType).interfaceId;
    bytes4 public constant IID_IERC165 = type(INFTType).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    
    function isERC1155(address nftAddress) public view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }    
    
    function isERC721(address nftAddress) public view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == IID_ITEST || interfaceId == IID_IERC165;
    }
}