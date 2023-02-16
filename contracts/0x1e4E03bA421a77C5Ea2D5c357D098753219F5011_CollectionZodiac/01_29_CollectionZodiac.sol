// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract CollectionZodiac is ERC721, Ownable, ERC721Burnable {
    struct AirdropRecipient {
        address recipient;
        uint256 tokenId;
    }

    string standardURI;
    /// @dev 36 prizes with 7 ties
    uint256 constant totalSupply = 43;

    constructor(string memory _name, string memory _symbol, string memory _standardURI) ERC721(_name, _symbol) {
        standardURI = _standardURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        standardURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return standardURI;
    }

    function airdrop(AirdropRecipient[] calldata airdropRecipients) external onlyOwner {
        uint256 length = airdropRecipients.length;
        for (uint256 i; i < length;) {
            _safeMint(airdropRecipients[i].recipient, airdropRecipients[i].tokenId);

            unchecked {
                ++i;
            }
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override (ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}