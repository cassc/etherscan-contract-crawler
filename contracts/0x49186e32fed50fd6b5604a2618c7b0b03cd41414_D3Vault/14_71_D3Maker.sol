// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/MakerTypes.sol";
import "../lib/Types.sol";
import "../lib/InitializableOwnable.sol";
import "../lib/Errors.sol";
import {ID3MM} from "../intf/ID3MM.sol";

/// @notice D3Maker is a dependent price controll model. Maker could set token price and other price 
/// parameters to control swap. The key part is MakerState(in D3Maker) and flag(in D3MM) parameter. MakerState 
/// contains token price, amount and swap fee. Specially for token price, which is supposed to be set frequently,
/// we use one slot to compress 3 token price with dependent price array. Flags in D3MM decide whether this token's 
/// cumulative volumn change, which means resetting integral start point. Every function should reset cumulative
/// volumn.
/// @dev maker could not delete token function
contract D3Maker is InitializableOwnable {
    MakerTypes.MakerState internal state;
    address public _POOL_;
    address[] internal poolTokenlist;

    // ============== Event =============
    // use operatorIndex to distinct different setting, 1 = setMaxInterval  2 = setTokensPrice, 3 = setNSPriceSlot,
    // 4 = setStablePriceSlot, 5 = setTokensAmounts, 6 = setTokensKs
    event SetPoolInfo(uint256 indexed operatorIndex);
    event SetNewToken(address indexed token);

    // ============== init =============
    function init(address owner, address pool, uint256 maxInterval) external {
        initOwner(owner);
        _POOL_ = pool;
        state.heartBeat.maxInterval = maxInterval;
    }

    // ============= Read for tokenMMInfo =================
    function getTokenMMInfoForPool(address token)
        external
        view
        returns (Types.TokenMMInfo memory tokenMMInfo, uint256 tokenIndex)
    {
        if (state.tokenMMInfoMap[token].amountInfo == 0) {
            // invalid token
            return (tokenMMInfo, 0);
        }
        // get mtFee
        uint256 mtFeeRate = ID3MM(_POOL_).getFeeRate(token);
        // deal with priceInfo
        uint80 priceInfo = getOneTokenPriceSet(token);
        (
            tokenMMInfo.askUpPrice,
            tokenMMInfo.askDownPrice,
            tokenMMInfo.bidUpPrice,
            tokenMMInfo.bidDownPrice,
            tokenMMInfo.swapFeeRate
        ) = MakerTypes.parseAllPrice(priceInfo, mtFeeRate);
        // lpfee add mtFee
        tokenMMInfo.mtFeeRate = mtFeeRate;
        uint64 amountInfo = state.tokenMMInfoMap[token].amountInfo;
        tokenMMInfo.askAmount = MakerTypes.parseAskAmount(amountInfo);
        tokenMMInfo.bidAmount = MakerTypes.parseBidAmount(amountInfo);
        tokenMMInfo.kAsk = MakerTypes.parseK(state.tokenMMInfoMap[token].kAsk);
        tokenMMInfo.kBid = MakerTypes.parseK(state.tokenMMInfoMap[token].kBid);
        tokenIndex = uint256(getOneTokenOriginIndex(token));
    }

    // ================== Read parameters ==============

    /// @notice give one token's address, give back token's priceInfo
    function getOneTokenPriceSet(address token) public view returns (uint80 priceSet) {
        require(state.priceListInfo.tokenIndexMap[token] > 0, Errors.INVALID_TOKEN);
        uint256 tokenOriIndex = state.priceListInfo.tokenIndexMap[token] - 1;
        uint256 tokenIndex = (tokenOriIndex / 2);
        uint256 tokenIndexInnerSlot = tokenIndex % MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;

        uint256 curAllPrices = tokenOriIndex % 2 == 1
            ? state.priceListInfo.tokenPriceNS[tokenIndex / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT]
            : state.priceListInfo.tokenPriceStable[tokenIndex / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT];
        curAllPrices = curAllPrices >> (MakerTypes.ONE_PRICE_BIT * tokenIndexInnerSlot);
        priceSet = uint80(curAllPrices & ((2 ** (MakerTypes.ONE_PRICE_BIT)) - 1));
    }

    /// @notice get one token index. odd for none-stable, even for stable,  true index = (tokenIndex[address] - 1) / 2
    function getOneTokenOriginIndex(address token) public view returns (int256) {
        //require(state.priceListInfo.tokenIndexMap[token] > 0, Errors.INVALID_TOKEN);
        return int256(state.priceListInfo.tokenIndexMap[token]) - 1;
    }

    /// @notice get all stable token Info
    /// @return numberOfStable stable tokens' quantity
    /// @return tokenPriceStable stable tokens' price slot array. each data contains up to 3 token prices
    function getStableTokenInfo()
        external
        view
        returns (uint256 numberOfStable, uint256[] memory tokenPriceStable, uint256 curFlag)
    {
        numberOfStable = state.priceListInfo.numberOfStable;
        tokenPriceStable = state.priceListInfo.tokenPriceStable;
        curFlag = ID3MM(_POOL_).allFlag();
    }

    /// @notice get all non-stable token Info
    /// @return number stable tokens' quantity
    /// @return tokenPrices stable tokens' price slot array. each data contains up to 3 token prices
    function getNSTokenInfo() external view returns (uint256 number, uint256[] memory tokenPrices, uint256 curFlag) {
        number = state.priceListInfo.numberOfNS;
        tokenPrices = state.priceListInfo.tokenPriceNS;
        curFlag = ID3MM(_POOL_).allFlag();
    }

    /// @notice used for construct several price in one price slot
    /// @param priceSlot origin price slot
    /// @param slotInnerIndex token index in slot
    /// @param priceSet the token info needed to update
    function stickPrice(
        uint256 priceSlot,
        uint256 slotInnerIndex,
        uint256 priceSet
    ) public pure returns (uint256 newPriceSlot) {
        uint256 leftPriceSet = priceSlot >> ((slotInnerIndex + 1) * MakerTypes.ONE_PRICE_BIT);
        uint256 rightPriceSet = priceSlot & ((2 ** (slotInnerIndex * MakerTypes.ONE_PRICE_BIT)) - 1);
        newPriceSlot = (leftPriceSet << ((slotInnerIndex + 1) * MakerTypes.ONE_PRICE_BIT))
            + (priceSet << (slotInnerIndex * MakerTypes.ONE_PRICE_BIT)) + rightPriceSet;
    }

    function checkHeartbeat() public view returns (bool) {
        if (block.timestamp - state.heartBeat.lastHeartBeat <= state.heartBeat.maxInterval) {
            return true;
        } else {
            return false;
        }
    }

    function getPoolTokenListFromMaker() external view returns(address[] memory tokenlist) {
        return poolTokenlist;
    }

    // ============= Set params ===========

    /// @notice maker could use multicall to set different params in one tx.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            results[i] = result;
        }
    }

    /// @notice maker set a new token info
    /// @param token token's address
    /// @param priceSet packed price, [mid price(16) | mid price decimal(8) | fee rate(16) | ask up rate (16) | bid down rate(16)]
    /// @param amountSet describe ask and bid amount and K, [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ] = one slot could contains 4 token info
    /// @param stableOrNot describe this token is stable or not, true = stable coin
    /// @param kAsk k of ask curve
    /// @param kBid k of bid curve
    function setNewToken(
        address token,
        bool stableOrNot,
        uint80 priceSet,
        uint64 amountSet,
        uint16 kAsk,
        uint16 kBid
    ) external onlyOwner {
        require(state.priceListInfo.tokenIndexMap[token] == 0, Errors.HAVE_SET_TOKEN_INFO);
        // check amount
        require(kAsk >= 0 && kAsk <= 10000, Errors.K_LIMIT);
        require(kBid >= 0 && kBid <= 10000, Errors.K_LIMIT);
        poolTokenlist.push(token);

        // set new token info
        state.tokenMMInfoMap[token].priceInfo = priceSet;
        state.tokenMMInfoMap[token].amountInfo = amountSet;
        state.tokenMMInfoMap[token].kAsk = kAsk;
        state.tokenMMInfoMap[token].kBid = kBid;
        state.heartBeat.lastHeartBeat = block.timestamp;

        // set token price index
        uint256 tokenIndex;
        if (stableOrNot) {
            // is stable
            tokenIndex = state.priceListInfo.numberOfStable * 2;
            uint256 innerSlotIndex = state.priceListInfo.numberOfStable % MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;
            uint256 slotIndex = state.priceListInfo.numberOfStable / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;
            if (innerSlotIndex == 0) {
                state.priceListInfo.tokenPriceStable.push(priceSet);
            } else {
                state.priceListInfo.tokenPriceStable[slotIndex] = (
                    uint256(priceSet) << (MakerTypes.ONE_PRICE_BIT * innerSlotIndex)
                ) + state.priceListInfo.tokenPriceStable[slotIndex];
            }
            state.priceListInfo.numberOfStable++;
        } else {
            tokenIndex = state.priceListInfo.numberOfNS * 2 + 1;
            uint256 innerSlotIndex = state.priceListInfo.numberOfNS % MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;
            uint256 slotIndex = state.priceListInfo.numberOfNS / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;
            if (innerSlotIndex == 0) {
                state.priceListInfo.tokenPriceNS.push(priceSet);
            } else {
                state.priceListInfo.tokenPriceNS[slotIndex] = (
                    uint256(priceSet) << (MakerTypes.ONE_PRICE_BIT * innerSlotIndex)
                ) + state.priceListInfo.tokenPriceNS[slotIndex];
            }
            state.priceListInfo.numberOfNS++;
        }
        // to avoid reset the same token, tokenIndexMap record index from 1, but actualIndex = tokenIndex[address] - 1
        state.priceListInfo.tokenIndexMap[token] = tokenIndex + 1;
        state.tokenMMInfoMap[token].tokenIndex = uint16(tokenIndex);

        emit SetNewToken(token);
    }

    /// @notice set token prices
    /// @param tokens token address set
    /// @param tokenPrices token prices set, each number pack one token all price.Each format is the same with priceSet
    /// [mid price(16) | mid price decimal(8) | fee rate(16) | ask up rate (16) | bid down rate(16)] = one slot could contains 3 token info
    function setTokensPrice(
        address[] calldata tokens,
        uint80[] calldata tokenPrices
    ) external onlyOwner {
        require(tokens.length == tokenPrices.length, Errors.PRICES_LENGTH_NOT_MATCH);
        uint256[] memory haveWrittenToken = new uint256[](tokens.length);
        uint256 curFlag = ID3MM(_POOL_).allFlag();

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (haveWrittenToken[i] == 1) continue;

            haveWrittenToken[i] = 1;
            address curToken = tokens[i];
            uint80 curTokenPriceSet = tokenPrices[i];
            //_checkUpAndDownPrice(curTokenPriceSet);

            {
                uint256 tokenIndex = state.priceListInfo.tokenIndexMap[curToken] - 1;
                curFlag = curFlag & ~(1 << tokenIndex);
            }

            // get slot price
            uint256 curTokenIndex = (state.priceListInfo.tokenIndexMap[curToken] - 1) / 2;
            uint256 slotIndex = curTokenIndex / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT;
            uint256 priceInfoSet = (state.priceListInfo.tokenIndexMap[curToken] - 1) % 2 == 1
                ? state.priceListInfo.tokenPriceNS[slotIndex]
                : state.priceListInfo.tokenPriceStable[slotIndex];

            priceInfoSet = stickPrice(
                priceInfoSet, curTokenIndex % MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT, uint256(curTokenPriceSet)
            );

            // find one slot token
            for (uint256 j = i + 1; j < tokens.length; ++j) {
                address tokenJ = tokens[j];
                uint256 tokenJOriIndex = (state.priceListInfo.tokenIndexMap[tokenJ] - 1);
                if (
                    haveWrittenToken[j] == 1 // have written
                        || (state.priceListInfo.tokenIndexMap[curToken] - 1) % 2 != tokenJOriIndex % 2 // not the same stable type
                        || tokenJOriIndex / 2 / MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT != slotIndex
                ) {
                    // not one slot
                    continue;
                }
                //_checkUpAndDownPrice(tokenPrices[j]);
                priceInfoSet = stickPrice(
                    priceInfoSet, (tokenJOriIndex / 2) % MakerTypes.PRICE_QUANTITY_IN_ONE_SLOT, uint256(tokenPrices[j])
                );

                haveWrittenToken[j] = 1;
                {
                    uint256 tokenIndex = state.priceListInfo.tokenIndexMap[tokenJ] - 1;
                    curFlag = curFlag & ~(1 << tokenIndex);
                }
            }

            if ((state.priceListInfo.tokenIndexMap[curToken] - 1) % 2 == 1) {
                state.priceListInfo.tokenPriceNS[slotIndex] = priceInfoSet;
            } else {
                state.priceListInfo.tokenPriceStable[slotIndex] = priceInfoSet;
            }
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
        ID3MM(_POOL_).setNewAllFlag(curFlag);

        emit SetPoolInfo(2);
    }

    /// @notice user set PriceListInfo.tokenPriceNS price info, only for none-stable coin
    /// @param slotIndex tokenPriceNS index
    /// @param priceSlots tokenPriceNS price info, every data has packed all 3 token price info
    /// @param newAllFlag maker update token cumulative status,
    /// for allFlag, tokenOriIndex represent bit index in allFlag. eg: tokenA has origin index 3, that means (allFlag >> 3) & 1 = token3's flag
    /// flag = 0 means to reset cumulative. flag = 1 means not to reset cumulative.
    /// @dev maker should be responsible for data availability
    function setNSPriceSlot(
        uint256[] calldata slotIndex,
        uint256[] calldata priceSlots,
        uint256 newAllFlag
    ) external onlyOwner {
        require(slotIndex.length == priceSlots.length, Errors.PRICE_SLOT_LENGTH_NOT_MATCH);
        for (uint256 i = 0; i < slotIndex.length; ++i) {
            state.priceListInfo.tokenPriceNS[slotIndex[i]] = priceSlots[i];
        }
        ID3MM(_POOL_).setNewAllFlag(newAllFlag);
        state.heartBeat.lastHeartBeat = block.timestamp;

        emit SetPoolInfo(3);
    }

    /// @notice user set PriceListInfo.tokenPriceStable price info, only for stable coin
    /// @param slotIndex tokenPriceStable index
    /// @param priceSlots tokenPriceStable price info, every data has packed all 3 token price info
    /// @param newAllFlag maker update token cumulative status,
    /// for allFlag, tokenOriIndex represent bit index in allFlag. eg: tokenA has origin index 3, that means (allFlag >> 3) & 1 = token3's flag
    /// flag = 0 means to reset cumulative. flag = 1 means not to reset cumulative.
    /// @dev maker should be responsible for data availability
    function setStablePriceSlot(
        uint256[] calldata slotIndex,
        uint256[] calldata priceSlots,
        uint256 newAllFlag
    ) external onlyOwner {
        require(slotIndex.length == priceSlots.length, Errors.PRICE_SLOT_LENGTH_NOT_MATCH);
        for (uint256 i = 0; i < slotIndex.length; ++i) {
            state.priceListInfo.tokenPriceStable[slotIndex[i]] = priceSlots[i];
        }
        ID3MM(_POOL_).setNewAllFlag(newAllFlag);
        state.heartBeat.lastHeartBeat = block.timestamp;

        emit SetPoolInfo(4);
    }

    /// @notice set token Amounts
    /// @param tokens token address set
    /// @param tokenAmounts token amounts set, each number pack one token all amounts.Each format is the same with amountSetAndK
    /// [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function setTokensAmounts(
        address[] calldata tokens,
        uint64[] calldata tokenAmounts
    ) external onlyOwner {
        require(tokens.length == tokenAmounts.length, Errors.AMOUNTS_LENGTH_NOT_MATCH);
        uint256 curFlag = ID3MM(_POOL_).allFlag();
        for (uint256 i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint64 curTokenAmountSet = tokenAmounts[i];

            state.tokenMMInfoMap[curToken].amountInfo = curTokenAmountSet;
            {
                uint256 tokenIndex = state.priceListInfo.tokenIndexMap[curToken] - 1;
                curFlag = curFlag & ~(1 << tokenIndex);
            }
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
        ID3MM(_POOL_).setNewAllFlag(curFlag);

        emit SetPoolInfo(5);
    }

    /// @notice set token Ks
    /// @param tokens token address set
    /// @param tokenKs token k_ask and k_bid, structure like [kAsk(16) | kBid(16)]
    function setTokensKs(address[] calldata tokens, uint32[] calldata tokenKs) external onlyOwner {
        require(tokens.length == tokenKs.length, Errors.K_LENGTH_NOT_MATCH);
        uint256 curFlag = ID3MM(_POOL_).allFlag();
        for (uint256 i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint32 curTokenK = tokenKs[i];
            uint16 kAsk = uint16(curTokenK >> 16);
            uint16 kBid = uint16(curTokenK & 0xffff);

            require(kAsk >= 0 && kAsk <= 10000, Errors.K_LIMIT);
            require(kBid >= 0 && kBid <= 10000, Errors.K_LIMIT);

            state.tokenMMInfoMap[curToken].kAsk = kAsk;
            state.tokenMMInfoMap[curToken].kBid = kBid;

            {
                uint256 tokenIndex = state.priceListInfo.tokenIndexMap[curToken] - 1;
                curFlag = curFlag & ~(1 << tokenIndex);
            }
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
        ID3MM(_POOL_).setNewAllFlag(curFlag);

        emit SetPoolInfo(6);
    }

    /// @notice set acceptable setting interval, if setting gap > maxInterval, swap will revert.
    function setHeartbeat(uint256 newMaxInterval) public onlyOwner {
        state.heartBeat.maxInterval = newMaxInterval;

        emit SetPoolInfo(1);
    }
}