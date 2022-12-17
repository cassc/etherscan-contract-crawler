// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "./interfaces/IHashExNFTCertificates.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HashExNFTCertificates is
    ERC721Burnable,
    Ownable,
    IHashExNFTCertificates
{
    string private _baseURIStored;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner_,
        MintParams[] memory idsToMint_
    ) ERC721(name_, symbol_) {
        for (uint256 i; i < idsToMint_.length; i++) {
            _mint(idsToMint_[i].to, idsToMint_[i].id);
        }
        _setBaseURI(baseURI_);
        if (owner_ != address(0)) _transferOwnership(owner_);
    }

    function mint(address _to, uint256 _tokenId) external onlyOwner {
        _mint(_to, _tokenId);
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        _setBaseURI(_newURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIStored;
    }

    function _setBaseURI(string memory _newURI) internal {
        string memory oldURI = _baseURIStored;
        _baseURIStored = _newURI;
        emit BaseURIChanged(oldURI, _newURI);
    }
}