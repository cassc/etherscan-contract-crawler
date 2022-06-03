//       ___           ___           ___           ___           ___                    ___           ___           ___           ___           ___
//      /\  \         /\__\         /\  \         /\  \         /\  \                  /\__\         /\  \         /\__\         /\  \         /\__\
//     /::\  \       /::|  |       /::\  \       /::\  \       /::\  \                /:/ _/_       /::\  \       /::|  |       /::\  \       /::|  |
//    /:/\:\  \     /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\:\  \              /:/ /\__\     /:/\:\  \     /:|:|  |      /:/\:\  \     /:|:|  |
//   /:/  \:\  \   /:/|:|__|__   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \            /:/ /:/ _/_   /:/  \:\  \   /:/|:|__|__   /::\~\:\  \   /:/|:|  |__
//  /:/__/ \:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/__/_\:\__\ /:/\:\ \:\__\          /:/_/:/ /\__\ /:/__/ \:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/ |:| /\__\
//  \:\  \ /:/  / \/__/~~/:/  / \:\~\:\ \/__/ \:\  /\ \/__/ \/__\:\/:/  /          \:\/:/ /:/  / \:\  \ /:/  / \/__/~~/:/  / \:\~\:\ \/__/ \/__|:|/:/  /
//   \:\  /:/  /        /:/  /   \:\ \:\__\    \:\ \:\__\        \::/  /            \::/_/:/  /   \:\  /:/  /        /:/  /   \:\ \:\__\       |:/:/  /
//    \:\/:/  /        /:/  /     \:\ \/__/     \:\/:/  /        /:/  /              \:\/:/  /     \:\/:/  /        /:/  /     \:\ \/__/       |::/  /
//     \::/  /        /:/  /       \:\__\        \::/  /        /:/  /                \::/  /       \::/  /        /:/  /       \:\__\         /:/  /
//      \/__/         \/__/         \/__/         \/__/         \/__/                  \/__/         \/__/         \/__/         \/__/         \/__/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OMEGA_WOMEN is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 public totalSupply = 11111;
    mapping(address => uint256) public OMEGAtoOwner;

    string private baseURI;
    Counters.Counter private tokenId;

    constructor(string memory baseURI_) ERC721("OMEGA WOMEN", "OW") {
        baseURI = baseURI_;
    }

    function mint() external nonReentrant {
        require(tokenId.current() + 1 <= totalSupply, "Mint exceeds supply");
        require(OMEGAtoOwner[msg.sender] < 1, "One free NFT per wallet");
        tokenId.increment();
        _safeMint(msg.sender, tokenId.current());
        OMEGAtoOwner[msg.sender] += 1;
    }

    function getActualSupply() public view returns (uint256) {
        return tokenId.current();
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Set some OMEGA aside for team, charity, growth and giveaways
    function reserveOMEGA() public onlyOwner {
        uint256 i;
        for (i = 0; i < 25; i++) {
            if (tokenId.current() + 1 <= totalSupply) {
                tokenId.increment();
                _safeMint(owner(), tokenId.current());
            }
        }
    }

    function donate() external payable {
        // Time to build the future together. Thanks you for supporting OMEGA WOMEN Foundation in its actions and ambitions
    }

    // This allows OMEGA WOMEN Foundation to receive kind donations
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}