// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./OrderEIP712.sol";
import "./interfaces/IWETH.sol";

contract SwapTest is
Initializable,
OwnableUpgradeable,
ReentrancyGuardUpgradeable,
PausableUpgradeable,
IERC1271Upgradeable,
IERC1155ReceiverUpgradeable,
IERC721ReceiverUpgradeable
{
    using SafeMathUpgradeable for uint256;

    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

    bytes constant public VERSION = bytes("1");

    mapping(bytes32 => uint16) public dealsByHash;
    mapping(bytes32 => bool) public cancelled;
    mapping(address => bool) public operators;

    bool public isUniversalSwapActive;
    bool public isP2pSwapActive;

    uint256 public sellerFee;
    uint256 public buyerFee;

    IWETH public weth;

    bytes32 public DOMAIN_SEPARATOR;

    event ErrorHandled(bytes32 hash, string reason);

    event NewOrder(
        OrderEIP712.OrderSig order,
        bytes32 indexed orderHash
    );

    event ExecuteMatching(
        bytes32 indexed orderHash,
        uint256 tokenId,
        uint256 price,
        uint16 currentDeal,
        uint256 fee
    );

    event ExecuteP2PSwap(
        address indexed account,
        bytes32[] orderHash,
        uint256[][] tokensIds,
        uint256 buyerFee,
        uint256 sellerFee
    );

    event CancelOrder(
        address indexed account,
        bytes32 indexed orderHash
    );

    modifier onlyOperators() {
        require(operators[msg.sender], "Swap: access denied");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address wethAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        setupOperator(msg.sender, true);
        setWethAddress(wethAddress);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                OrderEIP712.EIP712DOMAIN_TYPEHASH,
                keccak256("Swap"),
                keccak256(VERSION),
                block.chainid,
                address(this)
            )
        );

        isUniversalSwapActive = true;
        isP2pSwapActive = true;
        sellerFee = 0;
        buyerFee = 0; // 200 - 20%; 20 - 2%; 2 - 0.2%
    }

    receive() external payable {}

    function pause() public whenNotPaused {
        _pause();
    }

    function unpause() public whenPaused {
        _unpause();
    }

    function setupFee(uint256 _sellerFee, uint256 _buyerFee) public onlyOwner {
        require(_sellerFee <= 20 && _buyerFee <= 20, 'Swap:fee too much. max 20 (2%)');

        sellerFee = _sellerFee;
        buyerFee = _buyerFee;
    }

    function setupOperator(address operator, bool access) public onlyOwner {
        operators[operator] = access;
    }

    function setWethAddress(address wethAddress) public onlyOwner {
        weth = IWETH(wethAddress);
    }

    function setIsUniversalSwapActive(bool isActive_) public onlyOwner {
        isUniversalSwapActive = isActive_;
    }

    function setIsP2pSwapActive(bool isActive_) public onlyOwner {
        isP2pSwapActive = isActive_;
    }

    function universalSwap(
        OrderEIP712.OrderSig calldata orderWithSig,
        address target,
        bytes memory callData,
        uint256 tokenId,
        uint256 tokenPrice
    ) public onlyOperators nonReentrant returns (bool success){
        uint256 startGas = gasleft();
        bytes32 orderHash = hashBySig(orderWithSig);

        require(isUniversalSwapActive, 'Swap:universalSwap deactivated');

        require(
            orderWithSig.swapType == OrderEIP712.SwapType.ANY ||
            orderWithSig.swapType == OrderEIP712.SwapType.EXTERNAL,
            'Swap:Wrong swap type'
        );

        validateOrder(orderWithSig, orderHash, /* ignore check gas price */ false);

        uint256 withdrawalEthGas = gasleft();
        getEthFrom(orderWithSig.signer, tokenPrice);
        uint256 transferGasUsage = withdrawalEthGas - gasleft();

        require(orderWithSig.price >= tokenPrice, "Swap:Wrong token price");
        require(target != address(0) && target != address(this) && target != address(weth), "Swap:Wrong target address");

        (success,) = target.call{value : tokenPrice}(callData);

        uint256 fee = 0;

        if (success) {
            transferTokenToSigner(
                orderWithSig.assetClass,
                orderWithSig.collection,
                tokenId,
                address(this),
                orderWithSig.signer,
                1
            );

            dealsByHash[orderHash]++;

            fee = tokenPrice.div(1000).mul(buyerFee);

            emitExecuteOrderEvent(orderWithSig, tokenId, tokenPrice, fee);

        } else {
            emit ErrorHandled(orderHash, "external market error");
            weth.deposit{value: tokenPrice}();
            weth.transfer(orderWithSig.signer, tokenPrice);
        }

        uint256 approxEthForGasUsageWithFee = (startGas - gasleft())
                                    .add(transferGasUsage)
                                    .mul(tx.gasprice)
                                    .add(fee);
        getEthFrom(orderWithSig.signer, approxEthForGasUsageWithFee);

        (bool transaferSuccess,) = msg.sender.call{value: approxEthForGasUsageWithFee}('');
        require(transaferSuccess, 'Swap:Transfer failed');
    }

    function p2pSwap(OrderEIP712.OrderSig[] calldata orders, uint256[][] calldata tokenIds) public nonReentrant payable  {
        require(isP2pSwapActive, 'Swap:p2pSwap deactivated');
        require(orders.length > 0 && orders.length == tokenIds.length, 'Swap:wrong items len.');

        bytes32[] memory hashes = new bytes32[](orders.length);
        uint256 sumOfExchange = 0;

        for (uint256 i = 0; i < orders.length; i++) {
            OrderEIP712.OrderSig calldata currentOrder = orders[i];
            bytes32 currentOrderHash = hashBySig(currentOrder);
            hashes[i] = currentOrderHash;

            require(
                currentOrder.swapType == OrderEIP712.SwapType.ANY ||
                currentOrder.swapType == OrderEIP712.SwapType.P2P,
                'Swap:Wrong swap type'
            );

            validateOrder(currentOrder, currentOrderHash, /* ignore check gas price */ true);

            require(
                tokenIds[i].length > 0 &&
                tokenIds[i].length <= currentOrder.maxNumberOfDeals - dealsByHash[currentOrderHash],
                'Swap: wrong tokens for order deals'
            );

            uint256 ethResult = 0;

            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                transferTokenToSigner(
                    currentOrder.assetClass,
                    currentOrder.collection,
                    tokenIds[i][j],
                    msg.sender,
                    currentOrder.signer,
                    1
                );

                ethResult += currentOrder.price;
                dealsByHash[currentOrderHash]++;
                uint256 currentOrderFee = currentOrder.price.div(1000).mul(buyerFee);

                emitExecuteOrderEvent(currentOrder, tokenIds[i][j], currentOrder.price, currentOrderFee);
            }

            uint256 fee = ethResult.div(1000).mul(buyerFee);
            sumOfExchange += ethResult;

            getEthFrom(currentOrder.signer, ethResult.add(fee));
        }

        uint256 sellerFeeActual = sumOfExchange.div(1000).mul(sellerFee);
        uint256 buyerFeeActual = sumOfExchange.div(1000).mul(buyerFee);

        require(sellerFeeActual == msg.value, 'Swap:wrong fee');

        (bool senderTransaferSuccess,) = msg.sender.call{value: sumOfExchange}(''); // send eth to seller
        require(senderTransaferSuccess, 'Swap:Sender transfer failed');

        (bool ownerTransaferSuccess,) = owner().call{value: sellerFeeActual.add(buyerFeeActual)}(''); // send all fee to owner
        require(ownerTransaferSuccess, 'Swap:Owner transfer failed');

        emit ExecuteP2PSwap(msg.sender, hashes, tokenIds, buyerFeeActual, sellerFeeActual);
    }

    function emitExecuteOrderEvent(OrderEIP712.OrderSig memory order, uint256 tokenId, uint256 price, uint256 fee) internal {
        bytes32 currentOrderHash = hashBySig(order);
        uint16 dealNumber = dealsByHash[currentOrderHash];

        if (dealNumber == 1) { // is new order
            emit NewOrder(order, currentOrderHash);
        }

        emit ExecuteMatching(
            currentOrderHash,
            tokenId,
            price,
            dealNumber,
            fee
        );
    }

    function cancelOrder(OrderEIP712.OrderSig calldata order) public {
        address signer = recoverSigner(order, DOMAIN_SEPARATOR);

        require(signer == order.signer && signer == msg.sender, 'Swap:Wrong signer!');

        bytes32 orderHash = hashBySig(order);

        require(!cancelled[orderHash], 'Swap:Order already canceled!');

        cancelled[orderHash] = true;

        emit CancelOrder(msg.sender, orderHash);
    }

    function transferTokenToSigner(
        bytes4 assetClass,
        address collection,
        uint256 tokenId,
        address from,
        address to,
        uint256 value
    ) internal {
        if (assetClass == ERC721_ASSET_CLASS) {
            require(IERC721Upgradeable(collection).ownerOf(tokenId) == from, "Swap:wrong owner of token");

            IERC721Upgradeable(collection).safeTransferFrom(from, to, tokenId);

        } else if (assetClass == ERC1155_ASSET_CLASS) {
            require(IERC1155Upgradeable(collection).balanceOf(from, tokenId) > 0, "Swap:wrong owner/count of token");

            IERC1155Upgradeable(collection).safeTransferFrom(
                from,
                to,
                tokenId,
                value,
                ""
            );
        }
    }

    function recoverSigner(
        OrderEIP712.OrderSig calldata _orderWithSig,
        bytes32 _domainSeparator
    ) public pure returns (address){
        return recoverSignerSimple(
            hashBySig(_orderWithSig),
            _orderWithSig.v,
            _orderWithSig.r,
            _orderWithSig.s,
            _domainSeparator
        );
    }

    function recoverSignerSimple(
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _domainSeparator
    ) public pure returns (address){
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparator, _hash));

        return ECDSAUpgradeable.recover(digest, _v, _r, _s);
    }

    function hashBySig(OrderEIP712.OrderSig memory order) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                OrderEIP712.ORDER_TYPEHASH_V1,
                order.nonce,
                order.signer,
                order.collection,
                order.price,
                order.maxGasPrice,
                order.maxNumberOfDeals,
                order.expiration,
                order.assetClass,
                uint8(order.swapType)
            )
        );
    }

    function hash(OrderEIP712.Order memory _order) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                OrderEIP712.ORDER_TYPEHASH_V1,
                _order.nonce,
                _order.signer,
                _order.collection,
                _order.price,
                _order.maxGasPrice,
                _order.maxNumberOfDeals,
                _order.expiration,
                _order.assetClass,
                uint8(_order.swapType)
            )
        );
    }

    function getEthFrom(address from, uint256 value) internal {
        weth.transferFrom(from, address(this), value);
        weth.withdraw(value);
    }

    function validateOrder(
        OrderEIP712.OrderSig calldata orderWithSig,
        bytes32 orderHash,
        bool ignoreCheckGas
    ) public whenNotPaused view {
        address signer = recoverSigner(orderWithSig, DOMAIN_SEPARATOR);

        require(cancelled[orderHash] == false, 'Swap:Order cancelled');

        require(
            orderWithSig.assetClass == ERC721_ASSET_CLASS || orderWithSig.assetClass == ERC1155_ASSET_CLASS,
            "Swap:wrong token type"
        );

        require(ignoreCheckGas || orderWithSig.maxGasPrice >= tx.gasprice, 'Swap:Wrong max of gas price!');
        require(
            dealsByHash[orderHash] < orderWithSig.maxNumberOfDeals ||
            orderWithSig.maxNumberOfDeals == 0,
            'Swap:Number of deals wrong'
        );
        require(signer == orderWithSig.signer, 'Swap:Wrong signer!');
        require(orderWithSig.expiration == 0 || orderWithSig.expiration > block.timestamp, "Swap:Order expired");
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) override public pure returns (bytes4 magicValue) {
        magicValue = IERC1271Upgradeable.isValidSignature.selector;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override public pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) override public pure returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) override public pure returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) override public pure returns (bool) {
        // todo should be check
        return true;
    }
}