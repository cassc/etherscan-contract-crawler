// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { DefaultOperatorFilterer } from "./DefaultOperatorFilterer.sol";

contract ForgetMeNots is ERC721, ERC2981, Ownable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) public tokenImages;
    mapping(uint256 => string) public tokenNames;
    mapping(uint256 => string) public tokenDescriptions;

    constructor() ERC721("Forget Me Nots", "FMN") {
        setOwner(0xA8f7205CF1310d84DA2D3698854dE154d7dfdeC7);
    }

    function safeMint(
        string calldata tokenName,
        string calldata tokenDescription,
        string calldata rawImage
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        tokenImages[tokenId] = rawImage;
        tokenNames[tokenId] = tokenName;
        tokenDescriptions[tokenId] = tokenDescription;
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenNames[tokenId],
                        '", ',
                        '"description": "',
                        tokenDescriptions[tokenId],
                        '", ',
                        '"image": "data:image/png;base64,',
                        tokenImages[tokenId],
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setOwner(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function updateName(uint256 tokenId, string calldata name) public onlyOwner {
        tokenNames[tokenId] = name;
    }

    function updateDescription(uint256 tokenId, string calldata desc) public onlyOwner {
        tokenDescriptions[tokenId] = desc;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}