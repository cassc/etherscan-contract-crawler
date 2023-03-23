// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SymbNFT is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256 public MAX_SUPPLY;
    string public PROVENANCE_HASH;
    string public baseURI;

    function initialize(
        uint256 _maxSupply,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        MAX_SUPPLY = _maxSupply;
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    function claimReserved(address _receiver) external onlyOwner virtual {
        uint256 _tokenId = totalSupply();
        _safeMint(_receiver, _tokenId);
    }
}