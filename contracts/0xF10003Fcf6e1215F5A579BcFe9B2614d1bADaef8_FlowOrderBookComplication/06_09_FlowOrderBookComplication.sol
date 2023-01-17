// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

// external imports
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// internal imports
import { OrderTypes, SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowComplication } from "../interfaces/IFlowComplication.sol";

/**
 * @title FlowOrderBookComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication to execute orderbook orders
 */
contract FlowOrderBookComplication is IFlowComplication, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 public constant PRECISION = 1e4; // precision for division; similar to bps

    /// @dev WETH address of the chain being used
    // solhint-disable-next-line var-name-mixedcase
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_HASH =
        0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;

    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_ITEM_HASH =
        0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;

    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant TOKEN_INFO_HASH =
        0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;

    /// @dev Used in order signing with EIP-712
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Storage variable that keeps track of valid currencies used for payment (tokens)
    EnumerableSet.AddressSet private _currencies;

    bool public trustedExecEnabled = false;

    event CurrencyAdded(address currency);
    event CurrencyRemoved(address currency);
    event TrustedExecutionChanged(bool oldVal, bool newVal);

    constructor() {
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("FlowComplication"),
                keccak256(bytes("1")), // for versionId = 1
                block.chainid,
                address(this)
            )
        );

        // add default currencies
        _currencies.add(WETH);
        _currencies.add(address(0)); // ETH
    }

    // ======================================================= EXTERNAL FUNCTIONS ==================================================

    /**
   * @notice Checks whether one to one matches can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have one specific NFT only, whether time is still valid,
          prices are valid and whether the nfts intersect.
   * @param makerOrder1 first makerOrder
   * @param makerOrder2 second makerOrder
   * @return returns whether the order can be executed, orderHashes and the execution price
   */
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        if (trustedExecEnabled) {
            bool trustedExec = makerOrder2.constraints.length == 8 &&
                makerOrder2.constraints[7] == 1 &&
                makerOrder1.constraints.length == 8 &&
                makerOrder1.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    makerOrder1.signer,
                    makerOrder1.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        makerOrder2.signer,
                        makerOrder2.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to many matches can be executed
   * @dev This function is called by the main exchange to check whether one to many matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect. All orders are expected to contain specific items.
   * @param makerOrder the one makerOrder
   * @param manyMakerOrders many maker orders
   * @return returns whether the order can be executed and orderHash of the one side order
   */
    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view override returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);

        if (trustedExecEnabled) {
            bool isTrustedExec = makerOrder.constraints.length == 8 &&
                makerOrder.constraints[7] == 1;
            for (uint256 i; i < manyMakerOrders.length; ) {
                isTrustedExec =
                    isTrustedExec &&
                    manyMakerOrders[i].constraints.length == 8 &&
                    manyMakerOrders[i].constraints[7] == 1;
                if (!isTrustedExec) {
                    break; // short circuit
                }
                unchecked {
                    ++i;
                }
            }

            if (isTrustedExec) {
                bool sigValid = SignatureChecker.verify(
                    makerOrderHash,
                    makerOrder.signer,
                    makerOrder.sig,
                    DOMAIN_SEPARATOR
                );
                return (sigValid, makerOrderHash);
            }
        }

        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
   * @notice Checks whether match orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param sell sell order
   * @param buy buy order
   * @param constructedNfts - nfts constructed by the off chain matching engine
   * @return returns whether the order can be execute, orderHashes and the execution price
   */
    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        if (trustedExecEnabled) {
            bool trustedExec = sell.constraints.length == 8 &&
                sell.constraints[7] == 1 &&
                buy.constraints.length == 8 &&
                buy.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    sell.signer,
                    sell.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        buy.signer,
                        buy.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to one taker orders can be executed
   * @dev This function is called by the main exchange to check whether one to one taker orders can be executed.
          It checks whether orders have the right constraints - i.e they have one NFT only and whether time is still valid
   * @param makerOrder the makerOrder
   * @return returns whether the order can be executed and makerOrderHash
   */
    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        bool numItemsValid = makerOrder.constraints[0] == 1 &&
            makerOrder.nfts.length == 1 &&
            makerOrder.nfts[0].tokens.length == 1;
        bool _isTimeValid = makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        return (numItemsValid && _isTimeValid, makerOrderHash);
    }

    /**
   * @notice Checks whether take orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether take orders with a higher level intent can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid
          and whether the nfts intersect
   * @param makerOrder the maker order
   * @param takerItems the taker items specified by the taker
   * @return returns whether order can be executed and the makerOrderHash
   */
    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        return (
            makerOrder.constraints[3] <= block.timestamp &&
                makerOrder.constraints[4] >= block.timestamp &&
                areNumTakerItemsValid(makerOrder, takerItems) &&
                doItemsIntersect(makerOrder.nfts, takerItems),
            makerOrderHash
        );
    }

    // ======================================================= PUBLIC FUNCTIONS ==================================================

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sellOrderHash hash of the sell order
     * @param buyOrderHash hash of the buy order
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid
     */
    function verifyMatchOneToOneOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid and orderHash
     */
    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view override returns (bool, bytes32) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        bool _orderValid;
        bytes32 orderHash;

        if (verifySellOrder) {
            orderHash = _hash(sell);
            _orderValid = isOrderValid(sell, orderHash);
        } else {
            orderHash = _hash(buy);
            _orderValid = isOrderValid(buy, orderHash);
        }
        return (
            sell.isSellOrder &&
                !buy.isSellOrder &&
                sell.execParams[0] == buy.execParams[0] &&
                sell.signer != buy.signer &&
                currenciesMatch &&
                _orderValid,
            orderHash
        );
    }

    /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
          Also checks if the given complication can execute this order
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
    function verifyMatchOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Verifies the validity of the order
     * @dev checks if signature is valid and if the complication and currency are valid
     * @param order the order
     * @param orderHash computed hash of the order
     * @return whether the order is valid
     */
    function isOrderValid(
        OrderTypes.MakerOrder calldata order,
        bytes32 orderHash
    ) public view returns (bool) {
        // Verify the validity of the signature
        bool sigValid = SignatureChecker.verify(
            orderHash,
            order.signer,
            order.sig,
            DOMAIN_SEPARATOR
        );

        return (sigValid &&
            order.execParams[0] == address(this) &&
            _currencies.contains(order.execParams[1]));
    }

    /// @dev checks whether the orders are expired
    function isTimeValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        return
            sell.constraints[3] <= block.timestamp &&
            sell.constraints[4] >= block.timestamp &&
            buy.constraints[3] <= block.timestamp &&
            buy.constraints[4] >= block.timestamp;
    }

    /// @dev checks whether the price is valid; a buy order should always have a higher price than a sell order
    function isPriceValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool, uint256) {
        (uint256 currentSellPrice, uint256 currentBuyPrice) = (
            _getCurrentPrice(sell),
            _getCurrentPrice(buy)
        );
        return (currentBuyPrice >= currentSellPrice, currentSellPrice);
    }

    /// @dev sanity check to make sure the constructed nfts conform to the user signed constraints
    function areNumMatchItemsValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) public pure returns (bool) {
        uint256 numConstructedItems;
        for (uint256 i; i < constructedNfts.length; ) {
            unchecked {
                numConstructedItems =
                    numConstructedItems +
                    constructedNfts[i].tokens.length;
                ++i;
            }
        }
        return
            numConstructedItems >= buy.constraints[0] &&
            numConstructedItems <= sell.constraints[0];
    }

    /// @dev sanity check to make sure that a taker is specifying the right number of items
    function areNumTakerItemsValid(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) public pure returns (bool) {
        uint256 numTakerItems;
        for (uint256 i; i < takerItems.length; ) {
            unchecked {
                numTakerItems = numTakerItems + takerItems[i].tokens.length;
                ++i;
            }
        }
        return makerOrder.constraints[0] == numTakerItems;
    }

    /**
     * @notice Checks whether nfts intersect
     * @dev This function checks whether there are intersecting nfts between two orders
     * @param order1Nfts nfts in the first order
     * @param order2Nfts nfts in the second order
     * @return returns whether items intersect
     */
    function doItemsIntersect(
        OrderTypes.OrderItem[] calldata order1Nfts,
        OrderTypes.OrderItem[] calldata order2Nfts
    ) public pure returns (bool) {
        uint256 order1NftsLength = order1Nfts.length;
        uint256 order2NftsLength = order2Nfts.length;
        // case where maker/taker didn't specify any items
        if (order1NftsLength == 0 || order2NftsLength == 0) {
            return true;
        }

        uint256 numCollsMatched;
        unchecked {
            for (uint256 i; i < order2NftsLength; ) {
                for (uint256 j; j < order1NftsLength; ) {
                    if (order1Nfts[j].collection == order2Nfts[i].collection) {
                        // increment numCollsMatched
                        ++numCollsMatched;
                        // check if tokenIds intersect
                        bool tokenIdsIntersect = doTokenIdsIntersect(
                            order1Nfts[j],
                            order2Nfts[i]
                        );
                        require(tokenIdsIntersect, "tokenIds dont intersect");
                        // short circuit
                        break;
                    }
                    ++j;
                }
                ++i;
            }
        }

        return numCollsMatched == order2NftsLength;
    }

    /**
     * @notice Checks whether tokenIds intersect
     * @dev This function checks whether there are intersecting tokenIds between two order items
     * @param item1 first item
     * @param item2 second item
     * @return returns whether tokenIds intersect
     */
    function doTokenIdsIntersect(
        OrderTypes.OrderItem calldata item1,
        OrderTypes.OrderItem calldata item2
    ) public pure returns (bool) {
        uint256 item1TokensLength = item1.tokens.length;
        uint256 item2TokensLength = item2.tokens.length;
        // case where maker/taker didn't specify any tokenIds for this collection
        if (item1TokensLength == 0 || item2TokensLength == 0) {
            return true;
        }
        uint256 numTokenIdsPerCollMatched;
        unchecked {
            for (uint256 k; k < item2TokensLength; ) {
                // solhint-disable-next-line use-forbidden-name
                for (uint256 l; l < item1TokensLength; ) {
                    if (item1.tokens[l].tokenId == item2.tokens[k].tokenId) {
                        // increment numTokenIdsPerCollMatched
                        ++numTokenIdsPerCollMatched;
                        // short circuit
                        break;
                    }
                    ++l;
                }
                ++k;
            }
        }

        return numTokenIdsPerCollMatched == item2TokensLength;
    }

    // ======================================================= UTILS ============================================================

    /// @dev hashes the given order with the help of _nftsHash and _tokensHash
    function _hash(
        OrderTypes.MakerOrder calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_HASH,
                    order.isSellOrder,
                    order.signer,
                    keccak256(abi.encodePacked(order.constraints)),
                    _nftsHash(order.nfts),
                    keccak256(abi.encodePacked(order.execParams)),
                    keccak256(order.extraParams)
                )
            );
    }

    function _nftsHash(
        OrderTypes.OrderItem[] calldata nfts
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](nfts.length);
        for (uint256 i; i < nfts.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    ORDER_ITEM_HASH,
                    nfts[i].collection,
                    _tokensHash(nfts[i].tokens)
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
        return nftsHash;
    }

    function _tokensHash(
        OrderTypes.TokenInfo[] calldata tokens
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](tokens.length);
        for (uint256 i; i < tokens.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    TOKEN_INFO_HASH,
                    tokens[i].tokenId,
                    tokens[i].numTokens
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
        return tokensHash;
    }

    /// @dev returns the sum of current order prices; used in match one to many orders
    function _sumCurrentPrices(
        OrderTypes.MakerOrder[] calldata orders
    ) internal view returns (uint256) {
        uint256 sum;
        uint256 ordersLength = orders.length;
        for (uint256 i; i < ordersLength; ) {
            sum = sum + _getCurrentPrice(orders[i]);
            unchecked {
                ++i;
            }
        }
        return sum;
    }

    /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
    function _getCurrentPrice(
        OrderTypes.MakerOrder calldata order
    ) internal view returns (uint256) {
        (uint256 startPrice, uint256 endPrice) = (
            order.constraints[1],
            order.constraints[2]
        );
        if (startPrice == endPrice) {
            return startPrice;
        }

        uint256 duration = order.constraints[4] - order.constraints[3];
        if (duration == 0) {
            return startPrice;
        }

        uint256 elapsedTime = block.timestamp - order.constraints[3];
        unchecked {
            uint256 portionBps = elapsedTime > duration
                ? PRECISION
                : ((elapsedTime * PRECISION) / duration);
            if (startPrice > endPrice) {
                uint256 priceDiff = ((startPrice - endPrice) * portionBps) /
                    PRECISION;
                return startPrice - priceDiff;
            } else {
                uint256 priceDiff = ((endPrice - startPrice) * portionBps) /
                    PRECISION;
                return startPrice + priceDiff;
            }
        }
    }

    // ======================================================= VIEW FUNCTIONS ============================================================

    /// @notice returns the number of currencies supported by the exchange
    function numCurrencies() external view returns (uint256) {
        return _currencies.length();
    }

    /// @notice returns the currency at the given index
    function getCurrencyAt(uint256 index) external view returns (address) {
        return _currencies.at(index);
    }

    /// @notice returns whether a given currency is valid
    function isValidCurrency(address currency) external view returns (bool) {
        return _currencies.contains(currency);
    }

    // ======================================================= OWNER FUNCTIONS ============================================================

    /// @dev adds a new transaction currency to the exchange
    function addCurrency(address _currency) external onlyOwner {
        _currencies.add(_currency);
        emit CurrencyAdded(_currency);
    }

    /// @dev removes a transaction currency from the exchange
    function removeCurrency(address _currency) external onlyOwner {
        _currencies.remove(_currency);
        emit CurrencyRemoved(_currency);
    }

    /// @dev enables/diables trusted execution
    function setTrustedExecStatus(bool newVal) external onlyOwner {
        bool oldVal = trustedExecEnabled;
        require(oldVal != newVal, "no value change");
        trustedExecEnabled = newVal;
        emit TrustedExecutionChanged(oldVal, newVal);
    }
}