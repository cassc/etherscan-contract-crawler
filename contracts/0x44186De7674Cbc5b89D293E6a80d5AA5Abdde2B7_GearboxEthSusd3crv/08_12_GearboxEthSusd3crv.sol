// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

struct MultiCall {
    address target;
    bytes callData;
}

struct Balance {
    address token;
    uint256 balance;
}

interface ICreditFacade {
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    function multicall(MultiCall[] calldata calls) external;

    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external;

    function revertIfReceivedLessThan(Balance[] memory expected) external;
}

interface ICreditManager {
    function creditAccounts(address borrower) external view returns (address);
}

interface ICurveAdapter {
    function add_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external;

    function calc_add_one_coin(
        uint256 amount,
        int128 i
    ) external view returns (uint256);

    function calc_token_amount(
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[4] memory min_amounts
    ) external;

    function exchange_all(int128 i, int128 j, uint256 rateMinRAY) external;
}

interface IConvexBoosterAdapter {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

interface IBaseRewardPoolAdapter {
    function getReward() external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;
}

contract GearboxEthSusd3crv is DefiiWithCustomEnter, DefiiWithCustomExit {
    using SafeERC20 for IERC20;

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant STKCVX = IERC20(0x7e1992A7F28dAA5f6a2d34e2cd40f962f37B172C);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 constant CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    ICreditFacade constant creditFacade =
        ICreditFacade(0x61fbb350e39cc7bF22C01A469cf03085774184aa);
    ICreditManager constant creditManager =
        ICreditManager(0x95357303f995e184A7998dA6C6eA35cC728A1900);
    ICurveAdapter constant curveAdapter =
        ICurveAdapter(0x2bBDcc2425fa4df06676c4fb69Bd211b63314feA);
    IConvexBoosterAdapter constant convexBoosterAdapter =
        IConvexBoosterAdapter(0xB548DaCb7e5d61BF47A026903904680564855B4E);
    IBaseRewardPoolAdapter constant baseRewardPoolAdapter =
        IBaseRewardPoolAdapter(0xbEf6108D1F6B85c4c9AA3975e15904Bb3DFcA980);

    function getCreditAccount() public view returns (address) {
        return creditManager.creditAccounts(address(this));
    }

    function enterParams(
        uint16 leverage,
        uint256 slippage
    ) external view returns (bytes memory) {
        require(leverage >= 20, "Leverage must be >=20, (>=2.0x)");
        require(leverage <= 100, "Leverage must be <=100, (<=10.0x)");
        require(slippage > 800, "Slippage must be >800, (>80%)");
        require(slippage < 1200, "Slippage must be <1200, (<120%)");

        uint256 lpPerToken = curveAdapter.calc_add_one_coin(1e6, 1);

        return
            abi.encode(
                leverage * 10 - 100,
                (lpPerToken * leverage * slippage) / 10000
            );
    }

    function exitParams(uint256 slippage) public view returns (bytes memory) {
        require(slippage > 800, "Slippage must be >800, (>80%)");
        require(slippage < 1200, "Slippage must be <1200, (<120%)");

        uint256 lpPerToken = curveAdapter.calc_token_amount(
            [uint256(0), uint256(1), uint256(0), uint256(0)],
            false
        );

        return abi.encode((1e15 * slippage) / lpPerToken);
    }

    function hasAllocation() public view override returns (bool) {
        return STKCVX.balanceOf(getCreditAccount()) > 0;
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint16 leverageFactor, uint256 lpPerToken) = abi.decode(
            params,
            (uint16, uint256)
        );

        uint256 usdcAmount = USDC.balanceOf(address(this));

        USDC.approve(address(creditManager), usdcAmount);
        creditFacade.openCreditAccount(
            usdcAmount,
            address(this),
            leverageFactor,
            0
        );

        MultiCall[] memory deposit_calls = new MultiCall[](3);
        Balance[] memory balances = new Balance[](1);
        // Set slippage for multicalls result.
        // lpPerToken already include leverage.
        balances[0] = Balance(address(STKCVX), (usdcAmount * lpPerToken) / 1e6);
        deposit_calls[0] = MultiCall(
            address(creditFacade),
            abi.encodeWithSelector(
                ICreditFacade.revertIfReceivedLessThan.selector,
                balances
            )
        );
        deposit_calls[1] = MultiCall(
            address(curveAdapter),
            abi.encodeWithSelector(
                ICurveAdapter.add_liquidity_one_coin.selector,
                (usdcAmount * (leverageFactor + 100)) / 100,
                1,
                0
            )
        );
        deposit_calls[2] = MultiCall(
            address(convexBoosterAdapter),
            abi.encodeWithSelector(
                IConvexBoosterAdapter.depositAll.selector,
                4,
                true
            )
        );
        creditFacade.multicall(deposit_calls);
    }

    function _exit() internal override(Defii, DefiiWithCustomExit) {
        _exitWithParams(exitParams(995));
    }

    function _exitWithParams(bytes memory params) internal override {
        uint256 tokenPerLp = abi.decode(params, (uint256));

        _harvest();

        address account = getCreditAccount();
        uint256 lpAmount = STKCVX.balanceOf(account);
        uint256 usdcAmount = USDC.balanceOf(account);

        MultiCall[] memory withdraw_calls = new MultiCall[](6);
        Balance[] memory balances = new Balance[](1);
        // Set slippage for multicalls result.
        balances[0] = Balance(
            address(USDC),
            ((lpAmount * tokenPerLp) / 1e18) - usdcAmount
        );
        withdraw_calls[0] = MultiCall(
            address(creditFacade),
            abi.encodeWithSelector(
                ICreditFacade.revertIfReceivedLessThan.selector,
                balances
            )
        );
        withdraw_calls[1] = MultiCall(
            address(baseRewardPoolAdapter),
            abi.encodeWithSelector(
                IBaseRewardPoolAdapter.withdrawAllAndUnwrap.selector,
                false
            )
        );
        withdraw_calls[2] = MultiCall(
            address(curveAdapter),
            abi.encodeWithSelector(
                ICurveAdapter.remove_liquidity.selector,
                lpAmount,
                [uint256(0), uint256(0), uint256(0), uint256(0)]
            )
        );
        withdraw_calls[3] = MultiCall(
            address(curveAdapter),
            abi.encodeWithSelector(ICurveAdapter.exchange_all.selector, 0, 1, 0)
        );
        withdraw_calls[4] = MultiCall(
            address(curveAdapter),
            abi.encodeWithSelector(ICurveAdapter.exchange_all.selector, 2, 1, 0)
        );
        withdraw_calls[5] = MultiCall(
            address(curveAdapter),
            abi.encodeWithSelector(ICurveAdapter.exchange_all.selector, 3, 1, 0)
        );

        creditFacade.closeCreditAccount(
            address(this),
            0,
            false,
            withdraw_calls
        );

        _claimIncentive(CRV);
        _claimIncentive(CVX);
    }

    function _harvest() internal override {
        baseRewardPoolAdapter.getReward();
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }
}