pragma solidity 0.8.9;
// SPDX-License-Identifier: MIT

// Contracts
import "@teller-protocol/v2-contracts/contracts/TellerV2MarketForwarder.sol";
import "@teller-protocol/v2-contracts/contracts/TellerV2Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { BasicOrderParameters, BasicOrderType } from "./seaport/lib/ConsiderationStructs.sol";

// Interfaces
import "@teller-protocol/v2-contracts/contracts/interfaces/IMarketRegistry.sol";
import "@teller-protocol/v2-contracts/contracts/interfaces/ITellerV2.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBNPLMarket.sol";
import "./interfaces/IEscrowBuyer.sol";

contract BNPLMarket is
    Initializable,
    EIP712,
    ERC2771ContextUpgradeable,
    TellerV2MarketForwarder,
    IBNPLMarket
{
    using NumbersLib for uint256;

    address public immutable CRA_SIGNER;
    address public immutable wethAddress;
    address public immutable ETH_ADDRESS = address(0);

    string public constant CONTRACT_NAME = "Teller_BNPL_Market";
    string public constant CONTRACT_VERSION = "3.6"; //used for offchain signature domain separator

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
    AssetReceiptRegister private __assetReceiptRegister; //DEPRECATED

    //signature hash => has been executed
    mapping(bytes32 => bool) public executedSignatures;

    //bid ID -> discrete order
    //mapping(uint256 => DiscreteOrder) public discreteOrders;
    uint256 private __discreteOrders; // DEPRECATED

    address public cryptopunksMarketAddress;

    address public cryptopunksEscrowBuyer;
    address public seaportEscrowBuyer;

    string public upgradedToVersion; //used for the onUpgrade method alongside UPGRADE_VERSION

    //marketId => allowlist for fee recipients => true 
    mapping(uint256 => mapping(address => bool)) public allowedFeeRecipients;
     
    mapping(uint256 => uint16) referralRewardPercent;

    modifier onlyMarketOwner(uint256 marketId) {
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
        address borrower;
        address lender;
        uint256 totalPurchasePrice;
        uint256 principal;
        uint256 downPayment;
        uint32 duration;
        uint32 signatureExpiration;
        uint16 interestRate;
        string metadataURI;
        address referralAddress;
        uint256 marketId; 
    }

    event AssetPurchaseWithLoan(
        uint256 bidId,
        address indexed borrower,
        address indexed lender
    );

    event SetAllowedFeeRecipient(uint256 marketId, address _feeRecipient, bool allowed);

    event SetReferralReward(uint256 marketId, uint16 pct);

    event ClaimedAsset(
        uint256 indexed bidId,
        address recipient,
        address tokenContract,
        uint256 tokenId
    );

    /**
     * @notice Constructor for this contract.
     * @param _tellerV2 The address of the TellerV2 lending platform contract. 
     * @param _wethAddress The address of the Wrapped Ether contract.
     * @param _trustedForwarder The trusted forwarder contract for meta transactions.
     * @param _craSigner The public address of cra signer used to approve loans.
     */
    constructor(
        address _tellerV2,
        address _marketRegistry, 
        address _wethAddress,
        address _trustedForwarder,
        address _craSigner
    )
        TellerV2MarketForwarder(address(_tellerV2), address(_marketRegistry))
        EIP712(CONTRACT_NAME, CONTRACT_VERSION)
        ERC2771ContextUpgradeable(_trustedForwarder)
    {
        
        CRA_SIGNER = _craSigner;
        wethAddress = _wethAddress;
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
    function onUpgrade() external {
        require(
            keccak256(abi.encode(upgradedToVersion)) !=
                keccak256(abi.encode(CONTRACT_VERSION)),
            "already upgraded"
        );
        upgradedToVersion = CONTRACT_VERSION;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice The market owner can set the referralRewardPercent
     * @param _pct The proposed loan parameters
     */
     
    function setReferralRewardPercent(uint256 _marketId, uint16 _pct) public onlyMarketOwner(_marketId) {
        require(_pct <= 10000, "Must be no more than 100 percent");
        referralRewardPercent[_marketId] = _pct;
        emit SetReferralReward(_marketId,_pct);
    }


    /**
     * @notice Allows an address to be a fee recipient.  Only callable by market owner.
     * @param _feeRecipient  The address to allow or disallow.
     * @param _allowed  allowed or disallowed from receiving funds as a referrer.
     */
    function setAllowedFeeRecipient(uint256 _marketId, address _feeRecipient, bool _allowed)
        public
        onlyMarketOwner(_marketId)
    {
        allowedFeeRecipients[_marketId][_feeRecipient] = _allowed;
        emit SetAllowedFeeRecipient(_marketId,_feeRecipient, _allowed);
    }

    function getPaymentToken(address considerationToken ) internal view returns (address) {

        if(considerationToken == ETH_ADDRESS){
            return wethAddress;
        }

        return considerationToken;
    }
 
    /**
     * @notice Transfer weth downpayment from the borrower into this contract so it can be used to purchase NFT immediately.
     * @param _borrower The loan borrower for BNPL
     * @param _downPayment The amount of money down
     */

    function _collectDownpayment(address paymentToken, address _borrower, uint256 _downPayment)
        internal
    {
        IERC20(paymentToken).transferFrom(_borrower, address(this), _downPayment);
        
        if(paymentToken == wethAddress){           
            _unwrapWeth(_downPayment);
        } 
        
    }
    /**
     * @notice Takes out a loan using TellerV2 and uses the funds to purchase an NFT asset and escrow it within this contract until the loan is finalized.
     * @param _submitBidArgs Details describing the loan agreement
     * @param _basicOrderParameters Details describing the NFT offer order.
     * @param _signatureFromBorrower The signature from the borrower that approves this new loan
     */
    function executeUsingOffchainSignatures(
        SubmitBidArgs calldata _submitBidArgs,
        BasicOrderParameters calldata _basicOrderParameters,
        bytes calldata _signatureFromBorrower,
        bytes calldata _signatureFromLender
    ) public {
        require(
            block.timestamp < _submitBidArgs.signatureExpiration,
            "Offer has expired"
        );

        bytes32 sigTypehash = getTypeHash(
            _submitBidArgs,
            _basicOrderParameters.offerToken, // token contract address
            _basicOrderParameters.offerIdentifier, // token ID
            _basicOrderParameters.offerAmount, // quantity
            _submitBidArgs.totalPurchasePrice, // base price
            _basicOrderParameters.considerationToken //make sure the payment token type was signed properly
        );

        address paymentToken = getPaymentToken(_basicOrderParameters.considerationToken);

        //if the tx signer is not the borrower, we need an offchain approval from the borrower for this order
        if (_msgSender() != _submitBidArgs.borrower) {
            _verifySignature(
                sigTypehash,
                _signatureFromBorrower,
                _submitBidArgs.borrower
            );
        }

        //if the tx signer is not the lender, we need an offchain approval from the lender for this order
        if (_msgSender() != _submitBidArgs.lender) {
            _verifySignature(
                sigTypehash,
                _signatureFromLender,
                _submitBidArgs.lender
            );
        }

        //perform the BNPL
        _collectDownpayment(
            paymentToken,
            _submitBidArgs.borrower,
            _submitBidArgs.downPayment
            
        );

        uint256 bidId = _submitTellerV2Bid(
            _submitBidArgs,
            paymentToken,
            _submitBidArgs.borrower //the bid submitter becomes the borrower and downpayment is taken
        );
        _acceptBidAndPurchaseNFT(
            _basicOrderParameters,
            bidId,
            _submitBidArgs.totalPurchasePrice,
            _submitBidArgs.downPayment,
            _submitBidArgs.lender
        );

        _payReferralFee(
            _submitBidArgs.marketId,
            paymentToken,
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
            orderType >= BasicOrderType.ERC20_TO_ERC721_FULL_OPEN &&
            orderType <= BasicOrderType.ERC20_TO_ERC721_PARTIAL_RESTRICTED
        ) {
            return TokenType.ERC721;
        }

        if (
            orderType >= BasicOrderType.ETH_TO_ERC1155_FULL_OPEN &&
            orderType <= BasicOrderType.ETH_TO_ERC1155_PARTIAL_RESTRICTED
        ) {
            return TokenType.ERC1155;
        }


        if (
            orderType >= BasicOrderType.ERC20_TO_ERC1155_FULL_OPEN &&
            orderType <= BasicOrderType.ERC20_TO_ERC1155_PARTIAL_RESTRICTED
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

        address paymentToken = getPaymentToken(_basicOrderParameters.considerationToken);
 

        uint256 tokensGainedFromAcceptBid = _acceptTellerV2Bid(_bidId, _lender, paymentToken);
        _purchaseNFT(_basicOrderParameters, _purchasePrice, _downPayment);

        uint256 excessAmount = (_downPayment + tokensGainedFromAcceptBid) - _purchasePrice;

        require (excessAmount == 0, "Excess currency from accept bid");

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
                            "inputs(address offerToken,uint256 offerIdentifier,uint256 offerAmount,uint256 totalPurchasePrice,address considerationToken,uint256 principal,uint256 downPayment,uint32 duration,uint16 interestRate,uint32 signatureExpiration,uint256 marketId)"
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
                        _submitBidArgs.signatureExpiration,
                        _submitBidArgs.marketId
                    )
                )
            );
    }

    /**
     * @notice Returns true if and only if the EIP712 signature is valid for the typehash and domain separator.
     * @param _typeHash The hash including the loan and NFT details.
     * @param _signature The EIP712 signature from the CRA Server.
     * @param _expectedSigner The address to expect after recovering the signature address.
     */
    function _verifySignature(bytes32 _typeHash, bytes calldata _signature, address _expectedSigner) internal {
        bytes32 sigHash = keccak256(_signature);
        require(
            !executedSignatures[sigHash],
            "Signature already used"
        );
        executedSignatures[sigHash] = true;

        address signer = ECDSA.recover(_hashTypedDataV4(_typeHash), _signature);
        require(signer == _expectedSigner, "invalid signature");
    }

    /**
     * @notice Creates a new loan using the TellerV2 lending protocol.
     * @param _submitBidArgs Details describing the loan agreement.
     * @param _lendingToken The address of the currency used for the new loan.
     * @param _borrower The address of the borrower who is taking out the loan.
     */
    function _submitTellerV2Bid(
        SubmitBidArgs memory _submitBidArgs,
        address _lendingToken,
        address _borrower
    ) internal virtual returns (uint256 bidId) {
        bytes memory responseData;

        responseData = _forwardCall(
            abi.encodeWithSelector(
                ITellerV2.submitBid.selector,
                _lendingToken,
                _submitBidArgs.marketId,
                _submitBidArgs.principal,
                _submitBidArgs.duration,
                _submitBidArgs.interestRate,
                _submitBidArgs.metadataURI,
                // Ensure the receiver of the loan funds is this contract
                address(this)
            ),
            _borrower
        );

        return abi.decode(responseData, (uint256));
    }

    /**
     * @notice Accepts a new loan using the TellerV2 lending protocol.
     * @param bidId The id of the new loan.
     * @param _lender The address of the lender who will provide funds for the new loan.
     */
    function _acceptTellerV2Bid(uint256 bidId, address _lender, address paymentToken)
        internal
        virtual
        returns (uint256)
    {
        bytes memory responseData;
     
        // Approve the borrower's loan
        responseData = _forwardCall(
            abi.encodeWithSelector(ITellerV2.lenderAcceptBid.selector, bidId),
            _lender
        );

        (uint256 amountToProtocol, uint256 amountToMarketplace, uint256 tokensGained) = 
        abi.decode(responseData, (uint256,uint256,uint256));

        if(paymentToken == wethAddress){           
            _unwrapWeth(tokensGained);
        } 

        return tokensGained;
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
       
       
        address paymentToken = getPaymentToken(_basicOrderParameters.considerationToken);

        address escrowBuyer = _getEscrowBuyerForTokenAddress(_basicOrderParameters.offerToken);
        bool fulfilled; 

        if(paymentToken == wethAddress){
            fulfilled = IEscrowBuyer(
                escrowBuyer
            ).fulfillBasicOrderWithEth{ value: totalPurchasePrice }(
                _basicOrderParameters
            );
        }else{

            IERC20(paymentToken).transfer(escrowBuyer, totalPurchasePrice);

            fulfilled = IEscrowBuyer(
               escrowBuyer
              ).fulfillBasicOrderWithToken(
                _basicOrderParameters, totalPurchasePrice
            );
        }
        
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
    function _payReferralFee(uint256 _marketId, address _paymentToken, uint256 _loanPrincipal, address _feeRecipient)
        internal
        virtual
    {
        if (allowedFeeRecipients[_marketId][_feeRecipient]) {
            //calculate how much this contract earned in fees

            uint256 amountToMarketplace = _loanPrincipal.percent(
                IMarketRegistry(_marketRegistry).getMarketplaceFee(_marketId)
            );

            uint256 recipientReward = amountToMarketplace.percent(
                referralRewardPercent[_marketId]
            );

            if(IERC20(_paymentToken).balanceOf(address(this)) >= recipientReward){

                //send 20 percent to the referrer
                IERC20(_paymentToken).transferFrom(
                    address(this),
                    _feeRecipient,
                    recipientReward
                );
            }
        }
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