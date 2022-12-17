// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "solmate/tokens/ERC1155.sol";
import "fount-contracts/auth/Auth.sol";
import "fount-contracts/community/FountCardCheck.sol";
import "fount-contracts/extensions/SwappableMetadata.sol";
import "fount-contracts/utils/Royalties.sol";
import "fount-contracts/utils/Withdraw.sol";
import "closedsea/OperatorFilterer.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/EIP712.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IDriversPayments.sol";
import "./interfaces/IWETH.sol";

/**
 * @author Fount Gallery
 * @title  ERC1155Base
 * @notice Base contract for Drivers Open Editions to inherit from
 *
 * Features:
 *   - EIP-712 signature minting and verification
 *   - On-chain checking of Fount Gallery Patron cards for minting
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
abstract contract ERC1155Base is
    ERC1155,
    Auth,
    FountCardCheck,
    SwappableMetadata,
    Royalties,
    Withdraw,
    EIP712,
    OperatorFilterer
{
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice everfresh.eth
    address public everfresh = 0xBb3444a06E9928dDA9a739CdAb3E0c5cf6890099;

    /// @notice Contract information
    string public contractURI;

    /// @notice Contract name
    string public name = "Drivers Open Editions by Everfresh";

    /// @notice Contract symbol
    string public symbol = "DRIVERS";

    /// @notice EIP-712 signing domain
    string public constant SIGNING_DOMAIN = "DriversOpenEditions";

    /// @notice EIP-712 signature version
    string public constant SIGNATURE_VERSION = "1";

    /// @notice EIP-712 signed data type hash for minting with an off-chain signature
    bytes32 public constant MINT_SIGNATURE_TYPEHASH =
        keccak256("MintSignatureData(uint256 id,uint256 amount,address to,uint256 nonce)");

    /// @dev EIP-712 signed data struct for minting with an off-chain signature
    struct MintSignatureData {
        uint256 id;
        uint256 amount;
        address to;
        uint256 nonce;
        bytes signature;
    }

    /// @notice Approved signer public addresses
    mapping(address => bool) public approvedSigners;

    /// @notice Nonce management to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /// @notice If operator filtering is applied
    bool public operatorFilteringEnabled;

    /// @notice Wrapped ETH contract address for safe ETH transfer fallbacks
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Address where proceeds should be sent
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
     * @param admin_ The admin of the contract
     * @param payments_ The admin of the contract
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     * @param fountCard_ The address of the Fount Gallery Patron Card
     */
    constructor(
        address owner_,
        address admin_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_,
        address fountCard_
    )
        ERC1155()
        Auth(owner_, admin_)
        FountCardCheck(fountCard_)
        SwappableMetadata(metadata_)
        Royalties(payments_, royaltiesAmount_)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        payments = payments_;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        emit Init();
    }

    /* ------------------------------------------------------------------------
       A R T I S T   M I N T I N G
    ------------------------------------------------------------------------ */

    function _mintToArtistFirst(
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), everfresh, id, amount);
        emit TransferSingle(msg.sender, everfresh, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    everfresh,
                    id,
                    amount,
                    ""
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /* ------------------------------------------------------------------------
       S I G N A T U R E   V E R I F I C A T I O N
    ------------------------------------------------------------------------ */

    /**
     * @notice Internal function to verify an EIP-712 minting signature
     * @param id The token id
     * @param to The account that has approval to mint
     * @param signature The EIP-712 signature
     * @return bool If the signature is verified or not
     */
    function _verifyMintSignature(
        uint256 id,
        uint256 amount,
        address to,
        bytes calldata signature
    ) internal returns (bool) {
        MintSignatureData memory data = MintSignatureData({
            id: id,
            amount: amount,
            to: to,
            nonce: nonces[to],
            signature: signature
        });

        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINT_SIGNATURE_TYPEHASH,
                    data.id,
                    data.amount,
                    data.to,
                    nonces[data.to]++
                )
            )
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        return approvedSigners[addr] && addr != address(0);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** SIGNERS ------------------------------------------------------------ */

    /**
     * @notice Admin function to set an EIP-712 signer address
     * @param signer The address of the new signer
     * @param approved If the signer is approved
     */
    function setSigner(address signer, bool approved) external onlyOwnerOrAdmin {
        approvedSigners[signer] = approved;
    }

    /** METADATA ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the metadata contract address
     * @param metadata The new metadata contract address
     */
    function setMetadataAddress(address metadata) public override onlyOwnerOrAdmin {
        _setMetadataAddress(metadata);
    }

    /**
     * @notice Admin function to set the contract URI for marketplaces
     * @param contractURI_ The new contract URI
     */
    function setContractURI(string memory contractURI_) external onlyOwnerOrAdmin {
        contractURI = contractURI_;
    }

    /** ROYALTIES ---------------------------------------------------------- */

    /**
     * @notice Admin function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwnerOrAdmin {
        _setRoyaltyInfo(receiver, amount);
    }

    /**
     * @notice Admin function to set whether OpenSea's Operator Filtering should be enabled
     * @param enabled If the operator filtering should be enabled
     */
    function setOperatorFilteringEnabled(bool enabled) external onlyOwnerOrAdmin {
        operatorFilteringEnabled = enabled;
    }

    function registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        external
        onlyOwnerOrAdmin
    {
        _registerForOperatorFiltering(subscriptionOrRegistrantToCopy, subscribe);
    }

    /** PAYMENTS ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the payment address for withdrawing funds
     * @param paymentAddress The new address where payments should be sent upon withdrawal
     */
    function setPaymentAddress(address paymentAddress) external onlyOwnerOrAdmin {
        if (paymentAddress == address(0)) revert CannotSetPaymentAddressToZero();
        payments = paymentAddress;
    }

    /* ------------------------------------------------------------------------
       R O T A L T I E S
    ------------------------------------------------------------------------ */

    /**
     * @notice Add interface for on-chain royalty standard
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165)
        returns (bool)
    {
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
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
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
     * @dev Overrde `OperatorFilterer._operatorFilteringEnabled` to return whether
     * the operator filtering is enabled in this contract.
     */
    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    /* ------------------------------------------------------------------------
       S A F E   T R A N S F E R S
    ------------------------------------------------------------------------ */

    /**
     * @notice Safely transfer ETH by wrapping as WETH if the ETH transfer fails
     * @param to The address to transfer ETH/WETH to
     * @param amount The amount of ETH/WETH to transfer
     */
    function _transferETHWithFallback(address to, uint256 amount) internal {
        if (!_transferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @param to The address to transfer ETH to
     * @param amount The amount of ETH to transfer
     */
    function _transferETH(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}(new bytes(0));
        return success;
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

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawETH() public onlyOwnerOrAdmin {
        // Send the eth to the payments address
        _withdrawETH(payments);
    }

    /**
     * @notice Admin function to withdraw ETH from this contract and release from payments contract
     * @dev Withdraws to the `payments` address, then calls `releaseAllETH` as a splitter.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawAndReleaseAllETH() public onlyOwnerOrAdmin {
        // Send the eth to the payments address
        _withdrawETH(payments);
        // And then release all the ETH to the payees
        IDriversPayments(payments).releaseAllETH();
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - the payments address is set to zero
     *
     */
    function withdrawTokens(address tokenAddress) public onlyOwnerOrAdmin {
        // Send the tokens to the payments address
        _withdrawToken(tokenAddress, payments);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @param to The address to send the ERC-20 tokens to
     */
    function withdrawTokens(address tokenAddress, address to) public onlyOwnerOrAdmin {
        _withdrawToken(tokenAddress, to);
    }
}