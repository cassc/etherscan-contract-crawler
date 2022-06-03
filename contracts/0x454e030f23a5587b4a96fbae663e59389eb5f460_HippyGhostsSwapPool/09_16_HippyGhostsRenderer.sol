// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HippyGhostsRenderer is Ownable {
    using Strings for uint256;

    bytes32 constant public MERKLE_ROOT = 0x58d247a687ef48f010e2e6107a04d575787163cfb0d70543c421a5001e9f5aab;
    address public immutable hippyGhosts;
    string public baseURI;

    constructor(
        address hippyGhosts_,
        string memory baseURI_
    ) {
        hippyGhosts = hippyGhosts_;
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

}