// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/silicaFactory/ISilicaFactory.sol";
import "./interfaces/silica/ISilicaV2_1.sol";
import "./libraries/OrderLib.sol";
import "./interfaces/silicaVault/ISilicaVault.sol";
import "./interfaces/swapProxy/ISwapProxy.sol";

/**
 * @notice Swap Proxy
 * @author Alkimiya Team
 */
contract SwapProxy is EIP712, Ownable, ReentrancyGuard, ISwapProxy {
    mapping(bytes32 => uint256) public totalInvested;
    mapping(bytes32 => bool) public cancelled;
    mapping(bytes32 => address) public silicaCreated;

    ISilicaFactory private silicaFactory;

    function domainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    constructor(string memory name) EIP712(name, "1") {}

    function setSilicaFactory(address _silicaFactoryAddress) external override onlyOwner {
        silicaFactory = ISilicaFactory(_silicaFactoryAddress);
    }

    /// @notice Function to match Buyer order and Seller order and fulfill a silica
    function executeOrder(
        OrderLib.Order calldata buyerOrder,
        OrderLib.Order calldata sellerOrder,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) external override returns (address) {
        bytes32 buyerOrderHash = _hashTypedDataV4(OrderLib.getOrderHash(buyerOrder));
        bytes32 sellerOrderHash = _hashTypedDataV4(OrderLib.getOrderHash(sellerOrder));
        validateOrder(buyerOrder, buyerOrderHash, sellerOrder, sellerOrderHash, buyerSignature, sellerSignature);

        checkIfOrderMatches(buyerOrder, sellerOrder);

        // create silica
        address silicaAddress = executeCreateSilica(sellerOrder, sellerOrderHash);

        uint256 reservedPrice = ISilicaV2_1(silicaAddress).getReservedPrice();
        uint256 totalPaymentAmount = reservedPrice < buyerOrder.amount ? reservedPrice : buyerOrder.amount; // @review: there is room for imporvement here
        uint256 amountLeftToFillInSilica = reservedPrice - IERC20(sellerOrder.paymentToken).balanceOf(silicaAddress);

        require(buyerOrder.amount >= totalInvested[buyerOrderHash] + totalPaymentAmount, "buyer order payment amount too low");
        require(totalPaymentAmount <= amountLeftToFillInSilica, "seller order amount too low");

        OrderLib.OrderFilledData memory orderData;

        orderData.silicaContract = silicaAddress;
        orderData.buyerOrderHash = buyerOrderHash;
        orderData.sellerOrderHash = sellerOrderHash;
        orderData.buyerAddress = buyerOrder.buyerAddress;
        orderData.sellerAddress = sellerOrder.sellerAddress;
        orderData.unitPrice = sellerOrder.unitPrice;
        orderData.endDay = sellerOrder.endDay;
        orderData.totalPaymentAmount = totalPaymentAmount;
        orderData.reservedPrice = reservedPrice;

        totalInvested[buyerOrderHash] += totalPaymentAmount;
        emit OrderExecuted(orderData);
        if (buyerOrder.orderType == 1) {
            SafeERC20.safeTransferFrom(IERC20(sellerOrder.paymentToken), buyerOrder.buyerAddress, address(this), totalPaymentAmount);
            IERC20(sellerOrder.paymentToken).approve(silicaAddress, totalPaymentAmount);
            ISilicaV2_1(silicaAddress).proxyDeposit(buyerOrder.buyerAddress, totalPaymentAmount);
        } else if (buyerOrder.orderType == 2) {
            ISilicaVault(buyerOrder.buyerAddress).purchaseSilica(silicaAddress, totalPaymentAmount);
        }
        return silicaAddress;
    }

    /// @notice Function to cancel a listed order
    function cancelOrder(OrderLib.Order calldata order, bytes memory signature) external override {
        bytes32 orderHash = _hashTypedDataV4(OrderLib.getOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "order cannot be cancelled");
        cancelled[orderHash] = true;
        emit OrderCancelled(order.buyerAddress, order.sellerAddress, orderHash);
    }

    /// @notice Function to return how much a order has been fulfilled
    function getOrderFill(bytes32 orderHash) external view override returns (uint256 fillAmount) {
        address silicaAddress = silicaCreated[orderHash];
        if (silicaAddress != address(0)) {
            fillAmount = IERC20(ISilicaV2_1(silicaAddress).getPaymentToken()).balanceOf(silicaAddress);
        } else {
            return totalInvested[orderHash];
        }
    }

    /// @notice Function to check if an order is canceled
    function isOrderCancelled(bytes32 orderHash) external view override returns (bool) {
        return cancelled[orderHash];
    }

    /// @notice Function to return the Silica Address created from an order
    function getSilicaAddress(bytes32 orderHash) external view override returns (address) {
        return silicaCreated[orderHash];
    }

    /// @notice Function to check if a seller order matches a buyer order
    function checkIfOrderMatches(OrderLib.Order calldata buyerOrder, OrderLib.Order calldata sellerOrder) public pure override {
        require(buyerOrder.unitPrice >= sellerOrder.unitPrice, "unit price does not match");
        require(buyerOrder.paymentToken == sellerOrder.paymentToken, "payment token does not match");
        require(buyerOrder.rewardToken == sellerOrder.rewardToken, "reward token does not match");
        require(buyerOrder.silicaType == sellerOrder.silicaType, "silica type does not match");
        require(buyerOrder.endDay >= sellerOrder.endDay, "end day does not match");
    }

    /// @notice Internal function to fulfill a matching pair of seller and buyer order
    function executeCreateSilica(OrderLib.Order calldata sellerOrder, bytes32 orderHash) internal returns (address silicaAddress) {
        // check if silica has been created already
        if (silicaCreated[orderHash] != address(0)) {
            return silicaCreated[orderHash];
        }
        if (sellerOrder.silicaType == 2) {
            // ETh Staking
            silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
                sellerOrder.rewardToken,
                sellerOrder.paymentToken,
                sellerOrder.amount,
                sellerOrder.endDay,
                sellerOrder.unitPrice,
                sellerOrder.sellerAddress
            );
        } else if (sellerOrder.silicaType == 0) {
            // WETH, WBTC, WAVAX
            silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                sellerOrder.rewardToken,
                sellerOrder.paymentToken,
                sellerOrder.amount,
                sellerOrder.endDay,
                sellerOrder.unitPrice,
                sellerOrder.sellerAddress
            );
        }

        require(silicaAddress != address(0), "silica cannot be created");

        silicaCreated[orderHash] = silicaAddress;
    }

    /// @notice Internal function fo validate an order's signature
    function validateOrderSignature(
        OrderLib.Order calldata _order,
        bytes32 orderHash,
        bytes memory signature
    ) internal view {
        if (_order.orderExpirationTimestamp != 0) {
            require(block.timestamp <= _order.orderExpirationTimestamp, "order expired");
        }
        require(cancelled[orderHash] == false, "This order was cancelled");

        address _signerAddress = ECDSA.recover(orderHash, signature);
        if (_order.orderType == 0) {
            require(_order.sellerAddress == _signerAddress, "order not signed by the seller");
        } else if (_order.orderType == 1) {
            require(_order.buyerAddress == _signerAddress, "order not signed by the buyer");
        } else if (_order.orderType == 2) {
            require(ISilicaVault(_order.buyerAddress).getAdmin() == _signerAddress, "order not signed by admin of the HashVault");
        } else {
            revert("invalid orderType");
        }
    }

    /// @notice Internal function fo validate an order's signature
    function validateOrder(
        OrderLib.Order calldata buyerOrder,
        bytes32 buyerOrderHash,
        OrderLib.Order calldata sellerOrder,
        bytes32 sellerOrderHash,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) internal view {
        require(buyerOrder.orderType == 1 || buyerOrder.orderType == 2, "not a buyer order");
        require(sellerOrder.orderType == 0, "not a seller order");

        validateOrderSignature(sellerOrder, sellerOrderHash, sellerSignature);
        validateOrderSignature(buyerOrder, buyerOrderHash, buyerSignature);
    }
}