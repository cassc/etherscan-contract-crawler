// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { LibBitmap} from "solady/src/utils/LibBitmap.sol";

import "./IRebelsRenderer.sol";


contract OptimizedNightModeSelectorURIRenderer is IRebelsRenderer, ERC165 {
    using LibBitmap for LibBitmap.Bitmap;

    string public baseURI;
    IERC721 public rebelsNFT;

    // Bit mapping to store night mode status for each token
    LibBitmap.Bitmap nightModeEnabled;

    constructor(string memory baseURI_, address nftAddress) {
        require(nftAddress != address(0), "NFT address cannot be the zero address");
        baseURI = baseURI_;
        rebelsNFT = IERC721(nftAddress);
    }

    function tokenURI(uint256 id) external view override returns (string memory) {
        string memory idStr = Strings.toString(id);
        string memory suffix = getNightMode(id) ? "-night.json" : ".json";
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
        nightModeEnabled.setTo(id, enable);
    }

    // Function to check night mode status for a specific token
    function getNightMode(uint256 id) public view returns (bool) {
        return nightModeEnabled.get(id);
    }
}