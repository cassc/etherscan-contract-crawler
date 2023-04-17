pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ENSRegistry {
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function available(uint256 tokenId) external view returns (bool);
}

contract ExchangeENS is OwnableUpgradeable {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /* An order, convenience struct. */
    struct Order {
        /* Order maker address. */
        address maker;
        /* Whether this order is erc721 or payment */
        bool isErc20Offer;
        /* Order tokenId for the domain */
        uint256 tokenId;
        /* Order asset contract */
        address currencyContract;
        /* Amount for any other erc20 */
        uint256 amount;
        /* Order nonce. To cancel all orders from a user */
        uint256 nonce;
        /* Listing nonce. To cancel listings for tokenId */
        uint256 listingNonce;
        /* Offer nonce. To cancel offers for tokenId and user */
        uint256 offerNonce;
        /* Order listing timestamp. */
        uint listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint salt;
    }

    event OrdersMatched(bytes32 firstHash, bytes32 secondHash, address indexed firstMaker, address indexed secondMaker);
    event OrderCanceled(bytes32 orderHash, address orderMaker);
    event ListingsForTokenCanceled(uint256 tokenId);
    event OffersForTokenByUserCanceled(uint256 tokenId, address offerMaker);
    event MakerBlacklistUpdate(address maker, bool isBlacklisted);

    string public constant name = 'Eternal Digital Exchange';

    string public constant version = '1.0';

    string public constant codename = 'Amalgamon';

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            'Order(address maker,bool isErc20Offer,uint256 tokenId,address currencyContract,uint256 amount,uint256 nonce,uint256 listingNonce,uint256 offerNonce,uint256 listingTime,uint256 expirationTime,uint256 salt)'
        );

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

    bytes32 DOMAIN_SEPARATOR;

    bool reentrancyLock;

    mapping(bytes32 => bool) public doneOrders;
    mapping(address => uint256) public nonce;
    mapping(uint256 => uint256) public listingNonce;
    mapping(uint256 => mapping(address => uint256)) public offerNonce;

    mapping(address => bool) public allowedCurrencies;

    ENSRegistry public tokenAddress;

    uint256 public constant royaltyPercentageDenominator = 10000;
    uint256 public royaltyBasisPoints;
    address public royaltyAddress;

    mapping(address => bool) public makerBlacklist;
    mapping(address => bool) public isAdmin;

    function initialize(
        address _tokenAddress,
        uint256 _chainId,
        address _royaltyAddress,
        uint256 _royaltyBasisPoints
    ) public initializer {
        tokenAddress = ENSRegistry(_tokenAddress);
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
        reentrancyLock = false;
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({name: name, version: version, chainId: _chainId, verifyingContract: address(this)})
        );
        __Ownable_init();
    }

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        require(!reentrancyLock, 'Reentrancy detected');
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) external onlyOwner {
        require(
            _royaltyBasisPoints <= royaltyPercentageDenominator,
            'Royalty basis points are greater than royalty denominator'
        );
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setAllowedCurrency(address _currencyAddress, bool _allowed) external onlyOwner {
        allowedCurrencies[_currencyAddress] = _allowed;
    }

    function cancelAllOrders() public {
        nonce[msg.sender]++;
    }

    function cancelAllListings(uint256 tokenId) public {
        require(tokenAddress.ownerOf(tokenId) == msg.sender, "You don't own the token");
        _cancelAllListings(tokenId);
    }

    function _cancelAllListings(uint256 tokenId) internal {
        listingNonce[tokenId]++;
        emit ListingsForTokenCanceled(tokenId);
    }

    function cancelAllOffersForTokenId(uint256 tokenId) public {
        _cancelAllOffersForTokenId(tokenId, msg.sender);
    }

    function _cancelAllOffersForTokenId(uint256 tokenId, address maker) internal {
        offerNonce[tokenId][maker]++;
        emit OffersForTokenByUserCanceled(tokenId, maker);
    }

    /* TODO: make it receive only hash to use less gas */
    function cancelOrder(Order memory order) public {
        require(order.maker == msg.sender, 'Canceling another user order prohibited');
        bytes32 orderHash = hashOrder(order);
        doneOrders[orderHash] = true;
        emit OrderCanceled(orderHash, order.maker);
    }

    function hashOrder(Order memory order) public pure returns (bytes32 hash) {
        /* Per EIP 712. */
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.isErc20Offer,
                    order.tokenId,
                    order.currencyContract,
                    order.amount,
                    order.nonce,
                    order.listingNonce,
                    order.offerNonce,
                    order.listingTime,
                    order.expirationTime,
                    order.salt
                )
            );
    }

    function hashToSign(bytes32 orderHash) public view returns (bytes32 hash) {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, orderHash));
    }

    function exists(address what) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function validateOrderParameters(Order memory order, bytes32 hash) public view returns (bool) {
        /* Order must be listed and not be expired. */
        if (
            order.listingTime > block.timestamp ||
            (order.expirationTime != 0 && order.expirationTime <= block.timestamp)
        ) {
            return false;
        }

        if (order.nonce < nonce[order.maker]) {
            return false;
        }

        if (tokenAddress.available(order.tokenId)) {
            return false;
        }

        /* Order must not have already been completed. */
        if (doneOrders[hash]) {
            return false;
        }

        if (makerBlacklist[order.maker]) {
            return false;
        }

        return true;
    }

    function setIsAdmin(address _address, bool _isAdmin) external onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function banUser(address user) external {
        require(isAdmin[msg.sender], 'Only admin can ban user');
        makerBlacklist[user] = true;
        emit MakerBlacklistUpdate(user, true);
    }

    function unbanUser(address user) external {
        require(isAdmin[msg.sender], 'Only admin can unban user');
        makerBlacklist[user] = false;
        emit MakerBlacklistUpdate(user, false);
    }

    function validateOrderAuthorization(
        bytes32 hash,
        address maker,
        bytes memory signature
    ) public view returns (bool) {
        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);
        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        /* (d.2): New way: order hash signed by maker using sign_typed_data */
        if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
            return true;
        }
        return false;
    }

    /* first order always domain, second order always payment */
    function atomicMatch(
        Order memory firstOrder,
        Order memory secondOrder,
        bytes memory firstSignature,
        bytes memory secondSignature
    ) public payable reentrancyGuard {
        /* CHECKS */
        require(firstOrder.maker != secondOrder.maker, "Can't order from yourself");
        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);
        /* Check first order validity. */
        require(validateOrderParameters(firstOrder, firstHash), 'First order has invalid parameters');
        require(!firstOrder.isErc20Offer, 'First order is not domain order');
        require(firstOrder.listingNonce == listingNonce[firstOrder.tokenId], 'Listing has been cancelled');

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);
        /* Check second order validity. */
        require(validateOrderParameters(secondOrder, secondHash), 'Second order has invalid parameters');
        require(secondOrder.isErc20Offer, 'Second order is not payment order');
        require(
            secondOrder.offerNonce == offerNonce[secondOrder.tokenId][secondOrder.maker],
            'Offers have been cancelled'
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, 'Self-matching orders is prohibited');

        /* Check first order authorization. */
        require(
            validateOrderAuthorization(firstHash, firstOrder.maker, firstSignature),
            'First order failed authorization'
        );

        /* Check second order authorization. */
        require(
            validateOrderAuthorization(secondHash, secondOrder.maker, secondSignature),
            'Second order failed authorization'
        );

        require(allowedCurrencies[firstOrder.currencyContract], 'Currency not allowed');
        require(firstOrder.tokenId == secondOrder.tokenId, 'Orders token id missmatch');
        require(firstOrder.currencyContract == secondOrder.currencyContract, 'Orders currency contract missmatch');
        require(firstOrder.amount == secondOrder.amount, 'Supplied less than required');

        /* INTERACTIONS */

        uint256 royaltyAmount = (firstOrder.amount * royaltyBasisPoints) / royaltyPercentageDenominator;
        uint256 orderAmount = firstOrder.amount - royaltyAmount;

        if (firstOrder.currencyContract == address(0)) {
            /* Reentrancy prevented by reentrancyGuard modifier */
            require(firstOrder.amount == msg.value, 'Supplied less than required');

            if (royaltyAmount > 0) {
                require(royaltyAddress != address(0));
                (bool success, ) = royaltyAddress.call{value: royaltyAmount}('');
                require(success, 'native token transfer failed.');
            }

            if (orderAmount > 0) {
                (bool success, ) = firstOrder.maker.call{value: orderAmount}('');
                require(success, 'native token transfer failed.');
            }
        } else {
            /* Execute first call, assert success. */

            IERC20 paymentContractAddress = IERC20(secondOrder.currencyContract);
            if (royaltyAmount > 0) {
                require(royaltyAddress != address(0));
                require(
                    paymentContractAddress.transferFrom(secondOrder.maker, royaltyAddress, royaltyAmount),
                    'Payment for asset failed. royalties'
                );
            }

            if (orderAmount > 0) {
                require(
                    paymentContractAddress.transferFrom(secondOrder.maker, firstOrder.maker, orderAmount),
                    'Payment for asset failed'
                );
            }
        }
        /* Execute second call, assert success. */
        require(
            tokenAddress.ownerOf(firstOrder.tokenId) == firstOrder.maker,
            'FirstOrder maker is not the owner of domain'
        );
        tokenAddress.transferFrom(firstOrder.maker, secondOrder.maker, firstOrder.tokenId);

        doneOrders[firstHash] = true;
        doneOrders[secondHash] = true;
        _cancelAllListings(firstOrder.tokenId);
        _cancelAllOffersForTokenId(secondOrder.tokenId, secondOrder.maker);
        /* LOGS */

        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, firstOrder.maker, secondOrder.maker);
    }
}