// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux/
// @url:    https://ragerscity.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interface/IRagersCityMetadata.sol";
import "./extensions/UnrevealedURI.sol";

contract RagersCityMetadata is IRagersCityMetadata, UnrevealedURI, Ownable {
    using Strings for uint256;

    // ======== URI =========
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    // ======== Lock =========
    bool public locked = false;

    // ======== Events =========
    event UriPrefixUpdated(string _uriPrefix);
    event UriSuffixUpdated(string _uriSuffix);
    event Locked();

    // ======== Constructor =========
    constructor(string memory _unrevealedMetadata) {
        uriPrefix = _unrevealedMetadata;
    }

    modifier isUnlocked() {
        require(!locked, "Contract is locked!");
        _;
    }

    function lock() public override onlyOwner isUnlocked {
        locked = true;
        emit Locked();
    }

    function setUriPrefix(string calldata _uriPrefix) public onlyOwner isUnlocked {
        uriPrefix = _uriPrefix;
        emit UriPrefixUpdated(_uriPrefix);
    }

    function setEncryptedPrefix(bytes calldata _encryptedPrefix) external onlyOwner isUnlocked {
        _setEncryptedURI(_encryptedPrefix);
    }

    function setUriSuffix(string calldata _uriSuffix) external onlyOwner isUnlocked {
        uriSuffix = _uriSuffix;
        emit UriSuffixUpdated(_uriSuffix);
    }

    function reveal(bytes calldata _key)
        external
        onlyOwner
        override
        isUnlocked
        returns (string memory revealedURI)
    {
        // bytes memory key = bytes(_key);
        revealedURI = getRevealURI(_key);

        _setEncryptedURI("");
        uriPrefix = revealedURI;

        emit TokenURIRevealed(revealedURI);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory uri = _baseURI();

        if (isEncryptedURI()) {
            return uri;
        } else {
            return 
                bytes(uri).length > 0 ?
                    string(
                        abi.encodePacked(
                            uri, 
                            _tokenId.toString(), 
                            uriSuffix
                        )
                )
                : uri;
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    // ======== Withdraw =========
    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}