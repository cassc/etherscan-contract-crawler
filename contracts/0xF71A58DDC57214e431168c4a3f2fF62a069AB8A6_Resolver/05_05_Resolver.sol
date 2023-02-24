// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Deployments:
// Ethereum: 0xF71A58DDC57214e431168c4a3f2fF62a069AB8A6
// Goerli: 0x2167A15c97fE3A28c0eebfA23a3368974A2b64E5

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Resolver is Ownable {
    mapping(uint256 => string) map;
    string fallbackUrl = "https://protocol.beb.xyz/graphql";
    IERC721 bebContract = IERC721(0x0F08FC2A63F4BfcDDfDa5c38e9896220d5468a64);

    function set(uint256 tokenId, string memory _value) external {
        require(bebContract.ownerOf(tokenId) == msg.sender, "only owner of tokenId can set");
        map[tokenId] = _value;
    }

    function get(uint256 tokenId) external view returns (string memory) {
        if (bytes(map[tokenId]).length == 0) {
            return fallbackUrl;
        }
        return map[tokenId];
    }

    function setFallbackUrl(string memory _fallbackUrl) external {
        require(msg.sender == owner(), "only owner can set fallback url");
        fallbackUrl = _fallbackUrl;
    }

    function setBebContract(address _bebContract) external {
        require(msg.sender == owner(), "only owner can set beb contract");
        bebContract = IERC721(_bebContract);
    }

    function getFallbackUrl() external view returns (string memory) {
        return fallbackUrl;
    }

    function getBebContract() external view returns (address) {
        return address(bebContract);
    }
}