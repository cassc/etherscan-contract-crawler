// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./../libraries/Lockable.sol";
import "./../libraries/ProtectedMintBurn.sol";
import "./../interfaces/IMetadataResolver.sol";

// @author: NFT Studios

contract Base1155 is
    ERC1155,
    ERC2981,
    Ownable,
    Lockable,
    ProtectedMintBurn,
    DefaultOperatorFilterer
{
    IMetadataResolver public metadataResolver;

    string public name;

    string public symbol;

    constructor(
        uint96 _royalty,
        string memory _name,
        string memory _symbol
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(owner(), _royalty);
    }

    // Only Minter
    function mint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyMinter mintIsNotLocked {
        _mintBatch(_to, _ids, _amounts, "");
    }

    // Only Burner
    function burn(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyBurner burnIsNotLocked {
        _burnBatch(_from, _ids, _amounts);
    }

    // Only owner
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function setMetadataResolver(
        address _metadataResolverAddress
    ) external onlyOwner metadataIsNotLocked {
        metadataResolver = IMetadataResolver(_metadataResolverAddress);
    }

    // Public
    function uri(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return metadataResolver.getTokenURI(_tokenId);
    }

    // OpenSea Operator Filter
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override onlyAllowedOperator(_from) {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}