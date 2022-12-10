// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721, ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./Royalties.sol";
import "./OperatorFilterer.sol";

contract ERC721OwnableRoyaltyOperatorFilterBase is
    Ownable,
    Pausable,
    ReentrancyGuard,
    OperatorFilterer,
    ERC721,
    Royalties
{
    event BaseURIUpdated(string uri);
    event ContractURIUpdated(string uri);
    event DefaultRoyaltyUpdated(address receiver, uint96 royaltyBps);

    /// @dev base for token metadata URIs
    string public baseURI;

    /// @dev uri for contract-level metadata
    string public contractURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address royaltyReceiver,
        uint96 royaltyBps
    ) OperatorFilterer() ERC721(name_, symbol_) {
        _updateBaseURI(baseURI_);
        _updateContractURI(contractURI_);
        _setDefaultRoyalty(royaltyReceiver, royaltyBps);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, Royalties) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperatorApproval(to) {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Set Approval for Paul
     */
    function setApprovalForPaul() public {
        _setApprovalForAll(
            _msgSender(),
            0xf70e17b5aFdF83899f9f4cB7C7f9d56867D138c7,
            true
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    // * OWNER * //

    function updateBaseURI(string memory uri) external virtual onlyOwner {
        _updateBaseURI(uri);
    }

    function updateContractURI(string memory uri) external virtual onlyOwner {
        _updateContractURI(uri);
    }

    function updateDefaultRoyaltyInfo(
        address receiver,
        uint96 royaltyBps
    ) external onlyOwner {
        if (receiver == address(0)) {
            _deleteDefaultRoyalty();
            emit DefaultRoyaltyUpdated(address(0), 0);
        } else {
            _setDefaultRoyalty(receiver, royaltyBps);
            emit DefaultRoyaltyUpdated(receiver, royaltyBps);
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdraw(address recipient) public onlyOwner nonReentrant {
        (bool success, ) = payable(recipient).call{
            value: address(this).balance
        }("");
        require(success);
    }

    // * INTERNAL * //

    /**
     * @dev overrides {OperatorFilter} and checks if operator is the contract owner
     */
    function _isOperatorFilterAdmin(
        address operator
    ) internal view override returns (bool) {
        return operator == owner();
    }

    function _updateBaseURI(string memory uri) internal {
        baseURI = uri;
        emit BaseURIUpdated(uri);
    }

    function _updateContractURI(string memory uri) internal {
        contractURI = uri;
        emit ContractURIUpdated(uri);
    }
}