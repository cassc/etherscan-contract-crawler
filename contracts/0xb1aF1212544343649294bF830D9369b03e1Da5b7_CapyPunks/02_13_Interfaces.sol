//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface OnChainMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ProxyQuery {
    function query(address _addr) external view returns (uint160);
}

interface OSI {
    function proxies(address _address) external view returns (address);
}