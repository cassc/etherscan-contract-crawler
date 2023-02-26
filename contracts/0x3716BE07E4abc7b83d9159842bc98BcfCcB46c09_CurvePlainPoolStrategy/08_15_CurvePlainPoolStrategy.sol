// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity >=0.8.0 <0.9.0;

import {StrategyCurveBase} from "./StrategyCurveBase.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ICurveFi} from "../../interfaces/curve-finance/ICurveFi.sol";

contract CurvePlainPoolStrategy is StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public poolSize;

    constructor(
        address _vault,
        uint256[3] memory _params,
        address _curvePool,
        address _yvToken,
        address _uniswapRouter,
        string memory strategyName,
        uint256 _poolSize,
        address _curveToken
    ) StrategyCurveBase(_vault, _params, _curveToken, _curvePool, _yvToken, _uniswapRouter, strategyName) {
        _initializeStrat(_poolSize);
    }

    function initialize(
        address _vault,
        address _strategist,
        uint256[3] memory _params,
        address _curvePool,
        address _yvToken,
        address _uniswapRouter,
        string memory strategyName,
        uint256 _poolSize,
        address _curveToken
    ) external {
        super.initializeBase(
            _vault,
            _strategist,
            _params,
            _curveToken,
            _curvePool,
            _yvToken,
            _uniswapRouter,
            strategyName
        );
        _initializeStrat(_poolSize);
    }

    function _initializeStrat(uint256 _poolSize) internal {
        require(_poolSize > 1 && _poolSize < 5, "incorrect pool size");
        if (_isWantWETH()) {
            require(
                curvePool.coins(0) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                "Wrong curve pool for WETH"
            );
            curveId = 0;
        } else {
            curveId = -1;
            // Unknown pool
            for (uint128 index; index < _poolSize; index++) {
                if (curvePool.coins(index) == address(want)) {
                    curveId = int128(index);
                    break;
                }
            }
            require(curveId != -1, "incorrect want for curve pool");
        }

        poolSize = _poolSize;
        _setupStatics();
    }

    function _setupStatics() internal {
        if (!_isWantWETH()) {
            want.safeApprove(address(curvePool), type(uint256).max);
        }
    }

    function cloneSingleSidedCurve(
        address _vault,
        address _strategist,
        uint256[3] memory _params,
        address _curvePool,
        address _yvToken,
        address _uniswapRouter,
        string memory _strategyName,
        uint256 _poolSize,
        address _curveToken
    ) external returns (address payable newStrategy) {
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        CurvePlainPoolStrategy(newStrategy).initialize(
            _vault,
            _strategist,
            _params,
            _curvePool,
            _yvToken,
            _uniswapRouter,
            _strategyName,
            _poolSize,
            _curveToken
        );

        emit Cloned(newStrategy);
    }

    /**
     * @notice
     *  Deposit want tokens into a Curve liquidity pool
     * @dev
     *  Unfortunately, we need to use an if/else structure here because the curve contract cannot handle dynamic arrays
     *  The following shorthand method is not possible: `uint256[] memory amounts = new uint256[](poolSize);`
     * @param investAmount the amount of want tokens to invest
     * @param maxSlippage the pre-calculated maximum allowed slippage when adding liquidity
     */
    function _addLiquidity(uint256 investAmount, uint256 maxSlippage) internal override {
        if (_isWantWETH()) {
            WETH.withdraw(investAmount);
            uint256[2] memory amounts;
            amounts[0] = investAmount;
            curvePool.add_liquidity{value: investAmount}(amounts, maxSlippage);
        } else if (poolSize == 2) {
            uint256[2] memory amounts;
            amounts[uint256(uint128(curveId))] = investAmount;
            curvePool.add_liquidity(amounts, maxSlippage);
        } else if (poolSize == 3) {
            uint256[3] memory amounts;
            amounts[uint256(uint128(curveId))] = investAmount;
            curvePool.add_liquidity(amounts, maxSlippage);
        } else {
            uint256[4] memory amounts;
            amounts[uint256(uint128(curveId))] = investAmount;
            curvePool.add_liquidity(amounts, maxSlippage);
        }
    }

    function _withdrawLiquidity(uint256 withdrawAmount, uint256 maxSlippage) internal override {
        curvePool.remove_liquidity_one_coin(withdrawAmount, curveId, maxSlippage);
        if (_isWantWETH()) {
            WETH.deposit{value: address(this).balance}();
        }
    }

    function _prepareMigration(address _newStrategy) internal override {
        super._prepareMigration(_newStrategy);
        if (_isWantWETH()) {
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                WETH.deposit{value: ethBalance}();
            }
        }
    }

    function _isWantWETH() internal view returns (bool) {
        return address(want) == address(WETH);
    }
}