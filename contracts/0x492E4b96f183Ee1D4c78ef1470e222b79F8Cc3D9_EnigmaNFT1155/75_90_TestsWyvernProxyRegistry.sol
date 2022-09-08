// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IWyvernProxyRegistry.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract TestsWyvernProxy {
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    function erc721TransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Upgradeable(token).transferFrom(from, to, tokenId);
    }

    function erc1155TransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes memory data
    ) external {
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc1155BatchTransferFrom(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        IERC1155Upgradeable(token).safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

contract TestsWyvernProxyRegistry {
    /* Authenticated proxies by user. */
    mapping(address => TestsWyvernProxy) public proxies;

    function registerProxy() public returns (TestsWyvernProxy proxy) {
        require(address(proxies[msg.sender]) == address(0), "Proxy mast not me initilized already");
        proxy = new TestsWyvernProxy();
        proxies[msg.sender] = proxy;
        return proxy;
    }
}