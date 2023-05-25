// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Super1155 is ERC1155, ERC2981, DefaultOperatorFilterer, Ownable {
    address public minter;
    uint256 public totalSupply;
    string public constant name = "POINTS";
    string public constant symbol = "PNT";

    constructor(string memory _uri) ERC1155(_uri) {}

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setURI(string memory _uri) external onlyOwner {
        super._setURI(_uri);
    }

    function setTokenRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        super._setTokenRoyalty(0, receiver, feeNumerator);
    }

    function mint(address recipient, uint256 amount) external {
        require(msg.sender == minter, "Unauthorized!");
        super._mint(recipient, 0, amount, "");
        totalSupply += amount;
    }

    function burn(uint256 amount) external {
        super._burn(msg.sender, 0, amount);
        totalSupply -= amount;
    }

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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}