// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

//  Developed by 0xsku, Twitter: @iamsku_

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";


contract zeroX is ERC721A, Owned, ReentrancyGuard, OperatorFilterer {

    bool public operatorFilteringEnabled;

    struct zeroXStorage {
        string name;
        string ipfs;
        string trait;
        string description;
    }

    mapping (uint256 => zeroXStorage) public tokenMetadata;

    constructor() ERC721A("zeroX", "zX") Owned(msg.sender) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function mint(string calldata _uri, string calldata _tokenName, string calldata _traitName, string calldata _description, uint256 _amount) onlyOwner external {
        uint256 tokenId = _nextTokenId();

        tokenMetadata[tokenId].name = _tokenName;
        tokenMetadata[tokenId].ipfs = _uri;
        tokenMetadata[tokenId].trait = _traitName;
        tokenMetadata[tokenId].description = _description;

        _mint(msg.sender, _amount);
    }

    function burn(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function changeImageURI(uint256 _tokenId, string calldata _newUri) external onlyOwner {
        tokenMetadata[_tokenId].ipfs = _newUri;
    }

    function changeTokenName(uint256 _tokenId, string calldata _newName) external onlyOwner {
        tokenMetadata[_tokenId].name = _newName;
    }

    function changeTraitName(uint256 _tokenId, string calldata _newTrait) external onlyOwner {
        tokenMetadata[_tokenId].trait = _newTrait;
    }

    function changeTokenDescription(uint256 _tokenId, string calldata _newDesc) external onlyOwner {
        tokenMetadata[_tokenId].description = _newDesc;
    }

    function repeatOperatorRegistration() external onlyOwner {
        _registerForOperatorFiltering();
    }

    function setOperatorFilteringEnabled(bool _value) public onlyOwner {
        operatorFilteringEnabled = _value;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked(
                    '{"name": "', tokenMetadata[tokenId].name, '",',
                    '"image": "', tokenMetadata[tokenId].ipfs, '",',
                    '"description": "', tokenMetadata[tokenId].description, '",',
                    '"attributes": [{"trait_type": "Art", "value": "', tokenMetadata[tokenId].trait, '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}