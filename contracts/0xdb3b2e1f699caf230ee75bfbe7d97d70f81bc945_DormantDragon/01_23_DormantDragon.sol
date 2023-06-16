//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./BaseERC721.sol";
import "./Whitelisted.sol";

contract DormantDragon is BaseERC721, Whitelisted {
    constructor(bytes32 _root, uint256 _total, uint256 _max, string memory _uri, address _teamWallet)
    BaseERC721(
        _total,
        _max,
        0.08 ether,
        _uri,
        _teamWallet,
        "DormantDragon",
        "DD"     
    )
    Whitelisted(
        _root
    )
    {}

    function whitelistMint(uint count, uint256 tokenId, bytes32[] calldata proof) external payable nonReentrant {
        require(isWhitelistActive, "Not live");
        require(_verify(_leaf(msg.sender, tokenId), proof), "Invalid");        
        require(whitelistCount[msg.sender] + count <= max, "max mints");
        _callMint(count);
        whitelistCount[msg.sender] += count;
    }
}