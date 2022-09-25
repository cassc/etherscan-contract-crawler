// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { INeuronPoolsController } from "../interfaces/INeuronPoolsController.sol";

abstract contract NeuronPoolCommon {
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;

    IERC20Metadata internal constant ETH = IERC20Metadata(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IERC20Metadata internal constant USDC = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20Metadata public token;
    uint256 public tokenDecimals;

    address public governance;
    address public controller;

    receive() external payable {}

    function getSupportedTokens() external view virtual returns (address[] memory);

    function totalSupply() public view virtual returns (uint256);

    function _mint(address account, uint256 amount) internal virtual;

    function _burn(address account, uint256 amount) internal virtual;

    function balanceOf(address account) public view virtual returns (uint256);

    function depositAll(address _enterToken) external payable returns (uint256) {
        return deposit(_enterToken, IERC20Metadata(_enterToken).balanceOf(msg.sender));
    }

    function deposit(address _enterToken, uint256 _amount) public payable virtual returns (uint256);

    function _mintShares(uint256 _amount, uint256 _balance) internal returns (uint256) {
        uint256 _totalSupply = totalSupply();

        uint256 shares = _totalSupply == 0
            ? (_amount * 10**decimals()) / 10**tokenDecimals
            : (_amount * _totalSupply) / _balance;

        _mint(msg.sender, shares);

        return shares;
    }

    function withdrawAll(address _withdrawableToken) external {
        withdraw(_withdrawableToken, balanceOf(msg.sender));
    }

    function _withdrawLpTokens(uint256 _shares) internal returns (uint256) {
        require(_shares > 0, "!shares");

        address self = address(this);
        IERC20Metadata _token = token;

        uint256 userLpTokensAmount = (balance() * _shares) / totalSupply();
        _burn(msg.sender, _shares);

        uint256 neuronPoolBalance = _token.balanceOf(self);
        // If pool balance's not enough, we're withdrawing the controller's tokens
        if (userLpTokensAmount > neuronPoolBalance) {
            uint256 _withdraw = userLpTokensAmount - neuronPoolBalance;
            INeuronPoolsController(controller).withdraw(address(_token), _withdraw);
            uint256 _after = _token.balanceOf(self);
            uint256 _diff = _after - neuronPoolBalance;
            if (_diff < _withdraw) {
                userLpTokensAmount = neuronPoolBalance + _diff;
            }
        }

        return userLpTokensAmount;
    }

    function withdraw(address _withdrawableToken, uint256 _shares) public virtual;

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // Balance = pool's balance + pool's token controller contract balance
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(INeuronPoolsController(controller).balanceOf(address(token)));
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        INeuronPoolsController(controller).earn(address(token), _bal);
    }

    function pricePerShare() public view returns (uint256) {
        uint256 total = totalSupply();
        return total == 0 ? 0 : (balance() * 1e18) / total;
    }
}