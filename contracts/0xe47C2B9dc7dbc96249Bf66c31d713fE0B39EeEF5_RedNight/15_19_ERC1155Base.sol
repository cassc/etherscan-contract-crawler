// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {FountCardCheck} from "fount-contracts/community/FountCardCheck.sol";
import {SwappableMetadata} from "fount-contracts/extensions/SwappableMetadata.sol";
import {Royalties} from "fount-contracts/utils/Royalties.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {Withdraw} from "fount-contracts/utils/Withdraw.sol";
import {IPayments} from "./interfaces/IPayments.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC165} from "openzeppelin/interfaces/IERC165.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";

/**
 * @author Fount Gallery
 * @title  ERC1155Base
 * @notice Base contract for Tormius 23 to inherit from
 *
 * Features:
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
abstract contract ERC1155Base is
    ERC1155,
    Owned,
    SwappableMetadata,
    Royalties,
    OperatorFilterer,
    Withdraw
{
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    string public name = "Tormius 23";
    string public symbol = "TOR23";

    /// @notice Contract information
    string public contractURI;

    /// @notice Approved minting addresses
    mapping(address => bool) public approvedMinters;

    /// @notice If operator filtering is applied
    bool public operatorFilteringEnabled;

    /// @notice Address where royalties/stuck funds should be sent
    address public payments;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error CannotSetPaymentAddressToZero();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event Init();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param payments_ The admin of the contract
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     */
    constructor(
        address owner_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_
    ) ERC1155() Owned(owner_) SwappableMetadata(metadata_) Royalties(payments_, royaltiesAmount_) {
        payments = payments_;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        emit Init();
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** MINTERS ------------------------------------------------------------ */

    /**
     * @notice Admin function to set a minter address
     * @param minter The address of the new minter
     * @param approved If the minter is approved
     */
    function setMinter(address minter, bool approved) external onlyOwner {
        approvedMinters[minter] = approved;
    }

    /** METADATA ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the metadata contract address
     * @param metadata The new metadata contract address
     */
    function setMetadataAddress(address metadata) public override onlyOwner {
        _setMetadataAddress(metadata);
    }

    /**
     * @notice Admin function to set the contract URI for marketplaces
     * @param contractURI_ The new contract URI
     */
    function setContractURI(string memory contractURI_) external onlyOwner {
        contractURI = contractURI_;
    }

    /** ROYALTIES ---------------------------------------------------------- */

    /**
     * @notice Admin function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwner {
        _setRoyaltyInfo(receiver, amount);
    }

    /**
     * @notice Admin function to set whether OpenSea's Operator Filtering should be enabled
     * @param enabled If the operator filtering should be enabled
     */
    function setOperatorFilteringEnabled(bool enabled) external onlyOwner {
        operatorFilteringEnabled = enabled;
    }

    function registerForOperatorFiltering(
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) external onlyOwner {
        _registerForOperatorFiltering(subscriptionOrRegistrantToCopy, subscribe);
    }

    /** PAYMENTS ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the payment address for withdrawing stuck funds
     * @param paymentAddress The new address where payments should be sent upon withdrawal
     */
    function setPaymentAddress(address paymentAddress) external onlyOwner {
        if (paymentAddress == address(0)) revert CannotSetPaymentAddressToZero();
        payments = paymentAddress;
    }

    /* ------------------------------------------------------------------------
       R O T A L T I E S
    ------------------------------------------------------------------------ */

    /**
     * @notice Add interface for on-chain royalty standard
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, IERC165) returns (bool) {
        return interfaceId == ROYALTY_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Repeats the OpenSea Operator Filtering registration
     */
    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    /**
     * @notice Override ERC-1155 `setApprovalForAll` to support OpenSea Operator Filtering
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override ERC-1155 `safeTransferFrom` to support OpenSea Operator Filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Override ERC-1155 `safeTransferFrom` to support OpenSea Operator Filtering
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Override `OperatorFilterer._operatorFilteringEnabled` to return whether
     * the operator filtering is enabled in this contract.
     */
    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw stuck ETH
     * @dev Withdraws to the `payments` address. Reverts if the payments address is set to zero.
     */
    function withdrawETH() public {
        _withdrawETH(payments);
    }

    /**
     * @notice Admin function to withdraw stuck ERC-20 tokens
     * @dev Withdraws to the `payments` address. Reverts if the payments address is set to zero.
     */
    function withdrawTokens(address tokenAddress) public {
        _withdrawToken(tokenAddress, payments);
    }

    /* ------------------------------------------------------------------------
       E R C 1 1 5 5
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the token metadata
     * @return id The token id to get metadata for
     */
    function uri(uint256 id) public view override returns (string memory) {
        return IMetadata(metadata).tokenURI(id);
    }

    /**
     * @notice Burn a token. You can only burn tokens you own.
     * @param id The token id to burn
     * @param amount The amount to burn
     */
    function burn(uint256 id, uint256 amount) external {
        require(balanceOf[msg.sender][id] >= amount, "CANNOT_BURN");
        _burn(msg.sender, id, amount);
    }
}