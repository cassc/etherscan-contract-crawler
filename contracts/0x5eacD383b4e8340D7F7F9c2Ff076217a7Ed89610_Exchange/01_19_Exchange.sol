import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../libraries/ECDSA.sol';

import '../Admin.sol';

import '../libraries/royalties.sol';
import '../royalties/IRoyaltyEngineV1.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

pragma experimental ABIEncoderV2;

interface Arbiter {
    function getToken(uint8 id) external returns (address, uint8);

    function getTokenAddress(uint8 id) external returns (address);
}

contract ExchangeAdmin is Admin {
    bytes32 public constant PURCHASER = keccak256('PURCHASER');
    modifier onlyPurchaser() {
        require(hasRole(PURCHASER, _msgSender()), 'sender must have the purchase role');
        _;
    }

    constructor() Admin(tx.origin) {}
}

error ExpiredOffer();
error InvalidNonce();
error CancelledOffer();
error InvalidSignature();
error SenderIsNotSigner();
error InvalidSender();
error OfferMustBeSale();

contract Exchange is ExchangeAdmin {
    using ECDSA for bytes32;
    using royalties for address;
    using SafeERC20 for IERC20;

    address public feeReceiver;
    address public royaltyRegistry;
    struct Offer {
        address signer;
        bytes32 nonce;
        uint256 tokenId;
        address contractAddress;
        uint256 price;
        uint256 quantity;
        uint256 expirationDate;
        ContractInterface contractInterface;
        bool isSeller;
        uint8 paymentType;
    }
    struct Actors {
        address buyer;
        address seller;
        address receiver;
    }

    enum ContractInterface {
        ERC1155,
        ERC721
    }

    event canceledOffer(bytes32 nonce, address signer);

    event completedOffer(bytes32 nonce, address signer, address counterParty, uint256 fee);

    mapping(address => mapping(bytes32 => bool)) public nonces;

    mapping(bytes32 => bool) public canceled;

    uint8 public paymentTokensAdded;

    uint256 public feePercentage = 100;
    uint256 public feeDecimals = 10000;
    address public paymentArbiter;

    constructor(address _paymentArbiter, address _registry) ExchangeAdmin() {
        paymentArbiter = _paymentArbiter;
        royaltyRegistry = _registry;
    }

    function getContractHash() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    function setFeeReceiver(address a) public isAdmin {
        feeReceiver = a;
    }

    function setPaymentArbiter(address a) public isAdmin {
        paymentArbiter = a;
    }

    function setFeePercentage(uint256 _feePercentage) public isAdmin {
        feePercentage = _feePercentage;
    }

    function setRoyaltyRegistry(address _registry) public isAdmin {
        royaltyRegistry = _registry;
    }

    function cancelOffer(Offer memory offer) public {
        if (_msgSender() != offer.signer) revert SenderIsNotSigner();
        bytes32 hashed = keccak256(abi.encode(offer));
        canceled[hashed] = true;
        emit canceledOffer(offer.nonce, offer.signer);
    }

    function getFee(uint256 price) public view returns (uint256) {
        return (price * feePercentage) / feeDecimals;
    }

    function validateOffer(Offer calldata offer, bytes calldata signature) internal {
        if (canceled[keccak256(abi.encode(offer))]) revert CancelledOffer();

        if (block.timestamp > offer.expirationDate) revert ExpiredOffer();

        if (nonces[offer.signer][offer.nonce]) revert InvalidNonce();
        nonces[offer.signer][offer.nonce] = true;

        if (!validateOfferSignature(offer, signature)) revert InvalidSignature();
    }

    function validateOfferSignature(Offer memory offer, bytes memory sig)
        public
        view
        returns (bool)
    {
        address signer = hashOffer(offer).toEthSignedMessageHash().recover(sig);

        bool valid = (signer == offer.signer);

        return valid;
    }

    function getOfferSigner(Offer memory offer, bytes memory sig) public view returns (address) {
        address signer = hashOffer(offer).toEthSignedMessageHash().recover(sig);

        return signer;
    }

    function hashOffer(Offer memory offer) public view returns (bytes32) {
        bytes32 hashedOffer = keccak256(abi.encode(offer));
        return keccak256(abi.encode(getContractHash(), hashedOffer));
    }

    function hashNIFTYOffer(Offer memory offer, address counterParty)
        public
        view
        returns (bytes32)
    {
        bytes32 nifty = keccak256(abi.encode(counterParty, abi.encode(offer)));
        return keccak256(abi.encode(getContractHash(), nifty));
    }

    function getNiftyOfferSigner(
        Offer memory sellOffer,
        address counterParty,
        bytes memory sig
    ) public view returns (address) {
        bytes32 niftyHash = hashNIFTYOffer(sellOffer, counterParty);
        address signer = niftyHash.toEthSignedMessageHash().recover(sig);
        return signer;
    }

    function validateNiftySignature(
        Offer memory offer,
        address counterParty,
        bytes memory sig
    ) public view returns (bool) {
        address signer = getNiftyOfferSigner(offer, counterParty, sig);
        return hasRole(SIGNER, signer);
    }

    function completeOffer(
        Offer calldata offer,
        bytes calldata signature,
        bytes calldata niftysSig
    ) external whenNotPaused {
        validateOffer(offer, signature);

        if (_msgSender() == offer.signer) revert InvalidSender();

        if (!validateNiftySignature(offer, _msgSender(), niftysSig)) revert InvalidSignature();

        address buyer = offer.isSeller ? _msgSender() : offer.signer;
        address seller = offer.isSeller ? offer.signer : _msgSender();

        uint256 fee = handleAssetTransfer(
            Actors(buyer, seller, buyer),
            offer.contractAddress,
            offer.tokenId,
            offer.contractInterface,
            offer.price,
            offer.paymentType,
            offer.quantity
        );
        emit completedOffer(offer.nonce, offer.signer, _msgSender(), fee);
    }

    function completePurchaseFor(
        Offer calldata offer,
        bytes calldata signature,
        address receiver
    ) external whenNotPaused onlyPurchaser {
        validateOffer(offer, signature);

        if (!offer.isSeller) revert OfferMustBeSale();
        address buyer = _msgSender();
        address seller = offer.signer;

        uint256 fee = handleAssetTransfer(
            Actors(buyer, seller, receiver),
            offer.contractAddress,
            offer.tokenId,
            offer.contractInterface,
            offer.price,
            offer.paymentType,
            offer.quantity
        );
        emit completedOffer(offer.nonce, offer.signer, _msgSender(), fee);
    }

    function handleAssetTransfer(
        Actors memory actors,
        address contractAddress,
        uint256 tokenId,
        ContractInterface contractInterface,
        uint256 price,
        uint8 paymentType,
        uint256 quantity
    ) internal returns (uint256) {
        uint256 fee = getFee(price);
        address feeToken = Arbiter(paymentArbiter).getTokenAddress(paymentType);

        uint256 royalty;
        bool success;

        if (royalties.checkRoyalties(ERC2981(contractAddress))) {
            (royalty, success) = contractAddress.royaltyTransferFrom(
                feeToken,
                actors.buyer,
                price,
                tokenId
            );
        } else {
            (royalty, success) = contractAddress.royaltyTransferFromRegistry(
                royalties.registryInput(price, tokenId, feeToken, royaltyRegistry, actors.buyer)
            );
        }

        if (success == false) {
            royalty = 0;
        }

        IERC20(feeToken).safeTransferFrom(actors.buyer, feeReceiver, fee);

        IERC20(feeToken).safeTransferFrom(actors.buyer, actors.seller, price - (fee + royalty));

        if (contractInterface == ContractInterface.ERC721) {
            IERC721(contractAddress).safeTransferFrom(actors.seller, actors.receiver, tokenId);
        }

        if (contractInterface == ContractInterface.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(
                actors.seller,
                actors.receiver,
                tokenId,
                quantity,
                ''
            );
        }

        return fee;
    }
}