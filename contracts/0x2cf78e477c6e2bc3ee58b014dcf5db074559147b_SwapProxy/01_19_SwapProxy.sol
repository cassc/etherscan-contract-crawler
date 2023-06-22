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
import "./storage/SilicaV2_1Storage.sol";

/**
 * @notice Swap Proxy
 * @author Alkimiya Team
 */
contract SwapProxy is EIP712, Ownable, ReentrancyGuard, ISwapProxy {
    mapping(bytes32 => bool) public buyOrdersCancelled;
    mapping(bytes32 => uint256) public buyOrderToConsumedBudget;

    mapping(bytes32 => bool) public sellOrdersCancelled;
    mapping(bytes32 => address) public sellOrderToSilica;

    ISilicaFactory private silicaFactory;

    function domainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    constructor(string memory name) EIP712(name, "1") {}

    function setSilicaFactory(address _silicaFactoryAddress) external override onlyOwner {
        silicaFactory = ISilicaFactory(_silicaFactoryAddress);
    }

    function fillBuyOrder(
        OrderLib.BuyOrder calldata buyerOrder,
        bytes memory buyerSignature,
        uint256 purchaseAmount,
        uint256 additionalCollateralPercent
    ) external override returns (address) {
        address sellerAddress = msg.sender; // msg.sender = address seller to fill this buy order

        bytes32 buyerOrderDigest = _hashTypedDataV4(OrderLib.getBuyOrderHash(buyerOrder));
        address _signerAddress = ECDSA.recover(buyerOrderDigest, buyerSignature);

        {
            require(buyOrderToConsumedBudget[buyerOrderDigest] + purchaseAmount <= buyerOrder.resourceAmount, "cannot exceed budget");
            require(block.timestamp <= buyerOrder.orderExpirationTimestamp, "order expired");
            require(buyOrdersCancelled[buyerOrderDigest] == false, "This order was cancelled");
            require(buyerOrder.signerAddress == _signerAddress, "invalid signature");
        }

        // create silica on behalf of seller
        address silicaAddress;
        {
            if (buyerOrder.commodityType == 2) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
                    buyerOrder.rewardToken,
                    buyerOrder.paymentToken,
                    purchaseAmount,
                    buyerOrder.endDay,
                    buyerOrder.unitPrice,
                    sellerAddress,
                    additionalCollateralPercent
                );
            } else if (buyerOrder.commodityType == 0) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                    buyerOrder.rewardToken,
                    buyerOrder.paymentToken,
                    purchaseAmount,
                    buyerOrder.endDay,
                    buyerOrder.unitPrice,
                    sellerAddress,
                    additionalCollateralPercent
                );
            } else {
                revert("invalid silica type");
            }

            buyOrderToConsumedBudget[buyerOrderDigest] += purchaseAmount;
        }

        uint256 reservedPrice = ISilicaV2_1(silicaAddress).getReservedPrice();

        if (buyerOrder.vaultAddress == address(0)) {
            emit BuyOrderFilled(silicaAddress, buyerOrderDigest, buyerOrder.signerAddress, sellerAddress, purchaseAmount);

            // Transfer pTokens from buyerAddress to here
            SafeERC20.safeTransferFrom(IERC20(buyerOrder.paymentToken), buyerOrder.signerAddress, address(this), reservedPrice);

            // Approves transfer from this contract to newly created Silica
            IERC20(buyerOrder.paymentToken).approve(silicaAddress, reservedPrice);

            // Silica pulls payment tokens from this contract
            ISilicaV2_1(silicaAddress).proxyDeposit(buyerOrder.signerAddress, reservedPrice);
        } else {
            emit BuyOrderFilled(silicaAddress, buyerOrderDigest, buyerOrder.vaultAddress, sellerAddress, purchaseAmount);
            require(ISilicaVault(buyerOrder.vaultAddress).getAdmin() == _signerAddress, "order not signed by admin");
            ISilicaVault(buyerOrder.vaultAddress).purchaseSilica(silicaAddress, reservedPrice);
        }

        return silicaAddress;
    }

    function routeBuy(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external override returns (address) {
        address buyerAddress = msg.sender;
        bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib.getSellOrderHash(sellerOrder));
        address _signerAddress = ECDSA.recover(sellerOrderDigest, sellerSignature);

        {
            require(sellOrdersCancelled[sellerOrderDigest] == false, "This order was cancelled");
            require(sellerOrder.signerAddress == _signerAddress, "invalid signature");
        }

        address silicaAddress = sellOrderToSilica[sellerOrderDigest];
        if (silicaAddress == address(0)) {
            require(block.timestamp <= sellerOrder.orderExpirationTimestamp, "order expired");

            if (sellerOrder.commodityType == 2) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else if (sellerOrder.commodityType == 0) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else {
                revert("invalid silica type");
            }

            // Event emitted only if silica is created first time
            emit SellOrderFilled(silicaAddress, sellerOrderDigest, sellerOrder.signerAddress, buyerAddress, amount);

            sellOrderToSilica[sellerOrderDigest] = silicaAddress;
        }

        uint256 reservedPrice =
            SilicaV2_1Storage(silicaAddress).reservedPrice() * amount / SilicaV2_1Storage(silicaAddress).resourceAmount();
        // Transfer pTokens from buyer (msg.sender) to newly created Silica
        SafeERC20.safeTransferFrom(IERC20(sellerOrder.paymentToken), buyerAddress, address(this), reservedPrice);

        // Approves transfer from this contract to newly created Silica
        IERC20(sellerOrder.paymentToken).approve(silicaAddress, reservedPrice);
        ISilicaV2_1(silicaAddress).proxyDeposit(buyerAddress, reservedPrice);

        return silicaAddress;
    }

    function fillSellOrder(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external override returns (address) {
        address buyerAddress = msg.sender;
        bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib.getSellOrderHash(sellerOrder));
        address _signerAddress = ECDSA.recover(sellerOrderDigest, sellerSignature);

        {
            require(sellOrderToSilica[sellerOrderDigest] == address(0), "order already filled");
            require(block.timestamp <= sellerOrder.orderExpirationTimestamp, "order expired");
            require(sellOrdersCancelled[sellerOrderDigest] == false, "This order was cancelled");
            require(sellerOrder.signerAddress == _signerAddress, "invalid signature");
        }

        // create silica on behalf signer
        address silicaAddress;
        {
            if (sellerOrder.commodityType == 2) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else if (sellerOrder.commodityType == 0) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else {
                revert("invalid silica type");
            }

            sellOrderToSilica[sellerOrderDigest] = silicaAddress;
        }

        emit SellOrderFilled(silicaAddress, sellerOrderDigest, sellerOrder.signerAddress, buyerAddress, amount);

        uint256 reservedPrice =
            SilicaV2_1Storage(silicaAddress).reservedPrice() * amount / SilicaV2_1Storage(silicaAddress).resourceAmount();
        // Transfer pTokens from buyer (msg.sender) to newly created Silica
        SafeERC20.safeTransferFrom(IERC20(sellerOrder.paymentToken), buyerAddress, address(this), reservedPrice);

        // Approves transfer from this contract to newly created Silica
        IERC20(sellerOrder.paymentToken).approve(silicaAddress, reservedPrice);
        ISilicaV2_1(silicaAddress).proxyDeposit(buyerAddress, reservedPrice);

        return silicaAddress;
    }

    function fillSellOrderAsVault(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount,
        address vaultAddress
    ) external override returns (address) {
        bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib.getSellOrderHash(sellerOrder));
        address _signerAddress = ECDSA.recover(sellerOrderDigest, sellerSignature);

        {
            require(sellOrderToSilica[sellerOrderDigest] == address(0), "order already filled");
            require(block.timestamp <= sellerOrder.orderExpirationTimestamp, "order expired");
            require(sellOrdersCancelled[sellerOrderDigest] == false, "This order was cancelled");
            require(sellerOrder.signerAddress == _signerAddress, "invalid signature");
            require(ISilicaVault(vaultAddress).getAdmin() == msg.sender, "only admin can fill order as vault");
        }

        // create silica on behalf of msg.sender (seller, who fills this order)
        address silicaAddress;
        {
            if (sellerOrder.commodityType == 2) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else if (sellerOrder.commodityType == 0) {
                silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                    sellerOrder.rewardToken,
                    sellerOrder.paymentToken,
                    sellerOrder.resourceAmount,
                    sellerOrder.endDay,
                    sellerOrder.unitPrice,
                    sellerOrder.signerAddress,
                    sellerOrder.additionalCollateralPercent
                );
            } else {
                revert("invalid silica type");
            }

            sellOrderToSilica[sellerOrderDigest] = silicaAddress;
        }

        emit SellOrderFilled(silicaAddress, sellerOrderDigest, sellerOrder.signerAddress, vaultAddress, amount);

        ISilicaVault(vaultAddress).purchaseSilica(silicaAddress, amount);

        return silicaAddress;
    }

    /// @notice Function to cancel a listed buy order
    function cancelBuyOrder(OrderLib.BuyOrder calldata order, bytes memory signature) external override {
        bytes32 orderHash = _hashTypedDataV4(OrderLib.getBuyOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "order cannot be cancelled");
        buyOrdersCancelled[orderHash] = true;
        emit BuyOrderCancelled(_signerAddress, orderHash);
    }

    /// @notice Function to cancel a listed sell order
    function cancelSellOrder(OrderLib.SellOrder calldata order, bytes memory signature) external override {
        bytes32 orderHash = _hashTypedDataV4(OrderLib.getSellOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "order cannot be cancelled");
        sellOrdersCancelled[orderHash] = true;
        emit SellOrderCancelled(_signerAddress, orderHash);
    }

    /// @notice Function to check if an order is canceled
    function isBuyOrderCancelled(bytes32 orderHash) external view override returns (bool) {
        return buyOrdersCancelled[orderHash];
    }

    function isSellOrderCancelled(bytes32 orderHash) external view override returns (bool) {
        return sellOrdersCancelled[orderHash];
    }

    /// @notice Function to return the Silica Address created from a buy order
    function getBudgetConsumedFromOrderHash(bytes32 orderHash) external view override returns (uint256) {
        return buyOrderToConsumedBudget[orderHash];
    }

    /// @notice Function to return the Silica Address created from a sell order
    function getSilicaAddressFromSellOrderHash(bytes32 orderHash) external view override returns (address) {
        return sellOrderToSilica[orderHash];
    }
}