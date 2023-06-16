// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IPosition} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPosition.sol";

import {IPoolPositionSlim} from "./interfaces/IPoolPositionSlim.sol";
import {Utilities} from "./libraries/Utilities.sol";

contract PoolPositionBaseSlim is IPoolPositionSlim, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IPool public immutable override pool;
    bool public immutable isStatic;
    IERC20 immutable tokenA;
    IERC20 immutable tokenB;

    uint128[] public binIds;
    uint128[] public ratios;

    uint256 public immutable tokenId;

    uint256 constant ONE = 1e18;

    // @notice Creates a pool position ERC20 that holds bin liquidity from a
    // Mav AMM pool.  In deploying this contract, the user specifies the
    // liquidity distribution that each minter of the PP ERC20 needs to
    // contribute.  This distribution is specified by the _binIds and _ratios
    // constructor arguments.  Specifically, a new minter will have to add
    // ratios[i] * (binIds[0] bin LP balance) for each bin, i, in
    // binIds. This contract is typically deployed from the Factory and will
    // not properly be paired with the appropiate incentive contract unless
    // deployed from the PoolPositionAndRewardFactorySlim factory.
    // @dev Requirements for constructor
    // - ratios[0] must be 1e18
    // - _binIds and _ratios must be non-empty arrays of the same length
    // - all binIds must be kind=0 unless _binIds.length = 1
    // - _binIds must be sorted in ascending order
    constructor(
        IPool _pool,
        uint128[] memory _binIds,
        uint128[] memory _ratios,
        uint256 factoryCount,
        bool _isStatic
    ) ERC20(Utilities.nameMaker(_pool, factoryCount, true), Utilities.nameMaker(_pool, factoryCount, false)) {
        uint256 binsLength = _binIds.length;
        if (binsLength == 0 || (!_isStatic && binsLength != 1) || binsLength != _ratios.length) revert InvalidBinIds(_binIds);
        if (_ratios[0] != ONE) revert InvalidRatio();

        pool = _pool;
        ratios = _ratios;
        binIds = _binIds;
        tokenId = _pool.factory().position().mint(address(this));
        isStatic = _isStatic;

        tokenA = pool.tokenA();
        tokenB = pool.tokenB();

        uint128 lastBinId;
        IPool.BinState memory bin;
        for (uint256 i; i < binsLength; i++) {
            bin = pool.getBin(_binIds[i]);

            if ((isStatic && bin.kind != 0) || !(_binIds[i] > lastBinId)) revert InvalidBinIds(_binIds);
            lastBinId = _binIds[i];
        }
    }

    modifier checkBin() {
        if (!isStatic && pool.getBin(binIds[0]).mergeId != 0) revert BinIsMerged();
        _;
    }

    //////////////////////////////
    // View Functions
    //////////////////////////////

    /// @inheritdoc IPoolPositionSlim
    function binLpAddAmountRequirement(uint128 binZeroLpAddAmount) external view checkBin returns (IPool.RemoveLiquidityParams[] memory params) {
        params = _binLpAddAmountRequirement(binZeroLpAddAmount);
    }

    /// @inheritdoc IPoolPositionSlim
    function getReserves() external view checkBin returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = _getReserves(tokenId);
    }

    function allBinIds() external view returns (uint128[] memory) {
        return binIds;
    }

    //////////////////////////////
    // Internal Helper Functions
    //////////////////////////////

    function _tokenBinReserves(uint256 _tokenId, uint256 i) internal view returns (uint256 reserveA, uint256 reserveB, uint256 balance) {
        uint128 binId = binIds[i];
        IPool.BinState memory bin = pool.getBin(binId);
        uint128 totalSupply = bin.totalSupply;
        balance = pool.balanceOf(_tokenId, binId);
        reserveA = Math.mulDiv(bin.reserveA, balance, totalSupply);
        reserveB = Math.mulDiv(bin.reserveB, balance, totalSupply);
    }

    function _getReserves(uint256 _tokenId) internal view checkBin returns (uint256 reserveA, uint256 reserveB) {
        uint256 binsLength = binIds.length;
        for (uint256 i; i < binsLength; i++) {
            (uint256 reserveA_, uint256 reserveB_, ) = _tokenBinReserves(_tokenId, i);
            reserveA += reserveA_;
            reserveB += reserveB_;
        }
    }

    function _binLpAddAmountRequirement(uint128 binZeroLpAddAmount) internal view returns (IPool.RemoveLiquidityParams[] memory params) {
        uint256 binsLength = binIds.length;
        params = new IPool.RemoveLiquidityParams[](binsLength);
        params[0] = IPool.RemoveLiquidityParams({binId: binIds[0], amount: binZeroLpAddAmount});

        for (uint256 i = 1; i < binsLength; i++) {
            params[i] = IPool.RemoveLiquidityParams({binId: binIds[i], amount: SafeCast.toUint128(Math.mulDiv(binZeroLpAddAmount, ratios[i], ONE))});
        }
    }

    //////////////////////////////
    // External Admin Functions
    //////////////////////////////

    /// @inheritdoc IPoolPositionSlim
    function migrateBinLiquidity() external virtual {}

    //////////////////////////////
    // Virtual Functions Requiring Override
    //////////////////////////////

    /// @dev update checkpoint array and create a params array with fee
    modifier checkpointLiquidity() virtual {
        _;
    }

    //////////////////////////////
    // Mint / Burn Functions
    //////////////////////////////

    /// @inheritdoc IPoolPositionSlim
    function mint(address to, uint256 fromTokenId, uint128 binZeroLpAddAmount) external override nonReentrant checkBin checkpointLiquidity returns (uint256 amountMinted) {
        if (tokenId == fromTokenId) revert InvalidTokenId(fromTokenId);
        uint256 supply = totalSupply();
        amountMinted = supply == 0 ? binZeroLpAddAmount : Math.mulDiv(binZeroLpAddAmount, supply, pool.balanceOf(tokenId, binIds[0]));

        require(amountMinted != 0, "PP: zero mint");

        pool.transferLiquidity(fromTokenId, tokenId, _binLpAddAmountRequirement(binZeroLpAddAmount));

        _mint(to, amountMinted);
    }

    function _ppBurn(address account, uint256 lpAmountToUnStake) internal checkBin checkpointLiquidity returns (IPool.RemoveLiquidityParams[] memory params) {
        uint256 proRata = Math.mulDiv(ONE, lpAmountToUnStake, totalSupply());

        uint256 binsLength = binIds.length;
        params = new IPool.RemoveLiquidityParams[](binsLength);
        for (uint256 i; i < binsLength; i++) {
            uint256 balance = pool.balanceOf(tokenId, binIds[i]);
            params[i] = IPool.RemoveLiquidityParams({binId: binIds[i], amount: SafeCast.toUint128(Math.mulDiv(balance, proRata, ONE))});
        }
        if (account != msg.sender) _spendAllowance(account, msg.sender, lpAmountToUnStake);
        _burn(account, lpAmountToUnStake);
    }

    /// @inheritdoc IPoolPositionSlim
    function burnFromToTokenIdAsBinLiquidity(address account, uint256 toTokenId, uint256 lpAmountToUnStake) external override nonReentrant returns (IPool.RemoveLiquidityParams[] memory params) {
        params = _ppBurn(account, lpAmountToUnStake);
        pool.transferLiquidity(tokenId, toTokenId, params);
    }

    /// @inheritdoc IPoolPositionSlim
    function burnFromToAddressAsReserves(address account, address recipient, uint256 lpAmountToUnStake) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        IPool.RemoveLiquidityParams[] memory params = _ppBurn(account, lpAmountToUnStake);
        (amountA, amountB, ) = pool.removeLiquidity(recipient, tokenId, params);
    }
}