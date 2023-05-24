// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  Trophy_Collection
 * @author Dadogg80 - VBS Viken Blockchain Solutions AS 
 * @notice This template contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry.
 */
abstract contract TrophyCollection is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    AccessControl,
    ERC2981
{
        using SafeERC20 for IERC20;

    bool public operatorFilteringEnabled;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    event Minted(address to, uint amount);

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyRole(ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /// @notice Removes stuck erc20 tokens from contract.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _token The contract address of the token to remove.
    /// @param _to The to account.
    function removeStuckTokens(address _token, address _to) external onlyRole(ADMIN_ROLE) {
        uint _amount = balanceOf(address(_token));
        IERC20(_token).safeTransfer(_to, _amount);
    }

}