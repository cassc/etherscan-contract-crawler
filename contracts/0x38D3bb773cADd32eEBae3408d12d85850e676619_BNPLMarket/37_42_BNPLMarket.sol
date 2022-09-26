pragma solidity 0.8.9;
// SPDX-License-Identifier: MIT

// Contracts

import "@teller-protocol/v2-contracts/contracts/interfaces/ITellerV2.sol";
import "@teller-protocol/v2-contracts/contracts/TellerV2MarketForwarder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// Interfaces
import "@teller-protocol/v2-contracts/contracts/interfaces/IMarketRegistry.sol";
import "@teller-protocol/v2-contracts/contracts/interfaces/IEAS.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "./interfaces/IWETH.sol";

import "./interfaces/IBNPLMarket.sol";
import "./interfaces/IEscrowBuyer.sol";
import { BasicOrderParameters, BasicOrderType } from "./seaport/lib/ConsiderationStructs.sol";

contract BNPLMarket is
    Initializable,
    ERC2771ContextUpgradeable,
    TellerV2MarketForwarder,
    IBNPLMarket
{
    using NumbersLib for uint256;

    uint256 public immutable marketId;
    address public immutable CRA_SIGNER;
    address public immutable wethAddress;
    address public immutable ETH_ADDRESS = address(0);
    bytes32 public immutable DOMAIN_SEPARATOR;

    string public constant CONTRACT_NAME = "Teller_BNPL_Market";
    string public constant CONTRACT_VERSION = "3.0"; //used for offchain signature domain separator

    // no longer used, now only placeholders
    string private __contractNameDeprecated;
    string private __contractVersionDeprecated;

    //tellerv2 bidId => escrowedToken for BNPL
    mapping(uint256 => EscrowedTokenData) public escrowedTokensForLoan;

    //DEPRECATED
    struct AssetReceiptRegister {
        address assetContractAddress;
        uint256 assetTokenId;
        uint256 quantity;
    }
    AssetReceiptRegister public __assetReceiptRegister; //DEPRECATED

    //signature hash => has been executed
    mapping(bytes32 => bool) public executedSignatures;

    //bid ID -> discrete order
    mapping(uint256 => DiscreteOrder) public discreteOrders;

    address public cryptopunksMarketAddress;

    address public cryptopunksEscrowBuyer;
    address public seaportEscrowBuyer;

    string public upgradedToVersion; //used for the onUpgrade method alongside UPGRADE_VERSION

    //allowlist for fee recipients
    mapping(address => bool) public allowedFeeRecipients;

    uint16 public referralRewardPercent;

    uint256 public discreteOrderCount;

    modifier onlyMarketOwner() {
        require(
            _msgSender() == getTellerV2MarketOwner(marketId),
            "Not the market owner"
        );
        _;
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

    struct SubmitBidArgs {
        address lender;
        uint256 totalPurchasePrice;
        uint256 principal;
        uint256 downPayment;
        uint32 duration;
        uint32 signatureExpiration;
        uint16 interestRate;
        string metadataURI;
        address referralAddress;
    }

    struct DiscreteOrder {
        address borrower;
        SubmitBidArgs submitBidArgs;
        address assetContractAddress;
        uint256 assetTokenId;
        uint256 quantity;
        uint256 bidId; //TellerV2 loan bid id
    }

    event CreatedDiscreteOrder(
        uint256 discreteOrderId,
        address indexed borrower
    );

    event AssetPurchaseWithLoan(
        uint256 bidId,
        address indexed borrower,
        address indexed lender
    );

    event SetAllowedFeeRecipient(address _feeRecipient, bool allowed);

    event SetReferralReward(uint16 pct);

    event CancelledDiscreteOrder(uint256 discreteOrderId);

    event ClaimedAsset(
        uint256 indexed bidId,
        address recipient,
        address tokenContract,
        uint256 tokenId
    );

    event AcceptedDiscreteOrder(uint256 discreteOrderId, uint256 bidId);

    /**
     * @notice Constructor for this contract.
     * @param _tellerV2 The address of the TellerV2 lending platform contract.
     * @param _marketId The Marketplace Id used in the lending platform contract.
     * @param _wethAddress The address of the Wrapped Ether contract.
     * @param _trustedForwarder The trusted forwarder contract for meta transactions.
     * @param _craSigner The public address of cra signer used to approve loans.
     */
    constructor(
        address _tellerV2,
        address _marketRegistry,
        uint256 _marketId,
        address _wethAddress,
        address _trustedForwarder,
        address _craSigner
    )
        TellerV2MarketForwarder(address(_tellerV2), address(_marketRegistry))
        ERC2771ContextUpgradeable(_trustedForwarder)
    {
        marketId = _marketId;
        CRA_SIGNER = _craSigner;
        wethAddress = _wethAddress;

        DOMAIN_SEPARATOR = makeDomainSeparator(CONTRACT_NAME, CONTRACT_VERSION);
    }

    /*  
    The initializer sets the state variables for the Cryptopunks contract address and the escrowBuyer contracts. 
    */
    function initialize(
        address _cryptopunksMarketAddress,
        address _seaportEscrowBuyer,
        address _cryptopunksEscrowBuyer
    ) external initializer {
        upgradedToVersion = CONTRACT_VERSION;

        cryptopunksMarketAddress = _cryptopunksMarketAddress;
        seaportEscrowBuyer = (_seaportEscrowBuyer);
        cryptopunksEscrowBuyer = (_cryptopunksEscrowBuyer);

        //Initialize the escrow buyers so their owner is set to this address
        IEscrowBuyer(_seaportEscrowBuyer).initialize();
        IEscrowBuyer(_cryptopunksEscrowBuyer).initialize();
    }

    /*
    This can only be called once per time that the CURRENT_VERSION immutable variable is incremented.  
    This will only be called by the deploy script upon an upgrade.
    This sets the state variables for the Cryptopunks contract address and the escrowBuyer contracts. 
    */
    function onUpgrade(
        address _cryptopunksMarketAddress,
        address _seaportEscrowBuyer,
        address _cryptopunksEscrowBuyer
    ) external {
        require(
            keccak256(abi.encode(upgradedToVersion)) !=
                keccak256(abi.encode(CONTRACT_VERSION)),
            "already upgraded"
        );
        upgradedToVersion = CONTRACT_VERSION;

        cryptopunksMarketAddress = _cryptopunksMarketAddress;
        seaportEscrowBuyer = (_seaportEscrowBuyer);
        cryptopunksEscrowBuyer = (_cryptopunksEscrowBuyer);

        //Initialize the escrow buyers so their owner is set to this address
        IEscrowBuyer(_seaportEscrowBuyer).initialize();
        IEscrowBuyer(_cryptopunksEscrowBuyer).initialize();
    }

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
     * @notice The market owner can set the referralRewardPercent
     * @param _pct The proposed loan parameters
     */
    function setReferralRewardPercent(uint16 _pct) public onlyMarketOwner {
        require(_pct <= 10000, "Must be no more than 100 percent");
        referralRewardPercent = _pct;
        emit SetReferralReward(_pct);
    }

    /**
     * @notice Allows for NFTs that were escrowed in this contract to be migrated to the Seaport Escrow contract.
     * @param tokenAddresses The NFT contract address.
     * @param tokenIds The NFT token ID.
     * @param tokenTypes The type of NFT asset
     * @param amounts The amount of NFT asset quantity (1 if not 1155)
     */
    function transferLegacyAssetsArrayToEscrow(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        IBNPLMarket.TokenType[] calldata tokenTypes,
        uint256[] calldata amounts
    ) external onlyMarketOwner {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _transferLegacyAssetToEscrow(
                tokenAddresses[i],
                tokenIds[i],
                tokenTypes[i],
                amounts[i]
            );
        }
    }

    /**
     * @notice Allows for NFTs that were escrowed in this contract to be migrated to the Seaport Escrow contract.
     * @param tokenAddress The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param tokenType The type of NFT asset
     * @param amount The amount of NFT asset quantity (1 if not 1155)
     */
    function transferLegacyAssetToEscrow(
        address tokenAddress,
        uint256 tokenId,
        IBNPLMarket.TokenType tokenType,
        uint256 amount
    ) external onlyMarketOwner returns (bool) {
        return
            _transferLegacyAssetToEscrow(
                tokenAddress,
                tokenId,
                tokenType,
                amount
            );
    }

    /**
     * @notice Allows for NFTs that were escrowed in this contract to be migrated to the Seaport Escrow contract.
     * @param tokenAddress The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param tokenType The type of NFT asset
     * @param amount The amount of NFT asset quantity (1 if not 1155)
     */
    function _transferLegacyAssetToEscrow(
        address tokenAddress,
        uint256 tokenId,
        IBNPLMarket.TokenType tokenType,
        uint256 amount
    ) internal onlyMarketOwner returns (bool) {
        if (tokenType == IBNPLMarket.TokenType.ERC1155) {
            bytes memory data;
            IERC1155Upgradeable(tokenAddress).safeTransferFrom(
                address(this),
                seaportEscrowBuyer,
                tokenId,
                amount,
                data
            );
        } else {
            IERC721Upgradeable(tokenAddress).safeTransferFrom(
                address(this),
                seaportEscrowBuyer,
                tokenId
            );
        }
        return true;
    }

    /**
     * @notice The borrower submits a bid requesting funds to purchase an NFT and this is saved in a mapping
     * @param _submitBidArgs The proposed loan parameters
     * @param _assetContractAddress The nft contract address
     * @param _assetTokenId The nft token id
     * @param _quantity The nft quantity (1 for erc721)
     */
    function submitDiscreteOrder(
        SubmitBidArgs calldata _submitBidArgs,
        address _assetContractAddress,
        uint256 _assetTokenId,
        uint256 _quantity
    ) public returns (uint256 discreteOrderId) {
        require(
            block.timestamp < _submitBidArgs.signatureExpiration,
            "Expiration must be in the future"
        );

        require(
            _submitBidArgs.lender == address(0),
            "Lender must be zero address"
        );

        discreteOrderId = discreteOrderCount++;

        discreteOrders[discreteOrderId] = DiscreteOrder({
            borrower: _msgSender(),
            submitBidArgs: _submitBidArgs,
            assetContractAddress: _assetContractAddress,
            assetTokenId: _assetTokenId,
            quantity: _quantity,
            bidId: 0
        });

        emit CreatedDiscreteOrder(discreteOrderId, _msgSender());
    }

    /**
     * @notice Allows a borrower to cancel their own discrete order.
     * @param _discreteOrderId The discrete order id to cancel
     */
    function cancelDiscreteOrder(uint256 _discreteOrderId) public {
        require(
            _msgSender() == discreteOrders[_discreteOrderId].borrower,
            "Must be discrete order borrower."
        );

        delete discreteOrders[_discreteOrderId];

        emit CancelledDiscreteOrder(_discreteOrderId);
    }

    /**
     * @notice Lender accepts a bid, performs AcceptBid and purchases NFT using the downpayment + lender funds.
     * @param _discreteOrderId The discrete order to accept
     * @param _basicOrderParameters Details describing the NFT offer order.
     */
    function acceptDiscreteOrder(
        uint256 _discreteOrderId,
        BasicOrderParameters calldata _basicOrderParameters
    ) public {
        DiscreteOrder storage order = discreteOrders[_discreteOrderId];

        require(
            block.timestamp < order.submitBidArgs.signatureExpiration,
            "Discrete order has expired"
        );

        require(
            order.assetContractAddress == _basicOrderParameters.offerToken,
            "Invalid assetContractAddress"
        );
        require(
            order.assetTokenId == _basicOrderParameters.offerIdentifier,
            "Invalid assetTokenId"
        );
        require(
            order.quantity == _basicOrderParameters.offerAmount,
            "Invalid quantity"
        );

        //prevent re-entrancy
        require(
            order.submitBidArgs.lender == address(0),
            "Order already accepted"
        );
        order.submitBidArgs.lender = _msgSender();

        _collectDownpaymentForDiscreteOrder(
            order.borrower,
            order.submitBidArgs.downPayment
        );

        uint256 _bidId = _submitTellerV2Bid(order.submitBidArgs, wethAddress);

        discreteOrders[_discreteOrderId].bidId = _bidId;

        _acceptBidAndPurchaseNFT(
            _basicOrderParameters,
            _bidId,
            order.submitBidArgs.totalPurchasePrice,
            order.submitBidArgs.downPayment,
            order.submitBidArgs.lender
        );

        _payReferralFee(
            order.submitBidArgs.principal,
            order.submitBidArgs.referralAddress
        );

        emit AcceptedDiscreteOrder(_discreteOrderId, _bidId);
    }

    /**
     * @notice Transfer weth downpayment from the borrower into this contract so it can be used to purchase NFT immediately.
     * @param _borrower The loan borrower for BNPL
     * @param _downPayment The amount of money down
     */

    function _collectDownpaymentForDiscreteOrder(
        address _borrower,
        uint256 _downPayment
    ) internal {
        IWETH(wethAddress).transferFrom(_borrower, address(this), _downPayment);

        _unwrapWeth(_downPayment);
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
            "Incorrect down payment"
        );

        address paymentToken = _basicOrderParameters.considerationToken;
        require(paymentToken == ETH_ADDRESS, "Payment token must be ETH");

        uint256 bidId = _submitTellerV2Bid(_submitBidArgs, wethAddress);
        _acceptBidAndPurchaseNFT(
            _basicOrderParameters,
            bidId,
            _submitBidArgs.totalPurchasePrice,
            _submitBidArgs.downPayment,
            _submitBidArgs.lender
        );

        require(
            block.timestamp < _submitBidArgs.signatureExpiration,
            "Signature has expired"
        );

        _verifySignature(
            getTypeHash(
                _submitBidArgs,
                _basicOrderParameters.offerToken, // token contract address
                _basicOrderParameters.offerIdentifier, // token ID
                _basicOrderParameters.offerAmount, // quantity
                _submitBidArgs.totalPurchasePrice, // base price
                paymentToken
            ),
            _signature
        );

        bytes32 signatureHash = keccak256(_signature);
        require(!executedSignatures[signatureHash], "Signature already used");
        executedSignatures[signatureHash] = true;

        _payReferralFee(
            _submitBidArgs.principal,
            _submitBidArgs.referralAddress
        );
    }

    /**
     * @notice Returns the type of token for the order, ERC721 or ERC1155.
     * @param orderType The order type from the Seaport protocol
     * @param offerToken The nftContractAddress
     */
    function _fetchTokenTypeFromOrder(
        BasicOrderType orderType,
        address offerToken
    ) internal view returns (TokenType) {
        if (offerToken == cryptopunksMarketAddress) {
            return TokenType.PUNK;
        }

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

    function _escrowHasOwnershipOfAsset(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity,
        TokenType tokenType
    ) internal view virtual returns (bool) {
        return
            IEscrowBuyer(_getEscrowBuyerForTokenAddress(assetContractAddress))
                .hasOwnershipOfAsset(
                    assetContractAddress,
                    assetTokenId,
                    quantity,
                    tokenType
                );
    }

    /**
     * @notice Accepts a bid and purchases an NFT with loan funds.
     * @param _basicOrderParameters Details describing the NFT offer order.
     * @param _bidId The ID of the TellerV2 bid to create the loan from.
     * @param _purchasePrice The price of the NFT to purchase.
     * @param _lender The address of the lender that will fill the loan.
     */
    function _acceptBidAndPurchaseNFT(
        BasicOrderParameters calldata _basicOrderParameters,
        uint256 _bidId,
        uint256 _purchasePrice,
        uint256 _downPayment,
        address _lender
    ) internal {
        uint256 ethGainedFromAcceptBid = _acceptTellerV2Bid(_bidId, _lender);
        _purchaseNFT(_basicOrderParameters, _purchasePrice, _downPayment);

        _repayLoanWithExcess(
            _bidId,
            _purchasePrice,
            _downPayment,
            ethGainedFromAcceptBid
        );

        TokenType tokenType = _fetchTokenTypeFromOrder(
            _basicOrderParameters.basicOrderType,
            _basicOrderParameters.offerToken
        );

        _assignNftToLoan(
            _basicOrderParameters.offerToken,
            _basicOrderParameters.offerIdentifier,
            tokenType,
            _basicOrderParameters.offerAmount,
            _bidId
        );

        emit AssetPurchaseWithLoan(_bidId, _msgSender(), _lender);
    }

    /**
     * @notice Repays the TellerV2 Loan using excess funds.
     * @param _bidId The TellerV2 Loan Bid Id.
     * @param _purchasePrice The amount of ETH sent to the NFT market to purchase.
     * @param _downPayment The borrowers downpayment amount to purchase the NFT.
     * @param _ethGainedFromAcceptBid The amount of ETH gained from the TellerV2 loan.
     */
    function _repayLoanWithExcess(
        uint256 _bidId,
        uint256 _purchasePrice,
        uint256 _downPayment,
        uint256 _ethGainedFromAcceptBid
    ) internal {
        uint256 excessAmount = (_downPayment + _ethGainedFromAcceptBid) -
            _purchasePrice;

        if (excessAmount > 0) {
            _wrapWeth(excessAmount);

            //approve WETH for the repayment
            IWETH(wethAddress).approve(address(_tellerV2), excessAmount);

            ITellerV2(_tellerV2).repayLoan(_bidId, excessAmount);

            //Reset approval back to 0 as a safety measure so there are no dangling approvals
            IWETH(wethAddress).approve(address(_tellerV2), 0);
        }
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
        SubmitBidArgs calldata _submitBidArgs,
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 assetQuantity,
        uint256 totalPurchasePrice,
        address paymentToken
    ) public pure returns (bytes32) {
        return
            keccak256(
                bytes.concat( // concat to avoid stack too deep errors
                    abi.encode(
                        keccak256(
                            "inputs(address offerToken,uint256 offerIdentifier,uint256 offerAmount,uint256 totalPurchasePrice,address considerationToken,uint256 principal,uint256 downPayment,uint32 duration,uint16 interestRate,uint32 signatureExpiration)"
                        ),
                        assetContractAddress,
                        assetTokenId,
                        assetQuantity,
                        totalPurchasePrice,
                        paymentToken
                    ),
                    abi.encode(
                        _submitBidArgs.principal,
                        _submitBidArgs.downPayment,
                        _submitBidArgs.duration,
                        _submitBidArgs.interestRate,
                        _submitBidArgs.signatureExpiration
                    )
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
        bytes calldata _signature
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
    function _verifySignature(bytes32 typeHash, bytes calldata _signature)
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
    function _submitTellerV2Bid(
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
    function _acceptTellerV2Bid(uint256 bidId, address _lender)
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

        _unwrapWeth(wethGained);

        return wethGained;
    }

    /**
     * @notice Purchases an NFT using the Seaport protocol
     * @param _basicOrderParameters  Details describing the NFT offer order.
     * @param totalPurchasePrice Total amount of currency used as the msg.value for the nft purchase trnsaction.
     */
    function _purchaseNFT(
        BasicOrderParameters calldata _basicOrderParameters,
        uint256 totalPurchasePrice,
        uint256 downPayment
    ) internal virtual returns (bool purchased_) {
        uint256 additionalEthNeededToPurchase = (totalPurchasePrice -
            downPayment);

        bool fulfilled = IEscrowBuyer(
            _getEscrowBuyerForTokenAddress(_basicOrderParameters.offerToken)
        ).fulfillBasicOrderThrough{ value: totalPurchasePrice }(
            _basicOrderParameters
        );
        require(fulfilled, "NFT purchase failed");

        TokenType tokenType = _fetchTokenTypeFromOrder(
            _basicOrderParameters.basicOrderType,
            _basicOrderParameters.offerToken
        );

        bool isEscrowed = _escrowHasOwnershipOfAsset(
            _basicOrderParameters.offerToken,
            _basicOrderParameters.offerIdentifier,
            _basicOrderParameters.offerAmount,
            tokenType
        );
        require(isEscrowed, "Asset Receipt Invalid");

        return true;
    }

    /**
     * @notice Unwrap WETH into ETH
     * @param amt Amount to unwrap in wei.
     */
    function _unwrapWeth(uint256 amt) internal virtual returns (uint256) {
        IWETH(wethAddress).withdraw(amt);

        return amt;
    }

    /**
     * @notice Wrap WETH into ETH
     * @param amt Amount to unwrap in wei.
     */
    function _wrapWeth(uint256 amt) internal virtual returns (uint256) {
        IWETH(wethAddress).deposit{ value: amt }();

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
     * @notice Pay a percent of the fees that are being received by this contract to _feeRecipient.
     * @param _loanPrincipal  The principal of the loan so we can calculate amount of funds to send out.
     * @param _feeRecipient  The address that will receive funds.
     */
    function _payReferralFee(uint256 _loanPrincipal, address _feeRecipient)
        internal
        virtual
    {
        if (allowedFeeRecipients[_feeRecipient]) {
            //calculate how much this contract earned in fees

            uint256 amountToMarketplace = _loanPrincipal.percent(
                IMarketRegistry(_marketRegistry).getMarketplaceFee(marketId)
            );

            uint256 recipientReward = amountToMarketplace.percent(
                referralRewardPercent
            );

            //send 20 percent to the referrer
            IERC20(wethAddress).transferFrom(
                address(this),
                _feeRecipient,
                recipientReward
            );
        }
    }

    /**
     * @notice Allows an address to be a fee recipient.  Only callable by market owner.
     * @param _feeRecipient  The address to allow or disallow.
     * @param _allowed  allowed or disallowed from receiving funds as a referrer.
     */
    function setAllowedFeeRecipient(address _feeRecipient, bool _allowed)
        public
        onlyMarketOwner
    {
        allowedFeeRecipients[_feeRecipient] = _allowed;
        emit SetAllowedFeeRecipient(_feeRecipient, _allowed);
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

        address tokenAddress = escrowedTokensForLoan[bidId].tokenAddress;

        IEscrowBuyer(_getEscrowBuyerForTokenAddress(tokenAddress)).claimNFT(
            escrowedTokensForLoan[bidId].tokenAddress,
            escrowedTokensForLoan[bidId].tokenId,
            escrowedTokensForLoan[bidId].tokenType,
            escrowedTokensForLoan[bidId].amount,
            recipient
        );

        emit ClaimedAsset(
            bidId,
            recipient,
            tokenAddress,
            escrowedTokensForLoan[bidId].tokenId
        );
    }

    function _getEscrowBuyerForTokenAddress(address tokenAddress)
        internal
        view
        virtual
        returns (address)
    {
        if (tokenAddress == cryptopunksMarketAddress) {
            return cryptopunksEscrowBuyer;
        }

        return seaportEscrowBuyer;
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        //use ERC2771ContextUpgradeable._msgSender()
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        //use ERC2771ContextUpgradeable._msgSender()
        return super._msgData();
    }

    receive() external payable virtual {}
}