// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IFlashStrategySushiSwapFactory.sol";
import "./interfaces/IFlashStrategySushiSwap.sol";
import "./interfaces/IFarmingLPTokenFactory.sol";
import "./interfaces/IFarmingLPToken.sol";
import "./interfaces/ISousChef.sol";
import "./interfaces/IFSushiBill.sol";

interface IFlashProtocol_ {
    function stake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo,
        bool _issueNFT
    )
        external
        returns (
            address stakerAddress,
            address strategyAddress,
            uint256 stakeStartTs,
            uint256 stakeDuration,
            uint256 stakedAmount,
            bool active,
            uint256 nftId,
            uint256 fTokensToUser,
            uint256 fTokensFee,
            uint256 totalFTokenBurned,
            uint256 totalStakedWithdrawn
        );
}

contract FSushiCookV0 {
    using SafeERC20 for IERC20;

    address public immutable flashStrategyFactory;
    address public immutable flpTokenFactory;
    address public immutable sousChef;

    constructor(address _flashStrategyFactory, address _sousChef) {
        flashStrategyFactory = _flashStrategyFactory;
        flpTokenFactory = IFlashStrategySushiSwapFactory(_flashStrategyFactory).flpTokenFactory();
        sousChef = _sousChef;
    }

    function cook(
        uint256 pid,
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary,
        uint256 stakeDuration,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        address flpToken = IFarmingLPTokenFactory(flpTokenFactory).getFarmingLPToken(pid);
        address lpToken = IFarmingLPToken(flpToken).lpToken();

        IUniswapV2Pair(lpToken).permit(msg.sender, address(this), amountLP, deadline, v, r, s);
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amountLP);

        IERC20(lpToken).approve(flpToken, amountLP);
        IFarmingLPToken(flpToken).deposit(amountLP, path0, path1, amountMin, address(this), deadline);

        uint256 amountFLP = IFarmingLPToken(flpToken).balanceOf(address(this));
        address strategy = IFlashStrategySushiSwapFactory(flpTokenFactory).getFlashStrategySushiSwap(pid);

        address protocol = IFlashStrategySushiSwap(strategy).flashProtocol();
        (, , , , , , , uint256 fTokensToUser, , , ) = IFlashProtocol_(protocol).stake(
            strategy,
            amountFLP,
            stakeDuration,
            beneficiary,
            false
        );

        address bill = ISousChef(sousChef).getBill(pid);
        IFSushiBill(bill).deposit(fTokensToUser, msg.sender);
    }
}