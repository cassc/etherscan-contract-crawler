// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibTransfer.sol";
import "../librairies/BpLibrary.sol";
import "../librairies/LibPart.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IWyvernExchange.sol";
import "./interfaces/IExchangeV2.sol";
import "./interfaces/ISeaPort.sol";
import "./interfaces/Ix2y2.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IBlurExchange.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISwapRouterV3.sol";
import "./interfaces/ISwapRouterV2.sol";
import "../interfaces/INftTransferProxy.sol";
import "../interfaces/IERC20TransferProxy.sol";

abstract contract ExchangeWrapperCore is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721Holder,
    ERC1155Holder
{
    using LibTransfer for address;
    using BpLibrary for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public exchangeV2;
    address public rarible;
    address public wyvern;
    address public seaport;
    address public x2y2;
    address public looksrare;
    address public sudoswap;
    address public blur;
    ISwapRouterV2 public uniswapRouterV2;
    ISwapRouterV3 public uniswapRouterV3;
    address public wrappedToken;
    address public erc20TransferProxy;

    // mapping market id <> market erc20 proxy
    mapping(Markets => address) public proxies;

    event Execution(bool result, address indexed sender);

    enum Markets {
        Rarible,
        Wyvern,
        SeaPort,
        X2Y2,
        LooksRare,
        SudoSwap,
        ExchangeV2,
        Blur
    }

    enum AdditionalDataTypes {
        NoAdditionalData,
        RoyaltiesAdditionalData
    }

    /**
        @notice struct for the purchase data
        @param marketId - market key from Markets enum (what market to use)
        @param amount - eth price (amount of eth that needs to be send to the marketplace)
        @param paymentToken - payment token required for the order
        @param fees - 2 fees (in base points) that are going to be taken on top of order amount encoded in 1 uint256
                        bytes (27,28) used for dataType
                        bytes (29,30) used for the first value (goes to feeRecipientFirst)
                        bytes (31,32) are used for the second value (goes to feeRecipientSecond)
        @param data - data for market call
     */
    struct PurchaseDetails {
        Markets marketId;
        uint256 amount;
        address paymentToken;
        uint fees;
        bytes data;
    }

    /**
        @notice struct for the data with additional Ddta
        @param data - data for market call
        @param additionalRoyalties - array additional Royalties (in base points plus address Royalty recipient)
     */
    struct AdditionalData {
        bytes data;
        uint[] additionalRoyalties;
    }

    /**
        @notice struct for the swap in v3 data
        @param path - tokenIn
        @param amountOut - amountOut
        @param amountInMaximum - amountInMaximum
        @param unwrap - unwrap
     */
    struct SwapDetailsIn {
        bytes path;
        uint256 amountOut;
        uint256 amountInMaximum;
        bool unwrap;
    }

    /**
        @notice struct for the swap in v2 data
        @param path - tokenIn
        @param amountOut - amountOut
        @param amountInMaximum - amountInMaximum
        @param binSteps - binSteps
        @param unwrap - unwrap
     */
    struct SwapV2DetailsIn {
        address[] path;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint256[] binSteps;
        bool unwrap;
    }

    function __ExchangeWrapper_init_unchained(
        address _exchangeV2,
        address _rarible,
        address _wyvern,
        address _seaport,
        address _x2y2,
        address _looksrare,
        address _sudoswap,
        address _blur
    ) internal {
        exchangeV2 = _exchangeV2;
        rarible = _rarible;
        wyvern = _wyvern;
        seaport = _seaport;
        x2y2 = _x2y2;
        looksrare = _looksrare;
        sudoswap = _sudoswap;
        blur = _blur;
    }

    /// @notice Pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Set uniswap v2 router
    function setUniswapV2(ISwapRouterV2 _uniswapRouterV2) external onlyOwner {
        uniswapRouterV2 = _uniswapRouterV2;
    }

    /// @notice Set uniswap v3 router
    function setUniswapV3(ISwapRouterV3 _uniswapRouterV3) external onlyOwner {
        uniswapRouterV3 = _uniswapRouterV3;
    }

    /// @notice Set wrapped token
    function setWrapped(address _wrappedToken) external onlyOwner {
        wrappedToken = _wrappedToken;
    }

    /// @notice Set erc20 transfer proxy
    function setTransferProxy(address _erc20TransferProxy) external onlyOwner {
        erc20TransferProxy = _erc20TransferProxy;
    }

    /// @notice Set erc20 proxy for market
    function setMarketProxy(Markets marketId, address proxy) external onlyOwner {
        proxies[marketId] = proxy;
    }

    /**
        @notice executes a single purchase
        @param purchaseDetails - details about the purchase (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
     */
    function singlePurchase(
        PurchaseDetails memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond
    ) external payable whenNotPaused {
        (bool success, uint feeAmountFirst, uint feeAmountSecond) = purchase(purchaseDetails, false);
        emit Execution(success, _msgSender());

        if (purchaseDetails.paymentToken == address(0)) {
            transferFee(feeAmountFirst, feeRecipientFirst);
            transferFee(feeAmountSecond, feeRecipientSecond);
        } else {
            transferFeeToken(purchaseDetails.paymentToken, feeAmountFirst, feeRecipientFirst);
            transferFeeToken(purchaseDetails.paymentToken, feeAmountSecond, feeRecipientSecond);

            transferFeeChange(purchaseDetails.paymentToken);
        }

        transferChange();
    }

    /**
        @notice executes an array of purchases - with swap v2 - tokens for tokens or tokens for eth/weth
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
        @param swapDetails - swapDetails v2
     */

    function bulkPurchaseWithV2Swap(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail,
        SwapV2DetailsIn memory swapDetails
    ) external payable whenNotPaused {
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];
        // tokens for eth or weth
        if (tokenOut == wrappedToken) {
            bool isSwapExecuted = swapV2TokensForExactETHOrWETH(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }
        // eth or weth for tokens
        else if (tokenIn == wrappedToken) {
            bool isSwapExecuted = swapV2ETHOrWETHForExactTokens(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }
        // tokens for tokens
        else {
            bool isSwapExecuted = swapV2TokensForExactTokens(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }

        bulkPurchase(purchaseDetails, feeRecipientFirst, feeRecipientSecond, allowFail);
    }

    /**
        @notice executes an array of purchases - with swap v3
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
        @param swapDetails - swapDetails v3
     */

    function bulkPurchaseWithSwap(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail,
        SwapDetailsIn memory swapDetails
    ) external payable whenNotPaused {
        bool isSwapExecuted = swapTokensForExactTokens(swapDetails);
        require(isSwapExecuted, "swap not successful");
        bulkPurchase(purchaseDetails, feeRecipientFirst, feeRecipientSecond, allowFail);
    }

    /**
        @notice executes an array of purchases
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
     */

    function bulkPurchase(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail
    ) public payable whenNotPaused {
        uint sumFirstFees = 0;
        uint sumSecondFees = 0;
        bool result = false;

        uint length = purchaseDetails.length;
        for (uint i; i < length; ++i) {
            (bool success, uint firstFeeAmount, uint secondFeeAmount) = purchase(purchaseDetails[i], allowFail);

            result = result || success;
            emit Execution(success, _msgSender());

            if (purchaseDetails[i].paymentToken == address(0)) {
                sumFirstFees = sumFirstFees + (firstFeeAmount);
                sumSecondFees = sumSecondFees + (secondFeeAmount);
            }
            // erc20 fees transferred right after each purchase to avoid having to store total
            else {
                transferFeeToken(purchaseDetails[i].paymentToken, firstFeeAmount, feeRecipientFirst);
                transferFeeToken(purchaseDetails[i].paymentToken, secondFeeAmount, feeRecipientSecond);
            }
        }

        require(result, "no successful executions");

        transferFee(sumFirstFees, feeRecipientFirst);
        transferFee(sumSecondFees, feeRecipientSecond);

        transferFeeChange(purchaseDetails);
        transferChange();
    }

    /**
        @notice executes one purchase
        @param purchaseDetails - details about the purchase
        @param allowFail - true if errors are handled, false if revert on errors
        @return result false if execution failed, true if succeded
        @return firstFeeAmount amount of the first fee of the purchase, 0 if failed
        @return secondFeeAmount amount of the second fee of the purchase, 0 if failed
     */
    function purchase(PurchaseDetails memory purchaseDetails, bool allowFail) internal returns (bool, uint, uint) {
        (bytes memory marketData, uint[] memory additionalRoyalties) = getDataAndAdditionalData(
            purchaseDetails.data,
            purchaseDetails.fees,
            purchaseDetails.marketId
        );

        uint nativeAmountToSend = purchaseDetails.amount;

        (uint firstFeeAmount, uint secondFeeAmount) = getFees(purchaseDetails.fees, purchaseDetails.amount);

        // purchase with ERC20
        if (purchaseDetails.paymentToken != address(0)) {
            // Set native value to 0 for ERC20
            nativeAmountToSend = 0;

            // Check balance in contract as there might be some from swap
            uint currentBalance = IERC20Upgradeable(purchaseDetails.paymentToken).balanceOf(address(this));

            // set token value to amount + fees
            uint tokenAmountToSend = purchaseDetails.amount + firstFeeAmount + secondFeeAmount;

            // Move tokenIn to contract and move what's missing if any
            if (tokenAmountToSend > currentBalance) {
                IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                    IERC20Upgradeable(purchaseDetails.paymentToken),
                    _msgSender(),
                    address(this),
                    tokenAmountToSend - currentBalance
                );
            }

            // Approve tokenIn on market proxy
            address marketProxy = getMarketProxy(purchaseDetails.marketId);
            uint256 allowance = IERC20Upgradeable(purchaseDetails.paymentToken).allowance(marketProxy, address(this));
            if (allowance < tokenAmountToSend) {
                IERC20Upgradeable(purchaseDetails.paymentToken).approve(address(marketProxy), type(uint256).max);
            }
        }

        if (purchaseDetails.marketId == Markets.SeaPort) {
            (bool success, ) = address(seaport).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Seaport failed");
            }
        }
        /* else if (purchaseDetails.marketId == Markets.Wyvern) {
            (bool success, ) = address(wyvern).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Wyvern failed");
            }
        } */
        else if (purchaseDetails.marketId == Markets.ExchangeV2) {
            (bool success, ) = address(exchangeV2).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase GhostMarket failed");
            }
        } else if (purchaseDetails.marketId == Markets.Rarible) {
            (bool success, ) = address(rarible).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Rarible failed");
            }
        } else if (purchaseDetails.marketId == Markets.X2Y2) {
            Ix2y2.RunInput memory input = abi.decode(marketData, (Ix2y2.RunInput));

            if (allowFail) {
                try Ix2y2(x2y2).run{value: nativeAmountToSend}(input) {} catch {
                    return (false, 0, 0);
                }
            } else {
                Ix2y2(x2y2).run{value: nativeAmountToSend}(input);
            }

            // for every element in input.details[] getting
            // order = input.details[i].orderIdx
            // and from that order getting item = input.details[i].itemId
            uint length = input.details.length;
            for (uint i; i < length; ++i) {
                uint orderId = input.details[i].orderIdx;
                uint itemId = input.details[i].itemIdx;
                bytes memory data = input.orders[orderId].items[itemId].data;
                {
                    if (input.orders[orderId].dataMask.length > 0 && input.details[i].dataReplacement.length > 0) {
                        _arrayReplace(data, input.details[i].dataReplacement, input.orders[orderId].dataMask);
                    }
                }

                // 1 = erc-721
                if (input.orders[orderId].delegateType == 1) {
                    Ix2y2.Pair721[] memory pairs = abi.decode(data, (Ix2y2.Pair721[]));

                    for (uint256 j = 0; j < pairs.length; j++) {
                        Ix2y2.Pair721 memory p = pairs[j];
                        IERC721Upgradeable(address(p.token)).safeTransferFrom(address(this), _msgSender(), p.tokenId);
                    }
                } else if (input.orders[orderId].delegateType == 2) {
                    // 2 = erc-1155
                    Ix2y2.Pair1155[] memory pairs = abi.decode(data, (Ix2y2.Pair1155[]));

                    for (uint256 j = 0; j < pairs.length; j++) {
                        Ix2y2.Pair1155 memory p = pairs[j];
                        IERC1155Upgradeable(address(p.token)).safeTransferFrom(
                            address(this),
                            _msgSender(),
                            p.tokenId,
                            p.amount,
                            ""
                        );
                    }
                } else {
                    revert("unknown delegateType x2y2");
                }
            }
        } else if (purchaseDetails.marketId == Markets.LooksRare) {
            (LibLooksRare.TakerOrder memory takerOrder, LibLooksRare.MakerOrder memory makerOrder, bytes4 typeNft) = abi
                .decode(marketData, (LibLooksRare.TakerOrder, LibLooksRare.MakerOrder, bytes4));
            if (allowFail) {
                try
                    ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: nativeAmountToSend}(
                        takerOrder,
                        makerOrder
                    )
                {} catch {
                    return (false, 0, 0);
                }
            } else {
                ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: nativeAmountToSend}(
                    takerOrder,
                    makerOrder
                );
            }
            if (typeNft == LibAsset.ERC721_ASSET_CLASS) {
                IERC721Upgradeable(makerOrder.collection).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    makerOrder.tokenId
                );
            } else if (typeNft == LibAsset.ERC1155_ASSET_CLASS) {
                IERC1155Upgradeable(makerOrder.collection).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    makerOrder.tokenId,
                    makerOrder.amount,
                    ""
                );
            } else {
                revert("Unknown token type");
            }
        } else if (purchaseDetails.marketId == Markets.SudoSwap) {
            (bool success, ) = address(sudoswap).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SudoSwap failed");
            }
        } else if (purchaseDetails.marketId == Markets.Blur) {
            (bool success, ) = address(blur).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase blurio failed");
            }
        } else {
            revert("Unknown purchase details");
        }

        //transferring royalties
        transferAdditionalRoyalties(additionalRoyalties, purchaseDetails.amount);

        return (true, firstFeeAmount, secondFeeAmount);
    }

    /**
        @notice transfers fee native to feeRecipient
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFee(uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            LibTransfer.transferEth(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers fee token to feeRecipient
        @param paymentToken - token to be transfered
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFeeToken(address paymentToken, uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            IERC20Upgradeable(paymentToken).transfer(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers change native back to sender
     */
    function transferChange() internal {
        uint ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address(msg.sender).transferEth(ethAmount);
        }
    }

    /**
        @notice transfers change fee back to sender
     */
    function transferFeeChange(address paymentToken) internal {
        uint tokenAmount = IERC20Upgradeable(paymentToken).balanceOf(address(this));
        if (tokenAmount > 0) {
            IERC20Upgradeable(paymentToken).transfer(_msgSender(), tokenAmount);
        }
    }

    /**
        @notice transfers change fees back to sender
     */
    function transferFeeChange(PurchaseDetails[] memory purchaseDetails) internal {
        uint length = purchaseDetails.length;
        for (uint i; i < length; ++i) {
            if (purchaseDetails[i].paymentToken != address(0)) {
                transferFeeChange(purchaseDetails[i].paymentToken);
            }
        }
    }

    /**
        @notice return market proxy based on market id
        @param marketId market id
        @return address market proxy address
     */
    function getMarketProxy(Markets marketId) internal view returns (address) {
        return proxies[marketId];
    }

    /**
        @notice parses fees in base points from one uint and calculates real amount of fees
        @param fees two fees encoded in one uint, 29 and 30 bytes are used for the first fee, 31 and 32 bytes for second fee
        @param amount price of the order
        @return firstFeeAmount real amount for the first fee
        @return secondFeeAmount real amount for the second fee
     */
    function getFees(uint fees, uint amount) internal pure returns (uint, uint) {
        uint firstFee = uint(uint16(fees >> 16));
        uint secondFee = uint(uint16(fees));
        return (amount.bp(firstFee), amount.bp(secondFee));
    }

    /**
        @notice parses _data to data for market call and additionalData
        @param feesAndDataType 27 and 28 bytes for dataType
        @return marketData data for market call
        @return additionalRoyalties array uint256, (base point + address)
     */
    function getDataAndAdditionalData(
        bytes memory _data,
        uint feesAndDataType,
        Markets marketId
    ) internal pure returns (bytes memory, uint[] memory) {
        AdditionalDataTypes dataType = AdditionalDataTypes(uint16(feesAndDataType >> 32));
        uint[] memory additionalRoyalties;

        //return no royalties if wrong data type
        if (dataType == AdditionalDataTypes.NoAdditionalData) {
            return (_data, additionalRoyalties);
        }

        if (dataType == AdditionalDataTypes.RoyaltiesAdditionalData) {
            AdditionalData memory additionalData = abi.decode(_data, (AdditionalData));

            //return no royalties if market doesn't support royalties
            if (supportsRoyalties(marketId)) {
                return (additionalData.data, additionalData.additionalRoyalties);
            } else {
                return (additionalData.data, additionalRoyalties);
            }
        }

        revert("unknown additionalDataType");
    }

    /**
        @notice transfer additional royalties
        @param _additionalRoyalties array uint256 (base point + royalty recipient address)
     */
    function transferAdditionalRoyalties(uint[] memory _additionalRoyalties, uint amount) internal {
        uint length = _additionalRoyalties.length;
        for (uint i; i < length; ++i) {
            if (_additionalRoyalties[i] > 0) {
                address payable account = payable(address(uint160(_additionalRoyalties[i])));
                uint basePoint = uint(_additionalRoyalties[i] >> 160);
                uint value = amount.bp(basePoint);
                transferFee(value, account);
            }
        }
    }

    // modifies `src`
    function _arrayReplace(bytes memory src, bytes memory replacement, bytes memory mask) internal view virtual {
        require(src.length == replacement.length);
        require(src.length == mask.length);

        uint256 length = src.length;
        for (uint256 i; i < length; ++i) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }

    /**
        @notice returns true if this contract supports additional royalties for the marketpale
        now royalties support only for marketId = sudoswap
    */
    function supportsRoyalties(Markets marketId) internal pure returns (bool) {
        if (marketId == Markets.SudoSwap || marketId == Markets.LooksRare) {
            return true;
        }

        return false;
    }

    /**
     * @notice swaps tokens for exact tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2TokensForExactTokens(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn from path
        address tokenIn = swapDetails.path[0];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountInMaximum
        );

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV2), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV2), type(uint256).max);
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountIn;

        if (isAvalanche) {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactTokens(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        } else {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactTokens(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        return true;
    }

    /**
     * @notice swaps tokens for exact ETH or WETH - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2TokensForExactETHOrWETH(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountInMaximum
        );

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountInMaximum) {} catch {
                return false;
            }
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            return true;
        }

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV2), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV2), type(uint256).max);
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountIn;
        uint256 balanceEthBefore = address(this).balance;

        if (isAvalanche) {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactAVAX(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                payable(address(this)), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        } else {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactETH(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.path, // path
                payable(address(this)), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        }

        uint256 balanceEthAfter = address(this).balance;

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        // Wrap if required
        if (swapDetails.unwrap) {
            try IWETH(wrappedToken).deposit{value: balanceEthAfter - balanceEthBefore}() {} catch {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice swaps ETH or WETH for exact tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2ETHOrWETHForExactTokens(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract if ERC20
        if (msg.value == 0) {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(tokenIn),
                _msgSender(),
                address(this),
                swapDetails.amountInMaximum
            );

            try IWETH(wrappedToken).withdraw(swapDetails.amountInMaximum) {} catch {
                return false;
            }
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountInMaximum);
            return true;
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;

        if (isAvalanche) {
            uniswapRouterV2.swapAVAXForExactTokens{value: swapDetails.amountInMaximum}(
                swapDetails.amountOut, // amountOutMinimum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
        } else {
            uniswapRouterV2.swapETHForExactTokens{value: swapDetails.amountInMaximum}(
                swapDetails.amountOut, // amountOutMinimum
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
        }

        return true;
    }

    /**
     * @notice swaps tokens for exact tokens - uniswap v3
     * @param swapDetails swapDetails required
     */
    function swapTokensForExactTokens(SwapDetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn;
        address tokenOut;
        bytes memory _path = swapDetails.path;
        uint _start = _path.length - 20;
        assembly {
            tokenIn := div(mload(add(add(_path, 0x20), _start)), 0x1000000000000000000000000)
            tokenOut := div(mload(add(add(_path, 0x20), 0)), 0x1000000000000000000000000)
        }

        // Move tokenIn to contract if ERC20
        if (msg.value == 0) {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(tokenIn),
                _msgSender(),
                address(this),
                swapDetails.amountInMaximum
            );
        }

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountOut) {} catch {
                return false;
            }
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            return true;
        }

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV3), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV3), type(uint256).max);
        }

        // Set the order parameters
        ISwapRouterV3.ExactOutputParams memory params = ISwapRouterV3.ExactOutputParams(
            swapDetails.path, // path
            address(this), // recipient
            block.timestamp, // deadline
            swapDetails.amountOut, // amountOut
            swapDetails.amountInMaximum // amountInMaximum
        );

        // Swap
        uint256 amountIn;
        try uniswapRouterV3.exactOutput{ value: msg.value }(params) returns (uint256 amount) {
            amountIn = amount;
        } catch {
            return false;
        }

        // Refund ETH from swap if any
        uniswapRouterV3.refundETH();

        // Unwrap if required
        if (swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountOut) {} catch {
                return false;
            }
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            if (msg.value == 0)
            {
                IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
            }
        }

        return true;
    }

    receive() external payable {}
}