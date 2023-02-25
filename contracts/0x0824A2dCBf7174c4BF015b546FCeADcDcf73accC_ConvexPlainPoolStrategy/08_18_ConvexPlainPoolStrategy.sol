// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConvexDeposit} from "../../interfaces/convex/IConvexDeposit.sol";
import {IConvexRewards} from "../../interfaces/convex/IConvexRewards.sol";
import {ICurveFi} from "../../interfaces/curve-finance/ICurveFi.sol";
import {IWETH} from "../../interfaces/IERC20/IWETH.sol";
import {IUniV3} from "../../interfaces/uniswap/IUniV3.sol";
import {StrategyConvexBase} from "./StrategyConvexBase.sol";

contract ConvexPlainPoolStrategy is StrategyConvexBase {
    using SafeERC20 for IERC20;

    int128 public curveId;
    uint256 public poolSize;
    uint24 public uniStableFee;
    IERC20 public curveDepositToken; // Used to deposit into curve LP when compounding rewards

    address internal constant _UNISWAP_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    bool internal _isOriginal = true;

    event Cloned(address indexed clone);

    constructor(
        address _vault,
        uint256 _pid,
        address _curvePool,
        string memory _name,
        address _curveDepositToken,
        uint256 _poolSize
    ) StrategyConvexBase(_vault, _pid, _curvePool, _name) {
        _initializeStrat(_curveDepositToken, _poolSize);
    }

    function cloneConvex3CrvRewards(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name,
        address _curveDepositToken,
        uint256 _poolSize
    ) external returns (address payable newStrategy) {
        require(_isOriginal);
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        ConvexPlainPoolStrategy(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _pid,
            _curvePool,
            _name,
            _curveDepositToken,
            _poolSize
        );

        emit Cloned(newStrategy);
    }

    // this will only be called by the clone function above
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name,
        address _curveDepositToken,
        uint256 _poolSize
    ) public {
        super._initializeBase(_vault, _strategist, _rewards, _keeper, _pid, _curvePool, _name);
        _initializeStrat(_curveDepositToken, _poolSize);
    }

    function _initializeStrat(address _curveDepositToken, uint256 _poolSize) internal {
        require(_poolSize > 1 && _poolSize < 5, "incorrect pool size");
        _WETH.approve(_UNISWAP_V3, type(uint256).max);
        curveDepositToken = IERC20(_curveDepositToken);
        uniStableFee = 500; // 0.5%
        poolSize = _poolSize;
        curveId = _findCurveId();
        if (!_isDepositTokenWETH()) {
            curveDepositToken.safeApprove(address(curve), type(uint256).max);
        }
    }

    function _findCurveId() internal view returns (int128) {
        if (_isDepositTokenWETH()) {
            require(
                curve.coins(0) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                "Wrong curve pool for WETH curve deposit token"
            );
            return 0;
        }
        for (uint128 index; index < poolSize; index++) {
            if (curve.coins(index) == address(curveDepositToken)) {
                return int128(index);
            }
        }
        revert("Wrong curve pool for curve deposit token");
    }

    function _isDepositTokenWETH() internal view returns (bool) {
        return address(curveDepositToken) == address(_WETH);
    }

    function _swapEthToTargetToken(uint256 _wethBalance) internal override {
        if (_isDepositTokenWETH()) {
            IWETH(address(_WETH)).withdraw(_wethBalance);
        } else {
            IUniV3(_UNISWAP_V3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(address(_WETH), uint24(uniStableFee), address(curveDepositToken)),
                    address(this),
                    block.timestamp,
                    _wethBalance,
                    uint256(1)
                )
            );
        }
    }

    /**
     * @notice
     *  Deposit want tokens into a Curve liquidity pool
     * @dev
     *  Unfortunately, we need to use an if/else structure here because the curve contract cannot handle dynamic arrays
     *  The following shorthand method is not possible: `uint256[] memory amounts = new uint256[](poolSize);`
     */
    function _addLiquidityToCurve() internal override {
        if (_isDepositTokenWETH()) {
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                uint256[2] memory amounts;
                amounts[0] = ethBalance;
                curve.add_liquidity{value: ethBalance}(amounts, 0);
            }
            return;
        }

        uint256 balance = curveDepositToken.balanceOf(address(this));
        if (balance > 0) {
            if (poolSize == 2) {
                uint256[2] memory amounts;
                amounts[uint256(uint128(curveId))] = balance;
                curve.add_liquidity(amounts, 0);
            } else if (poolSize == 3) {
                uint256[3] memory amounts;
                amounts[uint256(uint128(curveId))] = balance;
                curve.add_liquidity(amounts, 0);
            } else {
                uint256[4] memory amounts;
                amounts[uint256(uint128(curveId))] = balance;
                curve.add_liquidity(amounts, 0);
            }
        }
    }

    receive() external payable {}
}