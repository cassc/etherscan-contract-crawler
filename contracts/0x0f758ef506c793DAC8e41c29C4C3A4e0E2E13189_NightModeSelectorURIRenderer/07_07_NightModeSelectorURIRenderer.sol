// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IRebelsRenderer.sol";


contract NightModeSelectorURIRenderer is IRebelsRenderer, ERC165 {
    string public baseURI;
    IERC721 public rebelsNFT;

    // Mapping to store night mode status for each token
    mapping(uint256 => bool) private nightModeEnabled;

    constructor(string memory baseURI_, address nftAddress) {
        require(nftAddress != address(0), "NFT address cannot be the zero address");
        baseURI = baseURI_;
        rebelsNFT = IERC721(nftAddress);
    }

    event NightModeUpdated(uint256 indexed tokenId, bool enabled);

    function tokenURI(uint256 id) external view override returns (string memory) {
        string memory idStr = Strings.toString(id);
        string memory suffix = nightModeEnabled[id] ? "-night.json" : ".json";
        return string(abi.encodePacked(baseURI, idStr, suffix));
    }

    function beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) external pure override {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRebelsRenderer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Function for token owners to enable or disable night mode
    function setNightMode(uint256 id, bool enable) external {
        require(rebelsNFT.ownerOf(id) == msg.sender, "Not token owner");
        nightModeEnabled[id] = enable;
        emit NightModeUpdated(id, enable);
    }

    // Function to check night mode status for a specific token
    function getNightMode(uint256 id) external view returns (bool) {
        return nightModeEnabled[id];
    }
}