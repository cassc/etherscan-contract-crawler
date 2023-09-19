// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

import {Lockable} from "./../libraries/Lockable.sol";
import {ProtectedMintBurn} from "./../libraries/ProtectedMintBurn.sol";
import {IMetadataResolver} from "./../interfaces/IMetadataResolver.sol";
import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";

// @author: NFT Studios - Buildtree

contract Base721 is ERC721, ERC2981, Ownable, Lockable, ProtectedMintBurn, DefaultOperatorFilterer, IERC721Mintable {
    IMetadataResolver public metadataResolver;
    uint256 public totalSupply;

    constructor(
        uint96 _royalty,
        address _royaltyRecipient,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _setDefaultRoyalty(_royaltyRecipient, _royalty);
    }

    // Only Minter
    function mint(address _to, uint256[] memory _ids) external onlyMinter mintIsNotLocked {
        for (uint i; i < _ids.length; i++) {
            _safeMint(_to, _ids[i]);
        }

        totalSupply += _ids.length;
    }

    // Only Burner
    function burn(uint256[] memory _ids) external onlyBurner burnIsNotLocked {
        for (uint i; i < _ids.length; i++) {
            _burn(_ids[i]);
        }

        totalSupply -= _ids.length;
    }

    // Only owner
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function setMetadataResolver(address _metadataResolverAddress) external onlyOwner metadataIsNotLocked {
        metadataResolver = IMetadataResolver(_metadataResolverAddress);
    }

    // Public
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        return metadataResolver.getTokenURI(_tokenId);
    }

    // OpenSea Operator Filter
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(address _operator, uint256 _tokenId) public override onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}