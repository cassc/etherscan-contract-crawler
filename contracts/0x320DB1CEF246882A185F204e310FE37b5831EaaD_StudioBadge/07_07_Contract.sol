// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@erc721a/contracts/ERC721A.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

contract StudioBadge is ERC721A, Ownable {
    using ECDSA for bytes32;

    // @dev Using errors instead of requires with strings saves gas at deploy time
    error MaxSupplyReached();

    uint256 MAX_SUPPLY = 247;

    string public baseUri;

    constructor(string memory baseURI) ERC721A("247StudioBadge", "247Badge") {
        baseUri = baseURI;
    }

    // Owner functionality ------------------------------------------------------------------------
    function setBaseURI(string memory newUri) external onlyOwner {
        baseUri = newUri;
    }

    // Mint functionality ------------------------------------------------------------------------

    function mintToAddrs(address[] calldata addresses) external onlyOwner {
        if (_totalMinted() + addresses.length > MAX_SUPPLY)
            revert MaxSupplyReached();
        // Max supply is 247 so uint8 will never overflow
        for (uint8 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}