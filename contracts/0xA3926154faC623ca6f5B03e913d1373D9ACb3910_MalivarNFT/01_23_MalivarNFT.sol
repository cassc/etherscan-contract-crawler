// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


struct OwnedToken {
    address owner;
    uint256 id;
    string uri;
}

contract MalivarNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIds;
    address signerAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _signerAddress) initializer {
        signerAddress = _signerAddress;
        _tokenIds.increment();
    }

    function initialize() initializer public {
        __ERC721_init("MalivarNFT", "MalivarNFT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function _verify(bytes memory data, bytes memory signature, address account) internal pure returns (bool) {
        return data.toEthSignedMessageHash()
            .recover(signature) == account;
    }

    function changeSigner(address newSigner) public onlyOwner {
        signerAddress = newSigner;
    }

    function nextId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mintNFT(address recipient, string memory tokenMintingURI, bytes memory signature)
        public
        returns (uint256)
    {
        require(_verify(abi.encodePacked(tokenMintingURI), signature, signerAddress) == true, "Your signature is invalid for this tokenURI");
        
        uint256 tokenId = _tokenIds.current();

        _tokenIds.increment();
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, tokenMintingURI);

        return tokenId;
    }

    function ownedTokens(address owner) public view returns (OwnedToken[] memory) {
        uint256 balance = balanceOf(owner);
        OwnedToken[] memory tokens = new OwnedToken[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            tokens[i] = OwnedToken(owner, tokenId, tokenURI(tokenId));
        }

        return tokens;
    }

     // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
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
}