/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/silicaFactory/ISilicaFactory.sol";
import "./interfaces/silicaVault/ISilicaVault.sol";
import "./interfaces/swapProxy/ISwapProxy.sol";
import "./interfaces/silica/ISilicaV2_1.sol";
import "./storage/SilicaV2_1Storage.sol";
import "./libraries/OrderLib.sol";

/**
 * @title  Swap Proxy
 * @author Alkimiya Team
 * @notice This contract fills orders on behalf of users
 */
contract SwapProxy is EIP712, Ownable2Step, ISwapProxy {

    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 orderHash => bool isCancelled) public buyOrdersCancelled;
    mapping(bytes32 orderHash => uint256 consumedBudget) public buyOrderToConsumedBudget;

    mapping(bytes32 orderHash => bool isCancelled) public sellOrdersCancelled;
    mapping(bytes32 orderHash => address silicaAddress) public sellOrderToSilica;

    ISilicaFactory private silicaFactory;

    /*///////////////////////////////////////////////////////////////
                              Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name) EIP712(name, "1") {}

    /*///////////////////////////////////////////////////////////////
                              Owner Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function set the address of the Silica Factory
     * @dev    Only the contract owner can call this function
     * @param _silicaFactoryAddress The Silica Factory address
     */
    function setSilicaFactory(address _silicaFactoryAddress) external onlyOwner {
        silicaFactory = ISilicaFactory(_silicaFactoryAddress);
    }

    /*///////////////////////////////////////////////////////////////
                           User Facing Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to get the Domain Separator
     * @return bytes32: EIP712 Domain Separator
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Function to fill a Buy Order
     * @param  buyerOrder Instance of the BuyOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      vaultAddress: 
     * })
     * @param buyerSignature The signature of the resource buyer
     * @param purchaseAmount The amount to purchase
     * @param additionalCollateralPercent Added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then you will put 30% collateral.
     * @return address: The address of the newly created Silica
     */
    function fillBuyOrder(
        OrderLib.BuyOrder calldata buyerOrder,
        bytes calldata buyerSignature,
        uint256 purchaseAmount,
        uint256 additionalCollateralPercent
    ) external returns (address) {
        address sellerAddress = msg.sender; // msg.sender = address seller to fill this buy order

        bytes32 buyerOrderDigest = _hashTypedDataV4(OrderLib._getBuyOrderHash(buyerOrder));
        address _signerAddress = ECDSA.recover(buyerOrderDigest, buyerSignature);

        {
            require(buyOrderToConsumedBudget[buyerOrderDigest] + purchaseAmount <= buyerOrder.resourceAmount, "cannot exceed budget");
            require(block.timestamp <= buyerOrder.orderExpirationTimestamp, "order expired");
            require(buyOrdersCancelled[buyerOrderDigest] == false, "This order was cancelled");
            require(buyerOrder.signerAddress == _signerAddress, "invalid signature");
        }

        // Create silica on behalf of seller
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

    /**
     * @notice Function to route buy
     * @param  sellerOrder An instance of the SellOrder struct ({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      additionalCollateralPercent:
     * })
     * @param  sellerSignature The signature of the order seller
     * @param  amount The amount to purchase
     * @return address: The address of the newly created Silica
     */
    function routeBuy(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external returns (address) {
        address buyerAddress = msg.sender;
        bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib._getSellOrderHash(sellerOrder));
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

     /**
     * @notice Function to fill a Sell  Order
     * @param  sellerOrder An instance of the SellOrder struct ({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      additionalCollateralPercent:
     * })
     * @param  sellerSignature The signature of the order seller
     * @param  amount The amount to purchase
     * @return address: The address of the newly created Silica
     */
    function fillSellOrder(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external returns (address) {
        address buyerAddress = msg.sender;
        bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib._getSellOrderHash(sellerOrder));
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

    /** 
     * @notice Function to cancel a listed buy order
     * @param  order Instance of the BuyOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      vaultAddress: 
     * })
     * @param signature The signature of the signer 
     * */ 
    
    function cancelBuyOrder(OrderLib.BuyOrder calldata order, bytes memory signature) external {
        bytes32 orderHash = _hashTypedDataV4(OrderLib._getBuyOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "Not Order Creator");
        buyOrdersCancelled[orderHash] = true;
        emit BuyOrderCancelled(_signerAddress, orderHash);
    }

    /**
     * @notice Function to cancel a listed sell order
     * @param  order Instance of the SellOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      additionalCollateralPercent: 
     * })
     * @param signature The signature of the signer 
     */
    function cancelSellOrder(OrderLib.SellOrder calldata order, bytes memory signature) external {
        bytes32 orderHash = _hashTypedDataV4(OrderLib._getSellOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "Not Order Creator");
        sellOrdersCancelled[orderHash] = true;
        emit SellOrderCancelled(_signerAddress, orderHash);
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to check if a Buy Order is canceled
     * @param  orderHash The hash of the order
     * @return bool: True if order has been cancelled
     */
    function isBuyOrderCancelled(bytes32 orderHash) external view returns (bool) {
        return buyOrdersCancelled[orderHash];
    }

    /**
     * @notice Function to check if a Sell Order is canceled
     * @param  orderHash The hash of the order
     * @return bool: True if order has been cancelled
     */
    function isSellOrderCancelled(bytes32 orderHash) external view returns (bool) {
        return sellOrdersCancelled[orderHash];
    }

    /**
     * @notice Function to return the budget consumed by a buy order
     * @param  orderHash The hash of the order
     * @return uint256: Budget Consumed
     * */ 
    function getBudgetConsumedFromOrderHash(bytes32 orderHash) external view returns (uint256) {
        return buyOrderToConsumedBudget[orderHash];
    }

    /**
     * @notice Function to return the Silica address created from a sell order
     * @param  orderHash The hash of the order
     * @return The associated Silica address
     */
    function getSilicaAddressFromSellOrderHash(bytes32 orderHash) external view returns (address) {
        return sellOrderToSilica[orderHash];
    }

    // function fillSellOrderAsVault(
    //     OrderLib.SellOrder calldata sellerOrder,
    //     bytes memory sellerSignature,
    //     uint256 amount,
    //     address vaultAddress
    // ) external returns (address) {
    //     bytes32 sellerOrderDigest = _hashTypedDataV4(OrderLib._getSellOrderHash(sellerOrder));
    //     address _signerAddress = ECDSA.recover(sellerOrderDigest, sellerSignature);

    //     {
    //         require(sellOrderToSilica[sellerOrderDigest] == address(0), "order already filled");
    //         require(block.timestamp <= sellerOrder.orderExpirationTimestamp, "order expired");
    //         require(sellOrdersCancelled[sellerOrderDigest] == false, "This order was cancelled");
    //         require(sellerOrder.signerAddress == _signerAddress, "invalid signature");
    //         require(ISilicaVault(vaultAddress).getAdmin() == msg.sender, "only admin can fill order as vault");
    //     }

    //     // create silica on behalf of msg.sender (seller, who fills this order)
    //     address silicaAddress;
    //     {
    //         if (sellerOrder.commodityType == 2) {
    //             silicaAddress = ISilicaFactory(silicaFactory).proxyCreateEthStakingSilicaV2_1(
    //                 sellerOrder.rewardToken,
    //                 sellerOrder.paymentToken,
    //                 sellerOrder.resourceAmount,
    //                 sellerOrder.endDay,
    //                 sellerOrder.unitPrice,
    //                 sellerOrder.signerAddress,
    //                 sellerOrder.additionalCollateralPercent
    //             );
    //         } else if (sellerOrder.commodityType == 0) {
    //             silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
    //                 sellerOrder.rewardToken,
    //                 sellerOrder.paymentToken,
    //                 sellerOrder.resourceAmount,
    //                 sellerOrder.endDay,
    //                 sellerOrder.unitPrice,
    //                 sellerOrder.signerAddress,
    //                 sellerOrder.additionalCollateralPercent
    //             );
    //         } else {
    //             revert("Invalid silica type");
    //         }

    //         sellOrderToSilica[sellerOrderDigest] = silicaAddress;
    //     }

    //     emit SellOrderFilled(silicaAddress, sellerOrderDigest, sellerOrder.signerAddress, vaultAddress, amount);

    //     ISilicaVault(vaultAddress).purchaseSilica(silicaAddress, amount);

    //     return silicaAddress;
    // }
}