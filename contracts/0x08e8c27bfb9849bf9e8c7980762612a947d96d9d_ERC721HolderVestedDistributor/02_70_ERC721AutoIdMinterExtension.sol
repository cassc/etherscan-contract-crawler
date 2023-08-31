// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

interface ERC721AutoIdMinterExtensionInterface {
    function setMaxSupply(uint256 newValue) external;

    function freezeMaxSupply() external;

    function totalSupply() external view returns (uint256);
}

/**
 * @dev Extension to add minting capability with an auto incremented ID for each token and a maximum supply setting.
 */
abstract contract ERC721AutoIdMinterExtension is
    Ownable,
    ERC165Storage,
    ERC721,
    ERC721AutoIdMinterExtensionInterface
{
    using SafeMath for uint256;

    uint256 public maxSupply;

    bool internal _maxSupplyFrozen;
    uint256 internal _currentTokenId = 0;

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;

        _registerInterface(
            type(ERC721AutoIdMinterExtensionInterface).interfaceId
        );
        _registerInterface(type(IERC721).interfaceId);
    }

    // ADMIN

    function setMaxSupply(uint256 newValue) external onlyOwner {
        require(!_maxSupplyFrozen, "BASE_URI_FROZEN");
        maxSupply = newValue;
    }

    function freezeMaxSupply() external onlyOwner {
        _maxSupplyFrozen = true;
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    // INTERNAL

    function _mintTo(address to, uint256 count) internal {
        require(totalSupply() + count <= maxSupply, "EXCEEDS_MAX_SUPPLY");

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(to, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * Calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() internal view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        _currentTokenId++;
    }
}