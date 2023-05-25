// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RVMC is
    ERC1155,
    ERC1155Supply,
    ERC1155Burnable,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable,
    Pausable
{
    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    constructor(string memory baseUri) ERC1155(baseUri) {
        _pause();
    }

    /// @notice Mints tokens
    /// @param recipients The addresses to receive the tokens
    /// @param amounts The amounts of tokens to mint
    /// @param tokenId The ID of the tokens to mint
    function mintBatch(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 tokenId
    ) public onlyOwner {
        require(
            recipients.length == amounts.length,
            "Mismatched recipients and amounts"
        );

        unchecked {
            for (uint256 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], tokenId, amounts[i], "");
            }
        }
    }

    /// @notice Pauses the ability transfer tokens
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause (resume) the ability transfer tokens
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets the base URI for the token's metadata
    /// @param baseURI The new base URI
    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    /// @notice Sets the name and symbol for the token's metadata
    /// @param newName The new base URI
    /// @param newSymbol The new base URI
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external onlyOwner {
        name = newName;
        symbol = newSymbol;
    }

    /// @notice Sets the default royalty for the token
    /// @param receiver The receiver of the royalty fees
    /// @param feeNumerator The value of the royalty fees
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
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
    ) public override whenNotPaused onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotPaused onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override whenNotPaused {
        super.burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override whenNotPaused {
        super.burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}