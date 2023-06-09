// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./Interfaces/Pendle/IPMarket.sol";
import "./Interfaces/Pendle/IPMarketFactory.sol";
import "./Interfaces/IPendleProxy.sol";
import "@shared/lib-contracts-v0.8/contracts/Dependencies/TransferHelper.sol";

abstract contract PendleProxyBaseUpg is IPendleProxy, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    using TransferHelper for address;

    IPMarketFactory public pendleMarketFactory;
    address public vePendle;

    address public booster;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __PendleProxyBaseUpg_init() internal onlyInitializing {
        __PendleProxyBaseUpg_init_unchained();
    }

    function __PendleProxyBaseUpg_init_unchained() internal onlyInitializing {
        __AccessControl_init_unchained();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyBooster() {
        require(msg.sender == booster, "!auth");
        _;
    }

    function _setParams(
        address _pendleMarketFactory,
        address _booster
    ) internal {
        require(booster == address(0), "!init");

        require(
            _pendleMarketFactory != address(0),
            "invalid _pendleMarketFactory!"
        );
        require(_booster != address(0), "invalid _booster!");

        pendleMarketFactory = IPMarketFactory(_pendleMarketFactory);
        vePendle = IPMarketFactory(_pendleMarketFactory).vePendle();

        booster = _booster;

        emit BoosterUpdated(_booster);
    }

    function isValidMarket(
        address _market
    ) external view override returns (bool) {
        return pendleMarketFactory.isValidMarket(_market);
    }

    function withdraw(
        address _market,
        address _to,
        uint256 _amount
    ) external override onlyBooster {
        IERC20(_market).safeTransfer(_to, _amount);

        emit Withdrawn(_market, _to, _amount);
    }

    function claimRewards(
        address _market
    )
        external
        override
        onlyBooster
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        rewardTokens = _getRewardTokens(_market);
        uint256[] memory rewardTokensBalBefore = new uint256[](
            rewardTokens.length
        );
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardTokensBalBefore[i] = TransferHelper.balanceOf(
                rewardTokens[i],
                address(this)
            );
        }

        IPMarket(_market).redeemRewards(address(this));

        rewardAmounts = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 rewardTokenAmount = TransferHelper.balanceOf(
                rewardToken,
                address(this)
            ) - rewardTokensBalBefore[i];
            rewardAmounts[i] = rewardTokenAmount;
            if (rewardTokenAmount == 0) {
                continue;
            }
            rewardToken.safeTransferToken(booster, rewardTokenAmount);
        }

        emit RewardsClaimed(_market, rewardTokens, rewardAmounts);
    }

    function claimRewardsManually(
        address _market,
        uint256[] memory _amounts
    ) external override onlyBooster returns (address[] memory rewardTokens) {
        rewardTokens = _getRewardTokens(_market);
        require(rewardTokens.length == _amounts.length, "invalid _amounts!");
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardTokens[i].safeTransferToken(booster, _amounts[i]);
        }
        emit RewardsClaimed(_market, rewardTokens, _amounts);
    }

    function _getRewardTokens(
        address _market
    ) public view returns (address[] memory) {
        address[] memory rewardTokens = IPMarket(_market).getRewardTokens();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == address(0)) {
                // native
                rewardTokens[i] = AddressLib.PLATFORM_TOKEN_ADDRESS;
            }
        }
        return rewardTokens;
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }

    receive() external payable {}

    uint256[100] private __gap;
}