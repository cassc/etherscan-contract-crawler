// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {DefiiWithParams} from "../DefiiWithParams.sol";

contract KyberswapAvalancheUsdceUsdc is DefiiWithParams, ERC721Holder {
    IAntiSnipAttackPositionManager constant nfpManager =
        IAntiSnipAttackPositionManager(
            0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8
        );
    IElasticLiquidityMining constant mining =
        IElasticLiquidityMining(0xBdEc4a045446F583dc564C0A227FFd475b329bf0);
    IERC20 constant USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    IERC20 constant USDCe = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    function encodeParams(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external view returns (bytes memory encodedParams) {
        address pool = nfpManager.factory().getPool(
            address(USDC),
            address(USDCe),
            fee
        );

        uint256 poolLength = mining.poolLength();
        uint256 poolId = poolLength;
        for (uint256 i = 0; i < mining.poolLength(); i++) {
            (
                address poolAddress,
                uint32 startTime,
                uint32 endTime,
                ,
                ,
                ,
                ,
                ,

            ) = mining.getPoolInfo(i);
            if (
                poolAddress == pool &&
                startTime < block.timestamp &&
                endTime > block.timestamp
            ) {
                poolId = i;
                break;
            }
        }
        require(poolId < poolLength, "MINING POOL NOT FOUND");
        encodedParams = abi.encode(tickLower, tickUpper, fee, poolId);
    }

    function _enterWithParams(bytes memory params) internal override {
        require(!hasAllocation(), "DO EXIT FIRST");

        USDC.approve(address(nfpManager), type(uint256).max);
        USDCe.approve(address(nfpManager), type(uint256).max);

        (int24 tickLower, int24 tickUpper, uint24 fee, uint256 poolId) = abi
            .decode(params, (int24, int24, uint24, uint256));

        int24[2] memory ticksPrevious;
        (uint256 tokenId, uint128 liquidity, , ) = nfpManager.mint(
            IAntiSnipAttackPositionManager.MintParams({
                token0: address(USDCe),
                token1: address(USDC),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                ticksPrevious: ticksPrevious,
                amount0Desired: USDCe.balanceOf(address(this)),
                amount1Desired: USDC.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        nfpManager.approve(address(mining), tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        mining.deposit(tokenIds);

        uint256[] memory liqs = new uint256[](1);
        liqs[0] = liquidity;
        mining.join(poolId, tokenIds, liqs);

        USDC.approve(address(nfpManager), 0);
        USDCe.approve(address(nfpManager), 0);
    }

    function _exit() internal override {
        if (!hasAllocation()) {
            return;
        }

        _claim();
        // We don't expect DOS, because we have only 1 joined NFT for 1 pool (restriction in _enter)
        uint256 tokenId = mining.getDepositedNFTs(address(this))[0];
        uint256 poolId = mining.getJoinedPools(tokenId)[0];

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        uint256[] memory liqs = new uint256[](1);
        (, , liqs[0]) = mining.stakes(tokenId, poolId);
        mining.exit(poolId, tokenIds, liqs);
        mining.withdraw(tokenIds);

        IAntiSnipAttackPositionManager.Position memory position;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (position, ) = nfpManager.positions(tokenIds[i]);

            nfpManager.removeLiquidity(
                IAntiSnipAttackPositionManager.RemoveLiquidityParams({
                    tokenId: tokenIds[i],
                    liquidity: position.liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        }
        nfpManager.transferAllTokens(address(USDC), 0, address(this));
        nfpManager.transferAllTokens(address(USDCe), 0, address(this));
    }

    function _harvest() internal override {
        _claim();
        _withdrawETH();
    }

    function _withdrawFunds() internal override {
        _withdrawERC20(USDC);
        _withdrawERC20(USDCe);
        _withdrawETH();
    }

    function _claim() internal {
        // We don't expect DOS, because we have only 1 joined NFT (restriction in _enter)
        uint256[] memory tokenIds = mining.getDepositedNFTs(address(this));
        bytes[] memory datas = new bytes[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            datas[i] = abi.encode(
                IElasticLiquidityMining.HarvestData({
                    pIds: mining.getJoinedPools(tokenIds[i])
                })
            );
        }
        mining.harvestMultiplePools(tokenIds, datas);
    }

    function hasAllocation() public view override returns (bool) {
        return mining.getDepositedNFTs(address(this)).length > 0;
    }
}

interface IAntiSnipAttackPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24[2] ticksPrevious;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function factory() external view returns (IFactory);

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    struct Position {
        uint96 nonce;
        address operator;
        uint80 poolId;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 rTokenOwed;
        uint256 feeGrowthInsideLast;
    }

    struct PoolInfo {
        address token0;
        uint24 fee;
        address token1;
    }

    function positions(uint256 tokenId)
        external
        view
        returns (Position memory pos, PoolInfo memory info);

    function approve(address to, uint256 tokenId) external;

    function transferAllTokens(
        address token,
        uint256 minAmount,
        address recipient
    ) external;
}

interface IFactory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external view returns (address pool);
}

interface IElasticLiquidityMining {
    struct RewardData {
        address rewardToken;
        uint256 rewardUnclaimed;
    }

    struct LMPoolInfo {
        address poolAddress;
        uint32 startTime;
        uint32 endTime;
        uint32 vestingDuration;
        uint256 totalSecondsClaimed; // scaled by (1 << 96)
        RewardData[] rewards;
        uint256 feeTarget;
        uint256 numStakes;
    }

    struct HarvestData {
        uint256[] pIds;
    }

    function deposit(uint256[] calldata nftIds) external;

    function withdraw(uint256[] calldata nftIds) external;

    function getDepositedNFTs(address user)
        external
        view
        returns (uint256[] memory listNFTs);

    function poolLength() external view returns (uint256);

    function getPoolInfo(uint256 pId)
        external
        view
        returns (
            address poolAddress,
            uint32 startTime,
            uint32 endTime,
            uint32 vestingDuration,
            uint256 totalSecondsClaimed,
            uint256 feeTarget,
            uint256 numStakes,
            //index reward => reward data
            address[] memory rewardTokens,
            uint256[] memory rewardUnclaimeds
        );

    function join(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;

    function getJoinedPools(uint256 nftId)
        external
        view
        returns (uint256[] memory poolIds);

    function harvestMultiplePools(
        uint256[] calldata nftIds,
        bytes[] calldata datas
    ) external;

    function stakes(uint256 nftId, uint256 pid)
        external
        view
        returns (
            uint128 secondsPerLiquidityLast,
            int256 feeFirst,
            uint256 liquidity
        );

    function exit(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;
}