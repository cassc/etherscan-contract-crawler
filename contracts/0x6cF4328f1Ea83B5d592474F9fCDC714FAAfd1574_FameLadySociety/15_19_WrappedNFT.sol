// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {OperatorFilterer} from "operator-filter-registry/src/OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/src/lib/Constants.sol";
import {ITokenURIGenerator} from "./ITokenURIGenerator.sol";
import {IERC4906} from "./IERC4906.sol";

contract WrappedNFT is
    AccessControl,
    ERC721,
    Ownable2Step,
    OperatorFilterer,
    IERC4906
{
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }
    RoyaltyInfo public defaultRoyaltyInfo;
    IERC721 public immutable wrappedNft;
    ITokenURIGenerator public renderer;
    uint256 public wrapCost = 0;
    address private devDonationAddress;
    string private conractMetadataURI;
    mapping(uint256 => bool) public claimed;

    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant EMIT_METADATA_ROLE =
        keccak256("EMIT_METADATA_ROLE");
    bytes32 public constant UPDATE_RENDERER_ROLE =
        keccak256("UPDATE_RENDERER_ROLE");

    error MustWrapOneToken();
    error MustOwnToken(uint256 tokenId);
    error TokenNotWrapped(uint256 tokenId);
    error NotEnoughEther(uint256 required);
    error DevTipFailed();
    error WithdrawFailed();
    error NoContractUri();

    constructor(
        string memory name,
        string memory symbol,
        address nftContract,
        address tokenRenderer
    ) ERC721(name, symbol) OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {
        wrappedNft = IERC721(nftContract);
        renderer = ITokenURIGenerator(tokenRenderer);
        transferOwnership(msg.sender);
        _grantRole(AccessControl.DEFAULT_ADMIN_ROLE, msg.sender);
        devDonationAddress = msg.sender;
    }

    /**
     * @dev Wraps multiple tokens in a single transaction and sends them to the caller
     *
     * @param tokenIds the tokens to wrap
     */
    function wrap(uint256[] calldata tokenIds) public payable {
        wrapTo(msg.sender, tokenIds);
    }

    /**
     * @dev Wraps multiple tokens in a single transaction and sends them to the specified address
     *
     * @param to the address to send the wrapped tokens to
     * @param tokenIds the tokens to wrap
     */
    function wrapTo(address to, uint256[] calldata tokenIds) public payable {
        if (tokenIds.length == 0) revert MustWrapOneToken();
        uint256 totalCost = wrapCost * tokenIds.length;
        if (msg.value < totalCost)
            revert NotEnoughEther(totalCost);
        // leftover value is sent to the dev donation address

        if (msg.value > totalCost) {
            (bool sent, ) = payable(devDonationAddress).call{
                value: msg.value - totalCost
            }("");
            if (!sent) revert DevTipFailed();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Don't use safeTransferFrom as we don't want to trigger the onERC721Received
            wrappedNft.transferFrom(msg.sender, address(this), tokenIds[i]);
            _mint(to, tokenIds[i]);
        }
    }

    /**
     * Called when an ERC721 is sent to the contract. If it's an a token we can wrap then send back a wrapped token
     */
    function onERC721Received(
        address from,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // Check that we now own token
        if (wrappedNft.ownerOf(tokenId) != address(this))
            revert MustOwnToken(tokenId);
        // Can only succeed if the token does not already exist
        _mint(from, tokenId);
        // Done
        return this.onERC721Received.selector;
    }

    /**
     * @dev Unwraps a token and sends it to the specified address
     *
     * @param to the address to send the wrapped tokens to
     * @param tokenId the token to unwrap
     */
    function unwrap(address to, uint256 tokenId) public {
        if (!isWrapped(tokenId)) revert TokenNotWrapped(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert MustOwnToken(tokenId);
        _burn(tokenId);
        wrappedNft.safeTransferFrom(address(this), to, tokenId);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev Unwraps multiple tokens in a single transaction and sends them to the specified address
     *
     * @param to the address to send the wrapped tokens to
     * @param tokenIds the tokens to unwrap
     */
    function unwrapMany(address to, uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unwrap(to, tokenIds[i]);
        }
    }

    /**
     * @dev Returns the URI for a given token ID
     *
     * @param tokenId the tokens ID to retrieve metadata for
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    /**
     * @dev Returns the contract URI
     */
    function contractURI() public view returns (string memory) {
        if (bytes(conractMetadataURI).length == 0) revert NoContractUri();
        return conractMetadataURI;
    }

    /**
     * @dev allows the renderer to emit a metadata update event when metadata changes
     *
     * @param tokenId the token ID to emit an update for
     */
    function emitMetadataUpdate(
        uint256 tokenId
    ) public onlyRole(EMIT_METADATA_ROLE) {
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev Tests if the contract supports an interface
     *
     * @param interfaceId the interface to test
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view returns (address, uint256 royaltyAmount) {
        royaltyAmount =
            (_salePrice * defaultRoyaltyInfo.royaltyFraction) /
            10000;

        return (defaultRoyaltyInfo.receiver, royaltyAmount);
    }

    /**
     * @dev Withdraws all the funds in the contract
     */
    function withdraw() public onlyRole(TREASURER_ROLE) {
        address royaltyReceiver = defaultRoyaltyInfo.receiver;
        (bool sent, ) = payable(royaltyReceiver).call{
            value: address(this).balance
        }("");
        if (!sent) revert WithdrawFailed();
    }

    /**
     * @dev Returns true of the tokenId is wrapped (owned by this contract)
     *
     * @param tokenId the token to check if wrapped
     * @return bool
     */
    function isWrapped(uint256 tokenId) public view returns (bool) {
        return wrappedNft.ownerOf(tokenId) == address(this);
    }

    /**
     * @dev Updates the renderer to a new render contract. Can only be called by an address with the UPDATE_RENDERER_ROLE. Emits an EIP4906 BatchMetadataUpdate event
     *
     * @param newRenderer the new renderer
     */
    function setRenderer(
        address newRenderer
    ) public onlyRole(UPDATE_RENDERER_ROLE) {
        _revokeRole(EMIT_METADATA_ROLE, address(renderer));
        renderer = ITokenURIGenerator(newRenderer);
        _grantRole(EMIT_METADATA_ROLE, address(renderer));
        emit BatchMetadataUpdate(0, 10000);
    }

    function setContractURI(
        string memory uri
    ) public onlyRole(UPDATE_RENDERER_ROLE) {
        conractMetadataURI = uri;
    }

    /**
     * @dev Updates the EIP2981 Royalty info
     *
     * @param receiver The receiver of royalties
     * @param feeNumerator The royalty percent in basis points so 500 = 5%
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(TREASURER_ROLE) {
        defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Returns the EIP2981 royalty info for a token
     *
     * @param cost the cost to wrap one token
     */
    function setWrapCost(uint256 cost) public onlyRole(TREASURER_ROLE) {
        wrapCost = cost;
    }
}