pragma solidity ^0.8.2;

interface IAdapter {

    function getByteCodeERC20(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

    function getByteCodeERC721(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

    function getByteCodeERC1155(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

}