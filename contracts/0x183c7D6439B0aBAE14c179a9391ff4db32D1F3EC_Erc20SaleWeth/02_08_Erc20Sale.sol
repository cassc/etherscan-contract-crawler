// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/fee/IFeeSettings.sol';

struct PositionData {
    address owner;
    address asset1;
    address asset2;
    uint256 priceNom;
    uint256 priceDenom;
    uint256 count1;
    uint256 count2;
}

contract Erc20Sale {
    using SafeERC20 for IERC20;

    IFeeSettings immutable _feeSettings;
    mapping(uint256 => PositionData) _positions;
    uint256 _totalPositions;

    constructor(address feeSettings) {
        _feeSettings = IFeeSettings(feeSettings);
    }

    event OnCreate(
        uint256 indexed positionId,
        address indexed owner,
        address asset1,
        address asset2,
        uint256 priceNom,
        uint256 priceDenom
    );
    event OnBuy(
        uint256 indexed positionId,
        address indexed account,
        uint256 count
    );
    event OnPrice(
        uint256 indexed positionId,
        uint256 priceNom,
        uint256 priceDenom
    );
    event OnWithdraw(
        uint256 indexed positionId,
        uint256 assetCode,
        address to,
        uint256 count
    );

    function createAsset(
        address asset1,
        address asset2,
        uint256 priceNom,
        uint256 priceDenom,
        uint256 count
    ) external {
        if (count > 0) {
            uint256 lastCount = IERC20(asset1).balanceOf(address(this));
            IERC20(asset1).safeTransferFrom(msg.sender, address(this), count);
            count = IERC20(asset1).balanceOf(address(this)) - lastCount;
        }

        _positions[++_totalPositions] = PositionData(
            msg.sender,
            asset1,
            asset2,
            priceNom,
            priceDenom,
            count,
            0
        );

        emit OnCreate(
            _totalPositions,
            msg.sender,
            asset1,
            asset2,
            priceNom,
            priceDenom
        );
    }

    function addBalance(uint256 positionId, uint256 count) external {
        PositionData storage pos = _positions[positionId];
        uint256 lastCount = IERC20(pos.asset1).balanceOf(address(this));
        IERC20(pos.asset1).safeTransferFrom(msg.sender, address(this), count);
        pos.count1 += IERC20(pos.asset1).balanceOf(address(this)) - lastCount;
    }

    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');
        uint256 fee = (_feeSettings.feePercent() * count) /
            _feeSettings.feeDecimals();
        uint256 toWithdraw = count - fee;
        if (assetCode == 1) {
            require(pos.count1 >= count, 'not enough asset count');
            uint256 lastCount = IERC20(pos.asset1).balanceOf(address(this));
            IERC20(pos.asset1).safeTransfer(_feeSettings.feeAddress(), fee);
            IERC20(pos.asset1).safeTransfer(to, toWithdraw);
            uint256 transferred = lastCount -
                IERC20(pos.asset1).balanceOf(address(this));
            require(
                pos.count1 >= transferred,
                'not enough asset count after withdraw'
            );
            pos.count1 -= transferred;
        } else if (assetCode == 2) {
            require(pos.count2 >= count, 'not enough asset count');
            uint256 lastCount = IERC20(pos.asset2).balanceOf(address(this));
            IERC20(pos.asset2).safeTransfer(_feeSettings.feeAddress(), fee);
            IERC20(pos.asset2).safeTransfer(to, toWithdraw);
            uint256 transferred = lastCount -
                IERC20(pos.asset2).balanceOf(address(this));
            require(
                pos.count2 >= transferred,
                'not enough asset count after withdraw'
            );
            pos.count2 -= transferred;
        } else revert('unknown asset code');

        emit OnWithdraw(positionId, assetCode, to, count);
    }

    function setPrice(
        uint256 positionId,
        uint256 priceNom,
        uint256 priceDenom
    ) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');
        pos.priceNom = priceNom;
        pos.priceDenom = priceDenom;
        emit OnPrice(positionId, priceNom, priceDenom);
    }

    function buy(
        uint256 positionId,
        address to,
        uint256 count,
        uint256 priceNom,
        uint256 priceDenom
    ) external {
        PositionData storage pos = _positions[positionId];
        // price frontrun protection
        require(
            pos.priceNom == priceNom && pos.priceDenom == priceDenom,
            'the price is changed'
        );
        uint256 spend = _spendToBuy(pos, count);
        require(
            spend > 0,
            'spend asset count is zero (count parameter is less than minimum count to spend)'
        );
        uint256 buyFee = (count * _feeSettings.feePercent()) /
            _feeSettings.feeDecimals();
        uint256 buyToTransfer = count - buyFee;

        // transfer buy
        require(pos.count1 >= count, 'not enough asset count at position');
        uint256 lastCount = IERC20(pos.asset1).balanceOf(address(this));
        IERC20(pos.asset1).safeTransfer(_feeSettings.feeAddress(), buyFee);
        IERC20(pos.asset1).safeTransfer(to, buyToTransfer);
        uint256 transferred = lastCount -
            IERC20(pos.asset1).balanceOf(address(this));
        require(
            pos.count1 >= transferred,
            'not enough asset count after withdraw'
        );
        pos.count1 -= transferred;

        // transfer spend
        lastCount = IERC20(pos.asset2).balanceOf(address(this));
        IERC20(pos.asset2).safeTransferFrom(msg.sender, address(this), spend);
        pos.count2 += IERC20(pos.asset2).balanceOf(address(this)) - lastCount;

        // emit event
        emit OnBuy(positionId, to, count);
    }

    function spendToBuy(uint256 positionId, uint256 count)
        external
        view
        returns (uint256)
    {
        return _spendToBuy(_positions[positionId], count);
    }

    function _spendToBuy(PositionData memory pos, uint256 count)
        private
        pure
        returns (uint256)
    {
        return (count * pos.priceNom) / pos.priceDenom;
    }

    function getPosition(uint256 positionId)
        external
        view
        returns (PositionData memory)
    {
        return _positions[positionId];
    }
}