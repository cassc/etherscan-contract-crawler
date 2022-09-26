// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interface/IERC2981.sol";
import "./EverlensAccessControl.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract EverlensERC721 is
    Initializable,
    EverlensAccessControl,
    ERC721URIStorageUpgradeable,
    ERC2981PerTokenRoyalties
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private newBaseURI;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _newBaseURI,
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __EverlensAccessControl_init(_whitelistAddresses);
        __ERC721URIStorage_init();
        newBaseURI = _newBaseURI;
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return newBaseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function createNFT(string memory _currTokenURI, uint256 royaltyValue)
        public
        returns (uint256)
    {
        require(bytes(_currTokenURI).length != 0, "Token URI cannot be empty");
        _tokenIds.increment();
        _mint(_msgSender(), _tokenIds.current());
        _setTokenURI(_tokenIds.current(), _currTokenURI);
        _setTokenRoyalty(_tokenIds.current(), _msgSender(), royaltyValue);
        return _tokenIds.current();
    }
}