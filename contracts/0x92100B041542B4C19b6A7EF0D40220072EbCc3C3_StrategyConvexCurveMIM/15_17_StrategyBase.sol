// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IUniswapRouterV2 } from "../interfaces/IUniswapRouterV2.sol";
import { INeuronPoolsController } from "../interfaces/INeuronPoolsController.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";

// Strategy Contract Basics

abstract contract StrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable want;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // User accounts
    address public governance;
    address public controller;

    // Dex
    address public constant univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    constructor(
        // Input token accepted by the contract
        address _want,
        address _governance,
        address _controller
    ) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_controller != address(0));

        want = _want;
        governance = _governance;
        controller = _controller;
    }

    receive() external payable {}

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure virtual returns (string memory);

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // NeuronPoolsController only function for creating additional rewards from dust
    function withdraw(address _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != _asset, "want");
        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a pool withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_nPool, _amount);

        emit Withdraw(_amount, _amount);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool");
        IERC20(want).safeTransfer(_nPool, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = INeuronPoolsController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_nPool, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapUniswapExactETHForTokens(address _to, uint256 _amount) internal {
        require(_to != address(0));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = _to;

        IUniswapRouterV2(univ2Router2).swapExactETHForTokens{ value: _amount }(
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapUniswapExactTokensForETH(address _from, uint256 _amount) internal {
        require(_from != address(0));

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = weth;

        IUniswapRouterV2(univ2Router2).swapExactTokensForETH(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }
}