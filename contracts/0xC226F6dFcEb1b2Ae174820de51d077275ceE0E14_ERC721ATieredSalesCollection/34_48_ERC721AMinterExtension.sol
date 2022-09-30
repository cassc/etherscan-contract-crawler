// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "erc721a/contracts/ERC721A.sol";

import {IERC721AutoIdMinterExtension} from "../../ERC721/extensions/ERC721AutoIdMinterExtension.sol";

import "./ERC721ACollectionMetadataExtension.sol";

/**
 * @dev Extension to add minting capability with an auto incremented ID for each token and a maximum supply setting.
 */
abstract contract ERC721AMinterExtension is ERC721ACollectionMetadataExtension {
    using SafeMath for uint256;

    uint256 public maxSupply;
    bool public maxSupplyFrozen;

    function __ERC721AMinterExtension_init(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        __ERC721AMinterExtension_init_unchained(_maxSupply);
    }

    function __ERC721AMinterExtension_init_unchained(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        maxSupply = _maxSupply;

        _registerInterface(type(IERC721AutoIdMinterExtension).interfaceId);
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721A).interfaceId);
    }

    /* ADMIN */

    function setMaxSupply(uint256 newValue) public virtual onlyOwner {
        require(!maxSupplyFrozen, "BASE_URI_FROZEN");
        require(newValue >= totalSupply(), "LOWER_THAN_SUPPLY");
        maxSupply = newValue;
    }

    function freezeMaxSupply() external onlyOwner {
        maxSupplyFrozen = true;
    }

    /* INTERNAL */

    function _mintTo(address to, uint256 count) internal {
        require(totalSupply() + count <= maxSupply, "EXCEEDS_SUPPLY");
        _safeMint(to, count);
    }
}