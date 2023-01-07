//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "../interfaces/IClubrareMarketPlace.sol";
import "../interfaces/INFT.sol";

contract MarketplaceValidator is
    Initializable,
    IClubrareMarketplace,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    // Contract Name
    string public constant name = "Clubrare Marketplace";
    //Contract Version
    string public constant version = "1.0.1";
    // NOTE: these hashes are derived from keccak("CLUBRARE_MARKETPLACE_NAME") function
    //and verified in the constructor.
    //Contract Name hash
    bytes32 internal constant _NAME_HASH = 0xf555e867deda96ada315d27dde8710b83dfc4e2f5c9e0876ef5793912dd34009;
    //Contract Version Hash
    bytes32 internal constant _VERSION_HASH = 0xfc7f6d936935ae6385924f29da7af79e941070dafe46831a51595892abc1b97a;
    //Order Struct Hash
    bytes32 internal constant _ORDER_TYPEHASH = 0xd8c41470f0302fbc01702fe386d280faeb45d10b577ce71406f27d24efc3b489;
    //Bid Strcut Hash
    bytes32 internal constant _BID_TYPEHASH = 0x0539ae919312b6df6ee803473ef647a28045105ddae7e33738d7e063f4181776;

    //Derived Domain Separtor Hash Variable for EIP712 Domain Seprator
    bytes32 internal _domainSeparator;

    /* Blacklisted addresses */
    mapping(address => bool) public blacklist;

    mapping(address => bool) public adminContracts;

    /* Admins addresses */
    mapping(address => bool) public admins;

    /* Allowed ERC20 Payment tokens */
    mapping(address => bool) public allowedPaymenTokens;

    /* makertplace address for admins items */
    address public marketplace;

    address public cbrNFTAddress;

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(name, version);
        require(keccak256(bytes(name)) == _NAME_HASH, "name hash mismatch");
        require(keccak256(bytes(version)) == _VERSION_HASH, "version hash mismatch");
        require(
            keccak256(
                "Order(address seller,"
                "address contractAddress,"
                "uint256 royaltyFee,"
                "address royaltyReceiver,"
                "address paymentToken,"
                "uint256 basePrice,"
                "uint256 listingTime,"
                "uint256 expirationTime,"
                "uint256 nonce,"
                "uint256 tokenId,"
                "uint8 orderType,"
                "string uri,"
                "string objId,"
                "bool isTokenGated,"
                "address tokenGateAddress)"
            ) == _ORDER_TYPEHASH,
            "order hash mismatch"
        );
        require(
            keccak256(
                "Bid(address seller,"
                "address bidder,"
                "address contractAddress,"
                "address paymentToken,"
                "uint256 bidAmount,"
                "uint256 bidTime,"
                "uint256 expirationTime,"
                "uint256 nonce,"
                "uint256 tokenId,"
                "string objId)"
            ) == _BID_TYPEHASH,
            "bid hash mismatch"
        );
        _domainSeparator = _domainSeparatorV4();
    }

    /**
     * @dev Blacklist addresses to disable their trading
     */
    function excludeAddresses(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklist[_users[i]] = true;
            emit BlacklistUser(_users[i]);
        }
    }

    function setCBRNFTAddress(address _cbr) external onlyOwner {
        cbrNFTAddress = _cbr;
    }

    /**
     * @dev Add payment tokens to trade
     */
    function addPaymentTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedPaymenTokens[_tokens[i]] = true;
            emit AllowedPaymentToken(_tokens[i]);
        }
    }

    function addAdminContract(address[] calldata _tokenAddress) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            adminContracts[_tokenAddress[i]] = true;
        }
    }

    function addAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    function setMarketplaceAddress(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     * @notice This function is used to add address of admins
     * @dev Fuction take address type argument
     * @param admin The account address of admin
     */
    function addAdmin(address admin) public onlyOwner {
        require(!admins[admin], "admin already in list");
        admins[admin] = true;
        emit AdminAdded(admin, block.timestamp);
    }

    /**
     * @notice This function is used to get list of all address of admins
     * @dev This Fuction is not take any argument
     * @param admin The account address of admin
     */
    function removeAdmin(address admin) public onlyOwner {
        require(admins[admin], "not a admin");
        admins[admin] = false;
        emit AdminRemoved(admin, block.timestamp);
    }

    function isNFTHolder(address contractAddress, address user) public view returns (bool) {
        return INFT(contractAddress).balanceOf(user) > 0;
    }

    function verifySeller(Order calldata order, address _user) public view returns (bool) {
        (, address signer) = _verifyOrderSig(order);
        return admins[signer] ? admins[_user] : signer == _user;
    }

    function _verifyOrderSig(Order calldata order) public view returns (bytes32, address) {
        bytes32 digest = hashToSign(order);
        address signer = ECDSAUpgradeable.recover(digest, order.signature);
        return (digest, signer);
    }

    function _verifyBidSig(Bid calldata bid) public view returns (bytes32, address) {
        bytes32 digest = hashToSign(bid);
        address signer = ECDSAUpgradeable.recover(digest, bid.signature);
        return (digest, signer);
    }

    function onAuction(uint256 _time) external pure returns (bool) {
        return _time > 0;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param bid bidder signature hash
     * @param buyer bidder address
     * @param amount bid amount
     */

    function validateBid(
        Bid calldata bid,
        address buyer,
        uint256 amount
    ) public view returns (bool validated) {
        (, address _buyer) = _verifyBidSig(bid);
        if (_buyer != buyer) {
            return false;
        }
        if (amount != bid.bidAmount) {
            return false;
        }
        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param order Order to validate
     */
    function validateOrder(Order calldata order) public view returns (bool validated) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover 
        evaluation, which seems to happen even though it should short-circuit. */
        (, address signer) = _verifyOrderSig(order);
        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* recover via ECDSA, signed by seller (already verified as non-zero). */
        if (admins[signer] ? marketplace == order.seller : signer == order.seller) {
            return true;
        }
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order) internal pure returns (bool) {
        /* Order must have a maker. */
        if (order.seller == address(0)) {
            return false;
        }

        if (order.basePrice <= 0) {
            return false;
        }

        if (order.contractAddress == address(0)) {
            return false;
        }

        return true;
    }

    function hashOrder(Order memory _order) public pure returns (bytes32 hash) {
        bytes memory array = bytes.concat(
            abi.encode(
                _ORDER_TYPEHASH,
                _order.seller,
                _order.contractAddress,
                _order.royaltyFee,
                _order.royaltyReceiver,
                _order.paymentToken,
                _order.basePrice,
                _order.listingTime
            ),
            abi.encode(
                _order.expirationTime,
                _order.nonce,
                _order.tokenId,
                _order.orderType,
                keccak256(bytes(_order.uri)),
                keccak256(bytes(_order.objId)),
                _order.isTokenGated,
                _order.tokenGateAddress
            )
        );
        hash = keccak256(array);
        return hash;
    }

    /**
     * @dev Hash an bid, returning the canonical EIP-712 order hash without the domain separator
     * @param _bid Bid to hash
     * @return hash Hash of bid
     */
    function hashBid(Bid memory _bid) public pure returns (bytes32 hash) {
        bytes memory array = abi.encode(
            _BID_TYPEHASH,
            _bid.seller,
            _bid.bidder,
            _bid.contractAddress,
            _bid.paymentToken,
            _bid.bidAmount,
            _bid.bidTime,
            _bid.expirationTime,
            _bid.nonce,
            _bid.tokenId,
            keccak256(bytes(_bid.objId))
        );
        hash = keccak256(array);
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator, hashOrder(order)));
    }

    /**
     * @dev Hash an Bid, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param bid Bid to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Bid memory bid) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator, hashBid(bid)));
    }

    function checkTokenGate(Order calldata _order, address _user) public view {
        if (_order.isTokenGated) {
            require(INFT(_order.tokenGateAddress).balanceOf(_user) > 0, "not nft holder");
        }
    }
}