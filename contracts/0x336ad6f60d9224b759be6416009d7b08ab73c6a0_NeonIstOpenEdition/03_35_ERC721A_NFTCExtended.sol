// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ERC721A from Chiru Labs
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

// ClosedSea by Vectorized
import 'closedsea/src/OperatorFilterer.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title  ERC721A_NFTCExtended
 * @author @NFTCulture
 * @dev ERC721A plus NFTC-preferred extensions and add-ons.
 *
 * Using implementation and approach created by Vectorized for OperatorFilterer.
 * See: https://github.com/Vectorized/closedsea/blob/main/src/example/ExampleERC721A.sol
 *
 * @notice Be sure to add the following to your impl constructor:
 * >>  _registerForOperatorFiltering();
 * >>  operatorFilteringEnabled = true;
 */
abstract contract ERC721A_NFTCExtended is
    ERC721ABurnable,
    ERC721AQueryable,
    OperatorFilterer,
    Ownable
{
    bool public operatorFilteringEnabled;

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Failsafe in case we need to turn operator filtering off.
     */
    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * Failsafe in case we need to change what subscription we are using, for whatever reason.
     */
    function registerForOperatorFiltering(address subscription, bool subscribe) external onlyOwner {
        _registerForOperatorFiltering(subscription, subscribe);
    }

    /**
     * Can be called after manually invoking 'unregister' on the registry using this contract's
     * address and the contract owner's wallet to execute the transaction.
     *
     * If called repeatedly, will do nothing.
     */
    function repeatRegistration() external {
        _registerForOperatorFiltering();
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }
}