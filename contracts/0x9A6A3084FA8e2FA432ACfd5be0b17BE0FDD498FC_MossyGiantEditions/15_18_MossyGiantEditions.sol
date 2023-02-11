// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title MossyGiantEditions
 * MossyGiantEditions - an 1155 contract for  TheReeferRascals
 */
contract MossyGiantEditions is
    ERC1155Supply,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable
{
    using Strings for string;
    string public name;
    string public symbol;

    string public baseURI =
        "https://mother-plant.s3.amazonaws.com/mossygianteditions/metadata/";

    // Item data
    struct itemData {
        uint256 maxSupply;
    }
    mapping(uint256 => itemData) public idStats;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address payable royaltiesReceiver
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        setRoyaltyInfo(royaltiesReceiver, 750);
    }

    function createItem(uint256 _id, uint256 _maxSupply) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
    }

    function airdrop(
        address[] memory _addresses,
        uint256 _id,
        uint256[] memory _quantities
    ) external onlyOwner {
        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            totalQuantity += _quantities[i];
            _mint(_addresses[i], _id, _quantities[i], "");
        }
        require(
            totalQuantity <= idStats[_id].maxSupply,
            "Quantities airdropped exceed max supply"
        );
    }

    function withdraw() external onlyOwner {
        (bool rr, ) = payable(0xad8076DcaC7d6FA6F392d24eE225f4d715FAa363).call{
            value: address(this).balance
        }("");
        require(rr, "Transfer failed");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155: NONEXISTENT_TOKEN");
        return (
            string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"))
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // IERC2981
    function setRoyaltyInfo(
        address payable receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }
}