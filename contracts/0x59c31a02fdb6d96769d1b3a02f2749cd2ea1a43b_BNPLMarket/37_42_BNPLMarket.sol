pragma solidity 0.8.9;
// SPDX-License-Identifier: MIT

// Contracts

import "@teller-protocol/v2-contracts/contracts/interfaces/ITellerV2.sol";
import "@teller-protocol/v2-contracts/contracts/TellerV2MarketForwarder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SeaportEscrowBuyer.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// Interfaces
import "@teller-protocol/v2-contracts/contracts/interfaces/IMarketRegistry.sol";
import "@teller-protocol/v2-contracts/contracts/interfaces/IEAS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IWETH.sol";

import { BasicOrderParameters, BasicOrderType } from "./seaport/lib/ConsiderationStructs.sol";

contract BNPLMarket is
    Initializable,
    ERC2771ContextUpgradeable,
    TellerV2MarketForwarder,
    SeaportEscrowBuyer,
    IERC721Receiver
{
    uint256 public immutable marketId;
    address public immutable CRA_SIGNER;
    address public immutable wethAddress;
    address immutable ETH_ADDRESS = address(0);

    string public contractName;
    string public contractVersion;
    bytes32 public immutable DOMAIN_SEPARATOR;

    enum TokenType {
        ERC721,
        ERC1155
    }

    enum BasicOrderRouteType {
        ETH_TO_ERC721,
        ETH_TO_ERC1155,
        ERC20_TO_ERC721,
        ERC20_TO_ERC1155,
        ERC721_TO_ERC20,
        ERC1155_TO_ERC20
    }

    struct EscrowedTokenData {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        bool tokenClaimed;
    }

    struct AssetReceiptRegister {
        address assetContractAddress;
        uint256 assetTokenId;
        uint256 quantity;
    }

    mapping(uint256 => EscrowedTokenData) public escrowedTokensForLoan;
    AssetReceiptRegister public assetReceiptRegister;

    struct SubmitBidArgs {
        address lender;
        uint256 totalPurchasePrice;
        uint256 principal;
        uint256 downPayment;
        uint32 duration;
        uint16 interestRate;
        string metadataURI;
    }

    /**
     * @notice Constructor for this contract.
     * @param _tellerV2 The address of the TellerV2 lending platform contract.
     * @param _marketId The Marketplace Id used in the lending platform contract.
     * @param _nftExchangeAddress The nft exchange contract using Seaport protocol.
     * @param _wethAddress The address of the Wrapped Ether contract.
     * @param _trustedForwarder The trusted forwarder contract for meta transactions.
     * @param _craSigner The public address of cra signer used to approve loans.
     */
    constructor(
        address _tellerV2,
        uint256 _marketId,
        address _nftExchangeAddress,
        address _wethAddress,
        address _trustedForwarder,
        address _craSigner
    )
        TellerV2MarketForwarder(address(_tellerV2))
        ERC2771ContextUpgradeable(_trustedForwarder)
        SeaportEscrowBuyer(_nftExchangeAddress)
    {
        marketId = _marketId;
        CRA_SIGNER = _craSigner;
        wethAddress = _wethAddress;

        contractName = "Teller_BNPL_Market";
        contractVersion = "1.0";

        DOMAIN_SEPARATOR = makeDomainSeparator(contractName, contractVersion);
    }

    function initialize() external initializer {}

    /**
     * @notice Creates the domain separator for EIP712 signature verification.
     * @param name The formal name for this contract.
     * @param version The current version of this contract.
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Takes out a loan using TellerV2 and uses the funds to purchase an NFT asset and escrow it within this contract until the loan is finalized.
     * @param _submitBidArgs Details describing the loan agreement
     * @param _basicOrderParameters Details describing the NFT offer order.
     * @param _signature The signature from the CRA server that approves this new loan.
     */
    function execute(
        SubmitBidArgs calldata _submitBidArgs,
        BasicOrderParameters calldata _basicOrderParameters,
        bytes calldata _signature
    ) public payable {
        require(
            msg.value == _submitBidArgs.downPayment,
            "Incorrect downpayment"
        );

        address paymentToken = _basicOrderParameters.considerationToken;
        require(paymentToken == ETH_ADDRESS, "Payment token must be ETH");

        uint256 bidId = _submitAssetPurchaseUsingLoan(
            _submitBidArgs,
            _basicOrderParameters
        );

        address assetContractAddress = _basicOrderParameters.offerToken;
        uint256 assetTokenId = _basicOrderParameters.offerIdentifier;
        uint256 quantity = _basicOrderParameters.offerAmount;

        _verifySignature(
            getTypeHash(
                _submitBidArgs,
                assetContractAddress,
                assetTokenId,
                quantity,
                _submitBidArgs.totalPurchasePrice, //base price
                paymentToken
            ),
            _signature
        );

        TokenType tokenType = _fetchTokenTypeFromOrderType(
            _basicOrderParameters.basicOrderType
        );

        if (tokenType == TokenType.ERC721) {
            require(
                _hasOwnershipOfERC721Asset(assetContractAddress, assetTokenId),
                "Asset Receipt Invalid"
            );
        } else {
            //require asset handshake registry values and reset them for 1155
            require(
                validateAssetReceiptRegister(
                    assetContractAddress,
                    assetTokenId,
                    quantity
                ),
                "Asset Receipt Invalid"
            );
            resetAssetReceiptRegister();
        }

        _assignNftToLoan(
            assetContractAddress,
            assetTokenId,
            tokenType,
            quantity,
            bidId
        );
    }

    /**
     * @notice Returns the type of token for the order, ERC721 or ERC1155.
     * @param orderType The basicOrderType from the Seaport protocol response
     */
    function _fetchTokenTypeFromOrderType(BasicOrderType orderType)
        internal
        pure
        returns (TokenType)
    {
        if (
            orderType >= BasicOrderType.ETH_TO_ERC721_FULL_OPEN &&
            orderType <= BasicOrderType.ETH_TO_ERC721_PARTIAL_RESTRICTED
        ) {
            return TokenType.ERC721;
        }

        if (
            orderType >= BasicOrderType.ETH_TO_ERC1155_FULL_OPEN &&
            orderType <= BasicOrderType.ETH_TO_ERC1155_PARTIAL_RESTRICTED
        ) {
            return TokenType.ERC1155;
        }

        revert("Invalid Basic Order Type");
    }

    /**
     * @notice Creates a new loan and purchases an NFT.
     * @param _submitBidArgs Details describing the loan agreement
     * @param _basicOrderParameters Details describing the NFT offer order.
     */
    function _submitAssetPurchaseUsingLoan(
        SubmitBidArgs calldata _submitBidArgs,
        BasicOrderParameters calldata _basicOrderParameters
    ) internal returns (uint256 bidId) {
        address lendingToken = wethAddress;

        bidId = _submitBid(_submitBidArgs, lendingToken);

        _acceptBid(bidId, _submitBidArgs.lender);

        require(
            _purchaseNFT(
                _basicOrderParameters,
                _submitBidArgs.totalPurchasePrice
            ),
            "NFT purchase failed"
        );

        return bidId;
    }

    /**
     * @notice Returns the typehash for the EIP712 signature verification.
     * @param _submitBidArgs Details describing the loan agreement.
     * @param assetContractAddress The contract address for the NFT asset being purchased.
     * @param assetTokenId The token id for the NFT asset being purchased.
     * @param assetQuantity The quantity of the NFT asset being purchased.
     * @param totalPurchasePrice The total amount of currency being spent to purchase the NFT asset.
     * @param paymentToken The address of the currency being spent to purchase the NFT asset.
     */
    function getTypeHash(
        SubmitBidArgs memory _submitBidArgs,
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 assetQuantity,
        uint256 totalPurchasePrice,
        address paymentToken
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "inputs(address offerToken,uint256 offerIdentifier,uint256 offerAmount,uint256 totalPurchasePrice,address considerationToken,uint256 principal,uint256 downPayment,uint32 duration,uint16 interestRate)"
                    ),
                    assetContractAddress,
                    assetTokenId,
                    assetQuantity,
                    totalPurchasePrice,
                    paymentToken,
                    _submitBidArgs.principal,
                    _submitBidArgs.downPayment,
                    _submitBidArgs.duration,
                    _submitBidArgs.interestRate
                )
            );
    }

    /**
     * @notice Returns the public address recovered from the CRA signature.
     * @param domainSeparator The EIP712 domain hash including details for this contract.
     * @param typeHash The hash including the loan and NFT details.
     * @param _signature The EIP712 signature from the CRA Server.
     */
    function recoverSignature(
        bytes32 domainSeparator,
        bytes32 typeHash,
        bytes memory _signature
    ) public view virtual returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, typeHash)
        );

        return ECDSAUpgradeable.recover(dataHash, _signature);
    }

    /**
     * @notice Returns true if and only if the EIP712 signature is valid for the typehash and domain separator.
     * @param typeHash The hash including the loan and NFT details.
     * @param _signature The EIP712 signature from the CRA Server.
     */
    function _verifySignature(bytes32 typeHash, bytes memory _signature)
        internal
        view
        virtual
    {
        address signer = recoverSignature(
            DOMAIN_SEPARATOR,
            typeHash,
            _signature
        );
        require(signer == CRA_SIGNER, "invalid CRA signature");
    }

    /**
     * @notice Creates a new loan using the TellerV2 lending protocol.
     * @param _submitBidArgs Details describing the loan agreement.
     * @param lendingToken The address of the currency used for the new loan.
     */
    function _submitBid(
        SubmitBidArgs memory _submitBidArgs,
        address lendingToken
    ) internal virtual returns (uint256 bidId) {
        bytes memory responseData;

        responseData = _forwardCall(
            abi.encodeWithSelector(
                ITellerV2.submitBid.selector,
                lendingToken,
                marketId,
                _submitBidArgs.principal,
                _submitBidArgs.duration,
                _submitBidArgs.interestRate,
                _submitBidArgs.metadataURI,
                // Ensure the receiver of the loan funds is this contract
                address(this)
            ),
            _msgSender()
        );

        return abi.decode(responseData, (uint256));
    }

    /**
     * @notice Accepts a new loan using the TellerV2 lending protocol.
     * @param bidId The id of the new loan.
     * @param _lender The address of the lender who will provide funds for the new loan.
     */
    function _acceptBid(uint256 bidId, address _lender)
        internal
        virtual
        returns (uint256 wethGained)
    {
        bytes memory responseData;

        uint256 wethBalanceBefore = IWETH(wethAddress).balanceOf(address(this));

        // Approve the borrower's loan
        responseData = _forwardCall(
            abi.encodeWithSelector(ITellerV2.lenderAcceptBid.selector, bidId),
            _lender
        );

        wethGained =
            IWETH(wethAddress).balanceOf(address(this)) -
            wethBalanceBefore;

        return wethGained;
    }

    /**
     * @notice Purchases an NFT using the Seaport protocol
     * @param _basicOrderParameters  Details describing the NFT offer order.
     * @param totalPurchasePrice Total amount of currency used as the msg.value for the nft purchase trnsaction.
     */
    function _purchaseNFT(
        BasicOrderParameters memory _basicOrderParameters,
        uint256 totalPurchasePrice
    ) internal virtual returns (bool) {
        uint256 downPayment = msg.value;

        uint256 additionalEthNeededToPurchase = (totalPurchasePrice -
            downPayment);

        _unwrapWethFromBid(additionalEthNeededToPurchase);

        return
            fulfillBasicOrderThrough(_basicOrderParameters, totalPurchasePrice);
    }

    /**
     * @notice Unwrap WETH into ETH
     * @param amt Amount to unwrap in wei.
     */
    function _unwrapWethFromBid(uint256 amt)
        internal
        virtual
        returns (uint256)
    {
        IWETH(wethAddress).withdraw(amt);

        return amt;
    }

    /**
     * @notice Map data of a purchased NFT towards a TellerV2 loanId.
     * @param tokenAddress  The contract address of the NFT asset.
     * @param tokenId  The token id of the NFT asset.
     * @param tokenType  The NFT asset type either ERC721 or ERC1155.
     * @param amount  The quantity of the NFT asset.
     * @param loanId  The bidId for the loan in the TellerV2 protocol.
     */
    function _assignNftToLoan(
        address tokenAddress,
        uint256 tokenId,
        TokenType tokenType,
        uint256 amount,
        uint256 loanId
    ) internal virtual returns (bool) {
        escrowedTokensForLoan[loanId] = EscrowedTokenData({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            tokenType: tokenType,
            amount: amount,
            tokenClaimed: false
        });

        return true;
    }

    /**
     * @notice Withdraw the NFT from this contract to the lender when loan is defaulted.
     * @param bidId The bidId for the loan from the TellerV2 protocol.
     */
    function claimNFTFromDefaultedLoan(uint256 bidId) public {
        require(getTellerV2().isLoanDefaulted(bidId), "Loan is not defaulted");
        address lender = getTellerV2().getLoanLender(bidId);
        _claimNFT(bidId, lender);
    }

    /**
     * @notice Withdraw the NFT from this contract to the borrower when loan is paid.
     * @param bidId The bidId for the loan from the TellerV2 protocol.
     */
    function claimNFTFromRepaidLoan(uint256 bidId) public {
        require(
            getTellerV2().getBidState(bidId) ==
                TellerV2Storage_G0.BidState.PAID,
            "Loan is not repaid"
        );
        address borrower = getTellerV2().getLoanBorrower(bidId);
        _claimNFT(bidId, borrower);
    }

    /**
     * @notice Withdraw the NFT from this contract to a recipient.
     * @param bidId The bidId for the loan from the TellerV2 protocol.
     * @param recipient The address of the account that will receive the NFT.
     */
    function _claimNFT(uint256 bidId, address recipient) internal {
        require(
            !escrowedTokensForLoan[bidId].tokenClaimed,
            "Token already claimed."
        );
        escrowedTokensForLoan[bidId].tokenClaimed = true;

        if (escrowedTokensForLoan[bidId].tokenType == TokenType.ERC1155) {
            bytes memory data;

            IERC1155(escrowedTokensForLoan[bidId].tokenAddress)
                .safeTransferFrom(
                    address(this),
                    recipient,
                    escrowedTokensForLoan[bidId].tokenId,
                    escrowedTokensForLoan[bidId].amount,
                    data
                );
        } else {
            IERC721(escrowedTokensForLoan[bidId].tokenAddress).safeTransferFrom(
                    address(this),
                    recipient,
                    escrowedTokensForLoan[bidId].tokenId
                );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        setAssetReceiptRegister(msg.sender, id, value);

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata
    ) external returns (bytes4) {
        require(
            _ids.length == 1,
            "Only allowed one asset batch transfer per transaction."
        );

        setAssetReceiptRegister(msg.sender, _ids[0], _values[0]);

        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /**
     * @notice Returns true if and only if this contract is the owner of an ERC721 NFT asset.
     * @param assetContractAddress The contract address for the NFT asset.
     * @param assetTokenId The token id for the NFT asset.
     */
    function _hasOwnershipOfERC721Asset(
        address assetContractAddress,
        uint256 assetTokenId
    ) internal virtual returns (bool) {
        address currentOwner = IERC721(assetContractAddress).ownerOf(
            assetTokenId
        );

        return address(this) == currentOwner;
    }

    /**
     * @notice Sets a temporary mutex for tracking receipt of an NFT asset.
     * @param assetContractAddress The contract address for the NFT asset.
     * @param assetTokenId The token id for the NFT asset.
     * @param quantity The quantity of the NFT asset. Always 1 for ERC721.
     */
    function setAssetReceiptRegister(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity
    ) internal {
        assetReceiptRegister = AssetReceiptRegister({
            assetContractAddress: assetContractAddress,
            assetTokenId: assetTokenId,
            quantity: quantity
        });
    }

    /**
     * @notice Reset the temporary mutex for tracking receipt of an NFT asset.
     */
    function resetAssetReceiptRegister() internal {
        delete assetReceiptRegister;
    }

    /**
     * @notice Verifies the state of the a temporary mutex for tracking receipt of an NFT asset.
     * @param assetContractAddress The contract address for the NFT asset.
     * @param assetTokenId The token id for the NFT asset.
     * @param quantity The quantity of the NFT asset. Always 1 for ERC721.
     */
    function validateAssetReceiptRegister(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity
    ) internal view returns (bool) {
        return
            (assetReceiptRegister.assetContractAddress ==
                assetContractAddress) &&
            (assetReceiptRegister.assetTokenId == assetTokenId &&
                assetReceiptRegister.quantity == quantity);
    }

    //can accept eth
    receive() external payable virtual {}
}