// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../../interface/IERC2981.sol";
import "../ERC2981PerTokenRoyalties.sol";
import "./LazyMintERC721.sol";

contract GenericERC721 is
    Initializable,
    LazyNFTERC721,
    ERC2981PerTokenRoyalties
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private newBaseURI;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory signDomain,
        string memory signVersion,
        address payable minter,
        string memory _newBaseURI,
        address[] memory _whitelistAddresses
    ) public initializer {
        __LazyMintERC721_init(
            _name,
            _symbol,
            signDomain,
            signVersion,
            minter,
            _whitelistAddresses
        );
        newBaseURI = _newBaseURI;
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(LazyNFTERC721, ERC2981PerTokenRoyalties)
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

    function redeem(
        address redeemer,
        uint256 minPrice,
        string calldata uri,
        uint256 _royalty,
        bytes calldata signature
    ) public payable returns (uint256) {
        NFTVoucher memory voucher = NFTVoucher({
            minPrice: minPrice,
            uri: uri,
            royalty: _royalty,
            signature: signature
        });
        _tokenIds.increment();
        uint256 royalty = redeem(redeemer, voucher, _tokenIds.current());
        _setTokenRoyalty(_tokenIds.current(), _msgSender(), royalty);
        return _tokenIds.current();
    }
}