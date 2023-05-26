// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/interfaces/IERC2981.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";

contract ArcadeAsset is IERC2981, ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply {
    string public name;
    string public symbol;
    address internal _royaltyRecipient;
    uint16 internal _royaltyFee; // out of 10000

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC1155("https://test/{id}.json") {
        name = "Arcade Land Builder Assets";
        symbol = "ARCADEBUILD";
        _royaltyRecipient = _msgSender();
        _royaltyFee = 500; // 5%

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    // in case someone sends ETH to this contract
    function withdraw(address payable _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Call returns a boolean value indicating success or failure.
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /** @dev EIP2981 royalties implementation. */

    function setRoyaltyRecipient(address royaltyRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(royaltyRecipient != address(0), "Invalid royalty recipient address");
        _royaltyRecipient = royaltyRecipient;
    }

    function setRoyaltyFee(uint16 royaltyFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(royaltyFee <= 10000, "Invalid royalty fee");
        _royaltyFee = royaltyFee;
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_royaltyRecipient, (_salePrice * _royaltyFee) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }
}