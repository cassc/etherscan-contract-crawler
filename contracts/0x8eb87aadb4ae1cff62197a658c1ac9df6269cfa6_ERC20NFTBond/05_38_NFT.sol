// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../access/AccessManagedUpgradeable.sol";

abstract contract NFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, AccessManagedUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    CountersUpgradeable.Counter private _tokenIdCounter;
    string private _baseTokenURI;
    mapping(uint256 => bool) private _nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function __NFT_init(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseUri
    )
    internal initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        _setBaseURI(_baseUri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _safeMint(address to, string calldata uri) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function _safeMintBySig (string calldata uri, address to, bytes32 nftHash, bool setApprove, uint256 nonce, bytes memory signature) internal returns (uint256) {
        bytes32 messageHash = keccak256(abi.encode(uri, to, nftHash, address(this), setApprove, nonce, block.chainid));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        address miningSigner = ecrecover(ethSignedMessageHash, v, r, s);
        require(_hasRole(MINTER, miningSigner), "NFT::Invalid Signature");

        return _safeMint(to, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function _setBaseURI(string calldata _baseUri) private {
      _baseTokenURI = _baseUri;
    }

    function _splitSignature(bytes memory _sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "Invalid Signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
    uint256[49] private __gap;
}