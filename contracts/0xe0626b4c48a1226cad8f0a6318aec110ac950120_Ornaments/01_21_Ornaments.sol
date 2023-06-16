// SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Ornaments is
    ERC1155,
    ERC1155Burnable,
    ERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    mapping(uint256 => uint256) public prices;
    string private baseURI;

    constructor() ERC1155("") {
        _setDefaultRoyalty(_msgSender(), 500);
    }

    function setBaseURI(
        string memory _newBaseURI
    ) public nonReentrant onlyOwner {
        baseURI = _newBaseURI;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"));
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public payable nonReentrant whenNotPaused {
        require(prices[id] != 0, "Price is not set.");
        require(
            msg.value == prices[id] * amount,
            "The value sent is incorrect."
        );
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public payable nonReentrant whenNotPaused {
        require(ids.length == amounts.length, "Mismatch arrays length.");
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(prices[ids[i]] != 0, "Price is not set.");
            totalPrice += prices[ids[i]] * amounts[i];
        }
        require(msg.value == totalPrice, "The value sent is incorrect.");
        _mintBatch(to, ids, amounts, "");
    }

    function mintOwner(
        address to,
        uint256 id,
        uint256 amount
    ) public nonReentrant onlyOwner {
        _mint(to, id, amount, "");
    }

    function mintBatchOwner(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public nonReentrant onlyOwner {
        require(ids.length == amounts.length, "Mismatch arrays length.");
        _mintBatch(to, ids, amounts, "");
    }

    function mintCustomBatchOwner(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public nonReentrant onlyOwner {
        require(
            tos.length == ids.length && ids.length == amounts.length,
            "Mismatch arrays length."
        );
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], ids[i], amounts[i], "");
        }
    }

    function setPrice(uint256 id, uint256 _price) public onlyOwner {
        prices[id] = _price;
    }

    function setPriceBatch(
        uint256[] memory ids,
        uint256[] memory _prices
    ) public onlyOwner {
        require(ids.length == _prices.length, "Mismatch arrays length.");
        for (uint i = 0; i < ids.length; i++) {
            prices[ids[i]] = _prices[i];
        }
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // operator-filter-registry
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // ERC2981
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}