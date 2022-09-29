pragma solidity ^0.8.17;
import 'contracts/position_trading/algorithms/PositionLockerAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/lib/erc20/Erc20ForFactory.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/FeeDistributer.sol';
import 'contracts/interfaces/IFeeDistributer.sol';
import 'contracts/position_trading/algorithms/PositionLockerBase.sol';

struct AssetFee {
    uint256 input; // position entry fee 1/10000
    uint256 output; // position exit fee 1/10000
}

struct FeeSettings {
    AssetFee ownerAsset;
    AssetFee outputAsset;
}

struct SwapData {
    uint256 inputlastCount;
    uint256 buyCount;
    uint256 lastPrice;
    uint256 newPrice;
    uint256 snapPrice;
    uint256 outFee;
    uint256 priceImpact;
    uint256 slippage;
}

struct SwapSnapshot {
    uint256 input;
    uint256 output;
    uint256 slippage;
}

struct PositionAddingAssets {
    IAsset ownerAsset;
    IAsset outputAsset;
}

contract TradingPair is PositionLockerBase {
    mapping(uint256 => FeeSettings) public fee;
    mapping(uint256 => address) public liquidityTokens;
    mapping(uint256 => address) public feeTokens;
    mapping(uint256 => address) public feeDistributers;
    mapping(uint256 => mapping(address => PositionAddingAssets)) _liquidityAddingAssets;

    event Swap(
        uint256 indexed positionId,
        address indexed account,
        address indexed inputAsset,
        address outputAsset,
        uint256 inputCount,
        uint256 outputCount
    );

    constructor(address positionsControllerAddress)
        PositionLockerBase(positionsControllerAddress)
    {}

    function setAlgorithm(uint256 positionId, FeeSettings calldata feeSettings)
        external
    {
        _setAlgorithm(positionId, feeSettings);
    }

    function _setAlgorithm(uint256 positionId, FeeSettings calldata feeSettings)
        internal
        virtual
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        // set the algorithm
        ContractData memory data;
        data.factory = address(0);
        data.contractAddr = address(this);
        positionsController.setAlgorithm(positionId, data);

        // set fee settings
        fee[positionId] = feeSettings;

        Erc20ForFactory liquidityToken = new Erc20ForFactory(
            'liquidity',
            'LIQ',
            0
        );
        Erc20ForFactory feeToken = new Erc20ForFactory('fee', 'FEE', 0);
        liquidityTokens[positionId] = address(liquidityToken);
        feeTokens[positionId] = address(feeToken);
        (IAsset own, IAsset out) = _getAssets(positionId);
        liquidityToken.mintTo(msg.sender, own.count() * out.count());
        feeToken.mintTo(msg.sender, own.count() * out.count());
        // create assets for fee
        IAsset feeOwnerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        ).clone(address(this));
        IAsset feeOutputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        ).clone(address(this));
        // create fee distributor
        FeeDistributer feeDistributer = new FeeDistributer(
            address(this),
            address(feeToken),
            address(feeOwnerAsset),
            address(feeOutputAsset)
        );
        feeDistributers[positionId] = address(feeDistributer);
        // transfer the owner to the fee distributor
        feeOwnerAsset.transferOwnership(address(feeDistributer));
        feeOutputAsset.transferOwnership(address(feeDistributer));
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return address(liquidityTokens[positionId]) != address(0); // position lock automatically, after adding the algorithm
    }

    function createAddLiquidityAssets(uint256 positionId) external {
        // position must be created
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // re-creation is not allowed
        require(
            address(
                _liquidityAddingAssets[positionId][msg.sender].ownerAsset
            ) == address(0),
            'assets for adding liquidity is already exists'
        );
        // get position assets to clone them
        IAsset ownerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        );
        IAsset outputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        );
        // create liquidity adding assets
        _liquidityAddingAssets[positionId][msg.sender].ownerAsset = ownerAsset
            .clone(address(this));
        _liquidityAddingAssets[positionId][msg.sender].outputAsset = outputAsset
            .clone(address(this));

        _liquidityAddingAssets[positionId][msg.sender]
            .ownerAsset
            .setNotifyListener(false);
        _liquidityAddingAssets[positionId][msg.sender]
            .outputAsset
            .setNotifyListener(false);
    }

    function liquidityAddingAssets(uint256 positionId, address owner)
        external
        view
        returns (PositionAddingAssets memory)
    {
        return _liquidityAddingAssets[positionId][owner];
    }

    function addLiquidityByOwnerAsset(uint256 positionId)
        external
        positionLocked(positionId)
    {
        // position must be created
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // adding assets must exist
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.ownerAsset) != address(0) &&
                address(assets.outputAsset) != address(0),
            'assets for adding liquidity is not exists'
        );
        // take position assets
        IAsset ownerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        );
        IAsset outputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        );
        // counting of the required amount of adding output asset
        uint256 outputCount = (assets.ownerAsset.count() *
            outputAsset.count()) / ownerAsset.count();
        require(
            assets.outputAsset.count() >= outputCount,
            'not enough output adding asset count'
        );
        // take total supply of liquidity tokens
        Erc20ForFactory liquidityTokens = Erc20ForFactory(
            liquidityTokens[positionId]
        );
        // save the last owner asset count
        uint256 lastOwnerAssetCount = ownerAsset.count();
        // transfer from adding assets
        assets.ownerAsset.withdraw(
            address(ownerAsset),
            assets.ownerAsset.count()
        );
        assets.outputAsset.withdraw(address(outputAsset), outputCount);
        // mintim liquidity tokens
        uint256 liquidityTokensToMint = (liquidityTokens.totalSupply() *
            (ownerAsset.count() - lastOwnerAssetCount)) / lastOwnerAssetCount;
        liquidityTokens.mintTo(msg.sender, liquidityTokensToMint);
    }

    function withdrawOwnerAddingLiquidityAsset(uint256 positionId) external {
        // position must be created
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // adding assets must exist
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.ownerAsset) != address(0),
            'asset for adding liquidity is not exists'
        );
        assets.ownerAsset.withdraw(msg.sender, assets.ownerAsset.count());
    }

    function withdrawOutputAddingLiquidityAsset(uint256 positionId) external {
        // position must be created
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // adding assets must exist
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.outputAsset) != address(0),
            'asset for adding liquidity is not exists'
        );
        assets.outputAsset.withdraw(msg.sender, assets.outputAsset.count());
    }

    function _getAssetsAddresses(uint256 positionId)
        internal
        view
        returns (address ownerAsset, address outputAsset)
    {
        address ownerAssetAddr = positionsController
            .getAsset(positionId, 1)
            .contractAddr;
        address outputAssetAddr = positionsController
            .getAsset(positionId, 2)
            .contractAddr;

        return (ownerAssetAddr, outputAssetAddr);
    }

    function _getAssets(uint256 positionId)
        internal
        view
        returns (IAsset ownerAsset, IAsset outputAsset)
    {
        (address ownerAssetAddr, address outputAssetAddr) = _getAssetsAddresses(
            positionId
        );
        require(ownerAssetAddr != address(0), 'owner asset required');
        require(outputAssetAddr != address(0), 'output asset required');

        return (IAsset(ownerAssetAddr), IAsset(outputAssetAddr));
    }

    function getOwnerAssetPrice(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getOwnerAssetPrice(positionId);
    }

    function _getOwnerAssetPrice(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (IAsset ownerAsset, IAsset outputAsset) = _getAssets(positionId);
        uint256 ownerCount = ownerAsset.count();
        uint256 outputCount = outputAsset.count();
        require(outputCount > 0, 'has no output count');
        return ownerCount / outputCount;
    }

    function getOutputAssetPrice(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getOutputAssetPrice(positionId);
    }

    function _getOutputAssetPrice(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (IAsset ownerAsset, IAsset outputAsset) = _getAssets(positionId);
        uint256 ownerCount = ownerAsset.count();
        uint256 outputCount = outputAsset.count();
        require(outputCount > 0, 'has no output count');
        return outputCount / ownerCount;
    }

    function getBuyCount(
        uint256 positionId,
        uint256 inputAssetCode,
        uint256 amount
    ) external returns (uint256) {
        (address ownerAssetAddr, address outputAssetAddr) = _getAssetsAddresses(
            positionId
        );
        IAsset input;
        IAsset output;
        uint256 inputLastCount;
        uint256 outputLastCount;
        if (inputAssetCode == 1) {
            inputLastCount = IAsset(ownerAssetAddr).count();
            outputLastCount = IAsset(outputAssetAddr).count();
        } else if (inputAssetCode == 2) {
            inputLastCount = IAsset(outputAssetAddr).count();
            outputLastCount = IAsset(ownerAssetAddr).count();
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
    ) internal view returns (uint256) {
        return
            outputLastCount -
            ((inputLastCount * outputLastCount) / inputNewCount);
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual override {
        uint256 positionId = positionsController.getAssetPositionId(asset);
        (address ownerAssetAddr, address outputAssetAddr) = _getAssetsAddresses(
            positionId
        );
        // transfers from assets are not processed
        if (from == ownerAssetAddr || from == outputAssetAddr) return;
        // swap only if editing is locked
        require(
            _positionLocked(positionId),
            'swap can be maked only if position editing is locked'
        );
        // if there is no snapshot, then we do nothing
        require(
            data.length == 3,
            'data must be snapshot, where [owner asset, output asset, slippage]'
        );

        // take fee
        FeeSettings memory feeSettings = fee[positionId];
        // make a swap
        if (to == outputAssetAddr)
            // if the exchange is direct
            _swap(
                positionId,
                from,
                amount,
                IAsset(outputAssetAddr),
                IAsset(ownerAssetAddr),
                feeSettings.outputAsset,
                feeSettings.ownerAsset,
                SwapSnapshot(data[1], data[0], data[2]),
                IFeeDistributer(feeDistributers[positionId]).outputAsset(),
                IFeeDistributer(feeDistributers[positionId]).ownerAsset()
            );
        else
            _swap(
                positionId,
                from,
                amount,
                IAsset(ownerAssetAddr),
                IAsset(outputAssetAddr),
                feeSettings.ownerAsset,
                feeSettings.outputAsset,
                SwapSnapshot(data[0], data[1], data[2]),
                IFeeDistributer(feeDistributers[positionId]).ownerAsset(),
                IFeeDistributer(feeDistributers[positionId]).outputAsset()
            );
    }

    function _swap(
        uint256 positionId,
        address from,
        uint256 amount,
        IAsset input,
        IAsset output,
        AssetFee memory inputFee,
        AssetFee memory outputFee,
        SwapSnapshot memory snapshot,
        IAsset inputFeeAsset,
        IAsset outputFeeAsset
    ) internal {
        SwapData memory data;
        // count how much bought
        data.inputlastCount = input.count() - amount;
        data.buyCount = _getBuyCount(
            data.inputlastCount,
            input.count(),
            output.count()
        );
        require(data.buyCount <= output.count(), 'not enough asset to buy');

        // count the old price
        data.lastPrice = (data.inputlastCount * 100000) / output.count();
        // count the snapshot price
        data.snapPrice = (snapshot.input * 100000) / snapshot.output;
        // slip limiter
        if (data.lastPrice >= snapshot.slippage)
            data.slippage = (data.lastPrice * 100000) / data.snapPrice;
        else data.slippage = (data.snapPrice * 100000) / data.lastPrice;
        require(
            data.slippage <= snapshot.slippage,
            'price has changed by more than slippage'
        );

        // fee counting
        if (inputFee.input > 0) {
            input.withdraw(
                address(inputFeeAsset),
                (inputFee.input * amount) / 10000
            );
        }
        if (outputFee.output > 0) {
            data.outFee = (outputFee.output * data.buyCount) / 10000;
            data.buyCount -= data.outFee;
            output.withdraw(address(outputFeeAsset), data.outFee);
        }

        // transfer the asset
        uint256 devFee = (data.buyCount *
            positionsController.getFeeSettings().feePercent()) /
            positionsController.getFeeSettings().feeDecimals();
        if (devFee > 0) {
            output.withdraw(
                positionsController.getFeeSettings().feeAddress(),
                devFee
            );
            output.withdraw(from, data.buyCount - devFee);
        } else {
            output.withdraw(from, data.buyCount);
        }

        // count the old price
        data.newPrice = (input.count() * 100000) / output.count();

        // price should not change more than 50%
        data.priceImpact = (data.newPrice * 100000) / data.lastPrice;
        require(data.priceImpact < 150000, 'too large price impact');

        // event
        emit Swap(
            positionId,
            from,
            address(input),
            address(output),
            amount,
            data.buyCount
        );
    }

    function withdraw(uint256 positionId, uint256 liquidityCount) external {
        // take a token
        address liquidityAddr = liquidityTokens[positionId];
        require(
            liquidityAddr != address(0),
            'algorithm has no liquidity tokens'
        );
        // take assets
        (IAsset own, IAsset out) = _getAssets(positionId);
        // withdraw of owner asset
        own.withdraw(
            msg.sender,
            (own.count() * liquidityCount) /
                Erc20ForFactory(liquidityAddr).totalSupply()
        );
        // withdraw asset output
        out.withdraw(
            msg.sender,
            (out.count() * liquidityCount) /
                Erc20ForFactory(liquidityAddr).totalSupply()
        );

        // burn liquidity token
        Erc20ForFactory(liquidityAddr).burn(msg.sender, liquidityCount);
    }
}