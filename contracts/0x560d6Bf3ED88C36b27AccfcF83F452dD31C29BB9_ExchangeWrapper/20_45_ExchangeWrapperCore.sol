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
        @param fees - 2 fees (in base points) that are going to be taken on top of order amount encoded in 1 uint256
                        bytes (27,28) used for dataType
                        bytes (29,30) used for the first value (goes to feeRecipientFirst)
                        bytes (31,32) are used for the second value (goes to feeRecipientSecond)
        @param data - data for market call
     */
    struct PurchaseDetails {
        Markets marketId;
        uint256 amount;
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
        @notice struct for the swap out v3 data
        @param path - path
        @param amountIn - amountIn
        @param amountOutMinimum - amountOutMinimum
        @param unwrap - unwrap
     */
    struct SwapDetailsOut {
        bytes path;
        uint256 amountIn;
        uint256 amountOutMinimum;
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

    /**
        @notice struct for the swap out v2 data
        @param path - tokenIn
        @param amountIn - amountIn
        @param amountOutMinimum - amountOutMinimum
        @param binSteps - binSteps
        @param unwrap - unwrap
     */
    struct SwapV2DetailsOut {
        address[] path;
        uint256 amountIn;
        uint256 amountOutMinimum;
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

    /// temp for upgrade - to remove once initialized
    function setRarible(address _rarible) external onlyOwner {
        rarible = _rarible;
    }

    function setBlur(address _blur) external onlyOwner {
        blur = _blur;
    }

    /// temp for upgrade - to remove once initialized

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
    ) public payable whenNotPaused {
        (bool success, uint feeAmountFirst, uint feeAmountSecond) = purchase(purchaseDetails, false);
        emit Execution(success, _msgSender());

        transferFee(feeAmountFirst, feeRecipientFirst);
        transferFee(feeAmountSecond, feeRecipientSecond);

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
    ) public payable whenNotPaused {
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];
        // tokens for eth or weth
        if (tokenOut == wrappedToken) {
            bool isSwapExecuted = swapV2TokensForExactETHOrWETH(swapDetails, true);
            require(isSwapExecuted, "swap not successful");
        }
        // tokens for tokens
        else {
            bool isSwapExecuted = swapV2TokensForExactTokens(swapDetails, true);
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
    ) public payable whenNotPaused {
        bool isSwapExecuted = swapTokensForExactTokens(swapDetails, true);
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

            sumFirstFees = sumFirstFees + (firstFeeAmount);
            sumSecondFees = sumSecondFees + (secondFeeAmount);
        }

        require(result, "no successful executions");

        transferFee(sumFirstFees, feeRecipientFirst);
        transferFee(sumSecondFees, feeRecipientSecond);

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
        uint paymentAmount = purchaseDetails.amount;
        if (purchaseDetails.marketId == Markets.SeaPort) {
            (bool success, ) = address(seaport).call{value: paymentAmount}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Seaport failed");
            }
        } else if (purchaseDetails.marketId == Markets.Wyvern) {
            (bool success, ) = address(wyvern).call{value: paymentAmount}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Wyvern failed");
            }
        } else if (purchaseDetails.marketId == Markets.ExchangeV2) {
            (bool success, ) = address(exchangeV2).call{value: paymentAmount}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase GhostMarket failed");
            }
        } else if (purchaseDetails.marketId == Markets.Rarible) {
            (bool success, ) = address(rarible).call{value: paymentAmount}(marketData);
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
                try Ix2y2(x2y2).run{value: paymentAmount}(input) {} catch {
                    return (false, 0, 0);
                }
            } else {
                Ix2y2(x2y2).run{value: paymentAmount}(input);
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
                    ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: paymentAmount}(
                        takerOrder,
                        makerOrder
                    )
                {} catch {
                    return (false, 0, 0);
                }
            } else {
                ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: paymentAmount}(takerOrder, makerOrder);
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
            (bool success, ) = address(sudoswap).call{value: paymentAmount}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SudoSwap failed");
            }
        } else if (purchaseDetails.marketId == Markets.Blur) {
            (bool success, ) = address(blur).call{value: paymentAmount}(marketData);
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

        (uint firstFeeAmount, uint secondFeeAmount) = getFees(purchaseDetails.fees, purchaseDetails.amount);
        return (true, firstFeeAmount, secondFeeAmount);
    }

    /**
        @notice transfers fee to feeRecipient
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFee(uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            LibTransfer.transferEth(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers change back to sender
     */
    function transferChange() internal {
        uint ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address(msg.sender).transferEth(ethAmount);
        }
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
     * @param combined combined swap + buy - if true funds are not sent back to sender buy kept for trade
     */
    function swapV2TokensForExactTokens(SwapV2DetailsIn memory swapDetails, bool combined) public returns (bool) {
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
            try
                uniswapRouterV2.swapTokensForExactTokens(
                    swapDetails.amountOut, // amountOut
                    swapDetails.amountInMaximum, // amountInMaximum
                    swapDetails.binSteps, // binSteps
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountIn = amounts[0];
            } catch {
                return false;
            }
        } else {
            try
                uniswapRouterV2.swapTokensForExactTokens(
                    swapDetails.amountOut, // amountOut
                    swapDetails.amountInMaximum, // amountInMaximum
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountIn = amounts[0];
            } catch {
                return false;
            }
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        if (!combined) {
            address tokenOut = swapDetails.path[swapDetails.path.length - 1];
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountOut);
        }

        return true;
    }

    /**
     * @notice swaps exact tokens for tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2ExactTokensForTokens(SwapV2DetailsOut memory swapDetails) public returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountIn
        );

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV2), address(this));
        if (allowance < swapDetails.amountIn) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV2), type(uint256).max);
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountOut;

        if (isAvalanche) {
            try
                uniswapRouterV2.swapTokensForExactTokens(
                    swapDetails.amountIn, // amountIn
                    swapDetails.amountOutMinimum, // amountOutMinimum
                    swapDetails.binSteps, // binSteps
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountOut = amounts[0];
            } catch {
                return false;
            }
        } else {
            try
                uniswapRouterV2.swapTokensForExactTokens(
                    swapDetails.amountIn, // amountIn
                    swapDetails.amountOutMinimum, // amountOutMinimum
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountOut = amounts[0];
            } catch {
                return false;
            }
        }

        // send token out back
        IERC20Upgradeable(tokenOut).transfer(_msgSender(), amountOut);

        return true;
    }

    /**
     * @notice swaps tokens for exact ETH or WETH - uniswap v2
     * @param swapDetails swapDetails required
     * @param combined combined swap + buy - if true funds are not sent back to sender buy kept for trade
     */
    function swapV2TokensForExactETHOrWETH(SwapV2DetailsIn memory swapDetails, bool combined) public returns (bool) {
        // extract tokenIn from path
        address tokenIn = swapDetails.path[0];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountInMaximum
        );

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            IWETH(wrappedToken).withdraw(swapDetails.amountInMaximum);
            if (!combined) {
                address(_msgSender()).transferEth(swapDetails.amountInMaximum);
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
        if (isAvalanche) {
            try
                uniswapRouterV2.swapTokensForExactAVAX(
                    swapDetails.amountOut, // amountOut
                    swapDetails.amountInMaximum, // amountInMaximum
                    swapDetails.binSteps, // binSteps
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountIn = amounts[0];
            } catch {
                return false;
            }
        } else {
            try
                uniswapRouterV2.swapTokensForExactETH(
                    swapDetails.amountOut, // amountOut
                    swapDetails.amountInMaximum, // amountInMaximum
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountIn = amounts[0];
            } catch {
                return false;
            }
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        // Wrap if required
        if (swapDetails.unwrap) {
            IWETH(wrappedToken).deposit{value: swapDetails.amountOut}();
        }

        if (!combined) {
            if (swapDetails.unwrap) {
                address tokenOut = swapDetails.path[swapDetails.path.length - 1];
                IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountOut);
            } else {
                address(_msgSender()).transferEth(swapDetails.amountOut);
            }
        }

        return true;
    }

    /**
     * @notice swaps exact ETH or WETH for tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2ExactETHOrWETHForTokens(SwapV2DetailsOut memory swapDetails) public payable returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract if ERC20
        if (msg.value == 0) {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(tokenIn),
                _msgSender(),
                address(this),
                swapDetails.amountIn
            );

            IWETH(wrappedToken).withdraw(swapDetails.amountIn);
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            IWETH(wrappedToken).deposit{value: msg.value}();
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountIn);
            return true;
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountOut;
        if (isAvalanche) {
            try
                uniswapRouterV2.swapExactAVAXForTokens(
                    swapDetails.amountOutMinimum, // amountOutMinimum
                    swapDetails.binSteps, // binSteps
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountOut = amounts[0];
            } catch {
                return false;
            }
        } else {
            try
                uniswapRouterV2.swapExactETHForTokens(
                    swapDetails.amountOutMinimum, // amountOutMinimum
                    swapDetails.path, // path
                    address(this), // recipient
                    block.timestamp // deadline
                )
            returns (uint[] memory amounts) {
                amountOut = amounts[0];
            } catch {
                return false;
            }
        }

        // send token out back
        IERC20Upgradeable(tokenOut).transfer(_msgSender(), amountOut);

        return true;
    }

    /**
     * @notice swaps tokens for exact tokens - uniswap v3
     * @param swapDetails swapDetails required
     * @param combined combined swap + buy - if true funds are not sent back to sender buy kept for trade
     */
    function swapTokensForExactTokens(SwapDetailsIn memory swapDetails, bool combined) public payable returns (bool) {
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
            IWETH(wrappedToken).withdraw(swapDetails.amountOut);
            if (!combined) {
                address(_msgSender()).transferEth(swapDetails.amountOut);
            }
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            IWETH(wrappedToken).deposit{value: msg.value}();
            if (!combined) {
                IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountOut);
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
        try uniswapRouterV3.exactOutput(params) returns (uint256 amount) {
            amountIn = amount;
        } catch {
            return false;
        }

        // Refund ETH from swap if any
        uniswapRouterV3.refundETH();

        // Unwrap if required
        if (swapDetails.unwrap) {
            IWETH(wrappedToken).withdraw(swapDetails.amountOut);
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        if (!combined) {
            if (swapDetails.unwrap) {
                address(_msgSender()).transferEth(swapDetails.amountOut);
            } else {
                IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountOut);
            }
        }

        return true;
    }

    /**
     * @notice swaps exact tokens for tokens - uniswap v3
     * @param swapDetails swapDetails required
     */
    function swapExactTokensForTokens(SwapDetailsOut memory swapDetails) public payable returns (bool) {
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
                swapDetails.amountIn
            );
        }

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            IWETH(wrappedToken).withdraw(swapDetails.amountIn);
            address(_msgSender()).transferEth(swapDetails.amountIn);
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            IWETH(wrappedToken).deposit{value: msg.value}();
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountIn);
            return true;
        }

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV3), address(this));
        if (allowance < swapDetails.amountIn) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV3), type(uint256).max);
        }

        // Set the order parameters
        ISwapRouterV3.ExactInputParams memory params = ISwapRouterV3.ExactInputParams(
            swapDetails.path, // path
            address(this), // recipient
            block.timestamp, // deadline
            swapDetails.amountIn, // amountIn
            swapDetails.amountOutMinimum // amountOutMinimum
        );

        // Swap
        uint256 amountOut;
        try uniswapRouterV3.exactInput(params) returns (uint256 amount) {
            amountOut = amount;
        } catch {
            return false;
        }

        // Refund ETH from swap if any
        uniswapRouterV3.refundETH();

        // Unwrap if required
        if (swapDetails.unwrap) {
            IWETH(wrappedToken).withdraw(amountOut);
        }

        // send token out back
        if (swapDetails.unwrap) {
            address(_msgSender()).transferEth(amountOut);
        } else {
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), amountOut);
        }

        return true;
    }

    receive() external payable {}
}