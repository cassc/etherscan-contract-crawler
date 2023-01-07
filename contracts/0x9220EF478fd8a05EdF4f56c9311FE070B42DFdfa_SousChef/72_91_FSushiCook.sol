// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

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

contract FSushiCook {
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
        uint256 deadline
    ) public {
        address flpToken = IFarmingLPTokenFactory(flpTokenFactory).getFarmingLPToken(pid);
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
        //
    }
}