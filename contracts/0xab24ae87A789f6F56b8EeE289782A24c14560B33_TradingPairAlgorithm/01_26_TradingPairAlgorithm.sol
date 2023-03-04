// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/PositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/lib/erc20/IErc20ForFactoryFactory.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairConstraints.sol';
import 'contracts/position_trading/AssetTransferData.sol';

struct SwapVars {
    uint256 inputlastCount;
    uint256 buyCount;
    uint256 lastPrice;
    uint256 newPrice;
    uint256 snapPrice;
    uint256 outFee;
    uint256 priceImpact;
    uint256 slippage;
}

struct AddLiquidityVars {
    uint256 assetBCode;
    uint256 countB;
    uint256 lastAssetACount;
    uint256 lastCountA;
    uint256 lastCountB;
    uint256 liquidityTokensToMint;
}

struct SwapSnapshot {
    uint256 input;
    uint256 output;
    uint256 slippage;
}

struct PositionAddingAssets {
    ItemRef asset1;
    ItemRef asset2;
}

contract TradingPairAlgorithm is PositionAlgorithm, ITradingPairAlgorithm {
    using ItemRefAsAssetLibrary for ItemRef;

    uint256 public constant priceDecimals = 1e18;

    mapping(uint256 => FeeSettings) public fee;
    mapping(uint256 => TradingPairConstraints) public constraints;
    mapping(uint256 => IErc20ForFactory) public liquidityTokens;
    mapping(uint256 => IErc20ForFactory) public feeTokens;
    mapping(uint256 => address) public feeDistributers;
    IErc20ForFactoryFactory public erc20Factory;

    constructor(address positionsControllerAddress, address erc20Factory_)
        PositionAlgorithm(positionsControllerAddress)
    {
        erc20Factory = IErc20ForFactoryFactory(erc20Factory_);
    }

    receive() external payable {}

    function createAlgorithm(
        uint256 positionId,
        FeeSettings calldata feeSettings,
        TradingPairConstraints calldata constraints_
    ) external onlyFactory {
        positionsController.setAlgorithm(positionId, address(this));

        // set fee settings
        fee[positionId] = feeSettings;

        // constraints
        constraints[positionId] = constraints_;

        // getting assets refs
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);

        // calc support decimals
        uint8 decimals = own.getDecimals();
        if (out.getDecimals() > decimals) decimals = out.getDecimals();

        IErc20ForFactory liquidityToken = erc20Factory.create(
            'liquidity',
            'LIQ',
            decimals
        );
        IErc20ForFactory feeToken = erc20Factory.create('fee', 'FEE', decimals);
        liquidityTokens[positionId] = liquidityToken;
        feeTokens[positionId] = feeToken;
        liquidityToken.mintTo(
            positionsController.ownerOf(positionId),
            own.count() * out.count()
        );
        feeToken.mintTo(
            positionsController.ownerOf(positionId),
            own.count() * out.count()
        );
        // create fee distributor
        TradingPairFeeDistributer feeDistributer = new TradingPairFeeDistributer(
                positionId,
                address(this),
                address(feeToken),
                positionsController.getAssetReference(positionId, 1),
                positionsController.getAssetReference(positionId, 2),
                feeSettings.feeRoundIntervalHours
            );
        feeDistributers[positionId] = address(feeDistributer);
        // transfer the owner to the fee distributor
        //feeasset1.transferOwnership(address(feeDistributer)); // todo проверить работоспособность!!!
        //feeasset2.transferOwnership(address(feeDistributer));
    }

    function getFeeSettings(uint256 positionId)
        external
        view
        returns (FeeSettings memory)
    {
        return fee[positionId];
    }

    function getConstraints(uint256 positionId)
        external
        view
        returns (TradingPairConstraints memory)
    {
        return constraints[positionId];
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return address(liquidityTokens[positionId]) != address(0); // position lock automatically, after adding the algorithm
    }

    function _isPermanentLock(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return _positionLocked(positionId); // position lock automatically, after adding the algorithm
    }

    function addLiquidity(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external payable returns (uint256 ethSurplus) {
        ethSurplus = msg.value;
        // position must be created
        require(
            address(liquidityTokens[positionId]) != address(0),
            'position id is not exists'
        );
        AddLiquidityVars memory vars;
        vars.assetBCode = 1;
        if (assetCode == vars.assetBCode) vars.assetBCode = 2;
        // get assets
        ItemRef memory assetA = positionsController.getAssetReference(
            positionId,
            assetCode
        );
        ItemRef memory assetB = positionsController.getAssetReference(
            positionId,
            vars.assetBCode
        );
        // take total supply of liquidity tokens
        IErc20ForFactory liquidityToken = liquidityTokens[positionId];

        vars.countB = (count * assetB.count()) / assetA.count();

        // save the last asset count
        vars.lastAssetACount = assetA.count();
        //uint256 lastAssetBCount = assetB.count();
        // transfer from adding assets
        assetA.setNotifyListener(false);
        assetB.setNotifyListener(false);
        uint256[] memory data;
        vars.lastCountA = assetA.count();
        vars.lastCountB = assetB.count();
        ethSurplus = positionsController.transferToAssetFrom{
            value: ethSurplus
        }(msg.sender, positionId, assetCode, count, data);
        ethSurplus = positionsController.transferToAssetFrom{
            value: ethSurplus
        }(msg.sender, positionId, vars.assetBCode, vars.countB, data);
        require(
            assetA.count() == vars.lastCountA + count,
            'transferred asset 1 count to pair is not correct'
        );
        require(
            assetB.count() == vars.lastCountB + vars.countB,
            'transferred asset 2 count to pair is not correct'
        );
        assetA.setNotifyListener(true);
        assetB.setNotifyListener(true);
        // mint liquidity tokens
        vars.liquidityTokensToMint =
            (liquidityToken.totalSupply() *
                (assetA.count() - vars.lastAssetACount)) /
            vars.lastAssetACount;
        liquidityToken.mintTo(msg.sender, vars.liquidityTokensToMint);
        // mint fee tokens
        IErc20ForFactory feeToken = feeTokens[positionId];
        feeToken.mintTo(
            msg.sender,
            (feeToken.totalSupply() * (assetA.count() - vars.lastAssetACount)) /
                vars.lastAssetACount
        );

        // log event
        if (assetCode == 1) {
            emit OnAddLiquidity(
                positionId,
                msg.sender,
                count,
                vars.countB,
                vars.liquidityTokensToMint
            );
        } else {
            emit OnAddLiquidity(
                positionId,
                msg.sender,
                vars.countB,
                count,
                vars.liquidityTokensToMint
            );
        }

        // revert eth surplus
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function _getAssets(uint256 positionId)
        internal
        view
        returns (ItemRef memory asset1, ItemRef memory asset2)
    {
        ItemRef memory asset1 = positionsController.getAssetReference(
            positionId,
            1
        );
        ItemRef memory asset2 = positionsController.getAssetReference(
            positionId,
            2
        );
        require(asset1.id != 0, 'owner asset required');
        require(asset2.id != 0, 'output asset required');

        return (asset1, asset2);
    }

    function getAsset1Price(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getAsset1Price(positionId);
    }

    function _getAsset1Price(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 ownerCount = asset1.count();
        uint256 outputCount = asset2.count();
        require(outputCount > 0, 'has no output count');
        return ownerCount / outputCount;
    }

    function getAsset2Price(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getAsset2Price(positionId);
    }

    function _getAsset2Price(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 ownerCount = asset1.count();
        uint256 outputCount = asset2.count();
        require(outputCount > 0, 'has no output count');
        return outputCount / ownerCount;
    }

    function getBuyCount(
        uint256 positionId,
        uint256 inputAssetCode,
        uint256 amount
    ) external view returns (uint256) {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 inputLastCount;
        uint256 outputLastCount;
        if (inputAssetCode == 1) {
            inputLastCount = asset1.count();
            outputLastCount = asset2.count();
        } else if (inputAssetCode == 2) {
            inputLastCount = asset2.count();
            outputLastCount = asset1.count();
        } else revert('incorrect asset code');
        return
            _getBuyCount(
                inputLastCount,
                inputLastCount + amount,
                outputLastCount
            );
    }

    function _getBuyCount(
        uint256 inputLastCount,
        uint256 inputNewCount,
        uint256 outputLastCount
    ) internal pure returns (uint256) {
        return
            outputLastCount -
            ((inputLastCount * outputLastCount) / inputNewCount);
    }

    function _afterAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
        override
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(
            arg.positionId
        );
        // transfers from assets are not processed
        if (arg.from == asset1.addr || arg.from == asset2.addr) return;
        // swap only if editing is locked
        require(_positionLocked(arg.positionId), 'no lk pos');
        // if there is no snapshot, then we do nothing
        require(arg.data.length == 3, 'no snpsht');

        // take fee
        FeeSettings memory feeSettings = fee[arg.positionId];
        // make a swap
        if (arg.assetCode == 2) {
            // if the exchange is direct
            require(
                !constraints[arg.positionId].disableForwardSwap,
                'forward swap is disallowed'
            );
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset2,
                asset1,
                feeSettings.asset2,
                feeSettings.asset1,
                SwapSnapshot(arg.data[1], arg.data[0], arg.data[2]),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(2),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(1)
            );
        } else {
            require(
                !constraints[arg.positionId].disableBackSwap,
                'back swap is disallowed'
            );
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset1,
                asset2,
                feeSettings.asset1,
                feeSettings.asset2,
                SwapSnapshot(arg.data[0], arg.data[1], arg.data[2]),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(1),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(2)
            );
        }
    }

    function _swap(
        uint256 positionId,
        address from,
        uint256 amount,
        ItemRef memory input,
        ItemRef memory output,
        AssetFee memory inputFee,
        AssetFee memory outputFee,
        SwapSnapshot memory snapshot,
        ItemRef memory inputFeeAsset,
        ItemRef memory outputFeeAsset
    ) internal {
        SwapVars memory vars;
        // count how much bought
        vars.inputlastCount = input.count() - amount;
        vars.buyCount = _getBuyCount(
            vars.inputlastCount,
            input.count(),
            output.count()
        );
        require(vars.buyCount <= output.count(), 'not enough asset to buy');

        // count the old price
        vars.lastPrice = (vars.inputlastCount * priceDecimals) / output.count();
        if (vars.lastPrice == 0) vars.lastPrice = 1;

        // fee counting
        if (inputFee.input > 0) {
            positionsController.transferToAnotherAssetInternal(
                input,
                inputFeeAsset,
                (inputFee.input * amount) / 10000
            );
        }
        if (outputFee.output > 0) {
            vars.outFee = (outputFee.output * vars.buyCount) / 10000;
            vars.buyCount -= vars.outFee;
            positionsController.transferToAnotherAssetInternal(
                output,
                outputFeeAsset,
                vars.outFee
            );
        }

        // transfer the asset
        uint256 devFee = (vars.buyCount *
            positionsController.getFeeSettings().feePercent()) /
            positionsController.getFeeSettings().feeDecimals();
        if (devFee > 0) {
            positionsController.withdrawInternal(
                output,
                positionsController.getFeeSettings().feeAddress(),
                devFee
            );
            positionsController.withdrawInternal(
                output,
                from,
                vars.buyCount - devFee
            );
        } else {
            positionsController.withdrawInternal(output, from, vars.buyCount);
        }

        // count the old price
        vars.newPrice = (input.count() * priceDecimals) / output.count();
        if (vars.newPrice == 0) vars.newPrice = 1;

        // count the snapshot price
        vars.snapPrice = (snapshot.input * priceDecimals) / snapshot.output;
        if (vars.snapPrice == 0) vars.snapPrice = 1;
        // slippage limiter
        if (vars.newPrice >= vars.snapPrice)
            vars.slippage = (vars.newPrice * priceDecimals) / vars.snapPrice;
        else vars.slippage = (vars.snapPrice * priceDecimals) / vars.newPrice;

        require(vars.slippage <= snapshot.slippage, 'chngd more than slppg');

        // price should not change more than 50%
        vars.priceImpact = (vars.newPrice * priceDecimals) / vars.lastPrice;
        require(
            vars.priceImpact <= priceDecimals + priceDecimals / 2, // 150% of priceDecimals
            'large impct'
        );

        // event
        emit OnSwap(
            positionId,
            from,
            input.id,
            output.id,
            amount,
            vars.buyCount
        );
    }

    function withdraw(uint256 positionId, uint256 liquidityCount) external {
        // take a tokens
        IErc20ForFactory liquidityToken = liquidityTokens[positionId];
        IErc20ForFactory feeToken = feeTokens[positionId];
        require(address(liquidityToken) != address(0), 'no lquidity tokens');
        require(
            liquidityToken.balanceOf(msg.sender) >= liquidityCount,
            'not enough liquidity tokens balance'
        );
        require(
            address(feeToken) == address(0) ||
                feeToken.balanceOf(msg.sender) >= liquidityCount,
            'not enough fee tokens balance'
        );
        // take assets
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);
        // withdraw of owner asset
        uint256 asset1Count = (own.count() * liquidityCount) /
            liquidityToken.totalSupply();
        positionsController.withdrawInternal(own, msg.sender, asset1Count);
        // withdraw asset output
        uint256 asset2Count = (out.count() * liquidityCount) /
            liquidityToken.totalSupply();
        positionsController.withdrawInternal(out, msg.sender, asset2Count);

        // burn liquidity and fee tokens
        liquidityToken.burn(msg.sender, liquidityCount);
        if (address(feeToken) != address(0))
            feeToken.burn(msg.sender, liquidityCount);

        // log event
        emit OnRemoveLiquidity(
            positionId,
            msg.sender,
            asset1Count,
            asset2Count,
            liquidityCount
        );
    }

    function checkCanWithdraw(
        ItemRef calldata asset,
        uint256 assetCode,
        uint256 count
    ) external view {
        require(!this.positionLocked(asset.getPositionId()), 'locked');
    }

    function getSnapshot(uint256 positionId, uint256 slippage)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            positionsController.getAssetReference(positionId, 1).count(),
            positionsController.getAssetReference(positionId, 2).count(),
            priceDecimals + slippage
        );
    }

    function getPositionsController() external view returns (address) {
        return address(positionsController);
    }

    function getLiquidityToken(uint256 positionId)
        external
        view
        returns (address)
    {
        return address(liquidityTokens[positionId]);
    }

    function getFeeToken(uint256 positionId) external view returns (address) {
        return address(feeTokens[positionId]);
    }

    function getFeeDistributer(uint256 positionId)
        external
        view
        returns (address)
    {
        return feeDistributers[positionId];
    }

    function ClaimFeeReward(
        uint256 positionId,
        address account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 feeTokensCount
    ) external {
        require(feeDistributers[positionId] == msg.sender);
        emit OnClaimFeeReward(
            positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );
    }
}