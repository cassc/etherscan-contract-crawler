// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Closable} from "./Closable.sol";
import {Recoverable} from "./Recoverable.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {NFTReceiver} from "./NFTReceiver.sol";
import {LooksRareRewardsCollector} from "./LooksRareRewardsCollector.sol";
import {MarketRegistry} from "./MarketRegistry.sol";
import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {Sweep} from "./Structs.sol";

contract SingularSweep is
    Closable,
    Recoverable,
    ReentrancyGuard,
    NFTReceiver,
    LooksRareRewardsCollector,
    MarketRegistry
{
    using SafeTransferLib for IERC20;

    error MarketNotActive();
    error GetBalanceFailed();

    constructor(
        address owner,
        address guardian,
        address rewardDistributor,
        Market[] memory markets
    )
        Closable(guardian)
        LooksRareRewardsCollector(rewardDistributor)
        MarketRegistry(markets)
    {
        _transferOwnership(owner);
    }

    /**
     * Owner functions
     */

    function setOneTimeApproval(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    /**
     * Public buy functions
     */

    function batchBuyWithETH(Sweep.TradeDetails[] calldata tradeDetails)
        external
        payable
        isOpenForTrades
        nonReentrant
    {
        _trade(tradeDetails);

        _returnETHDust();
    }

    function batchBuyWithERC20s(
        Sweep.ERC20Detail[] calldata erc20Details,
        Sweep.TradeDetails[] calldata tradeDetails
    ) external payable isOpenForTrades nonReentrant {
        _getERC20s(erc20Details);

        _trade(tradeDetails);

        _returnETHDust();

        address[] memory tokens = new address[](erc20Details.length);
        for (uint256 i; i < erc20Details.length; i++) {
            tokens[i] = erc20Details[i].tokenAddr;
        }
        _returnERC20Dust(tokens);
    }

    function batchBuyWithSwappedERC20s(
        Sweep.ERC20Detail[] calldata erc20Details,
        Sweep.TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable isOpenForTrades nonReentrant {
        _getERC20s(erc20Details);

        _trade(tradeDetails);

        _returnETHDust();

        uint256 len = erc20Details.length + dustTokens.length;
        address[] memory tokens = new address[](len);
        for (uint256 i; i < erc20Details.length; i++) {
            tokens[i] = erc20Details[i].tokenAddr;
        }
        for (uint256 i; i < dustTokens.length; i++) {
            tokens[erc20Details.length + i] = dustTokens[i];
        }
        _returnERC20Dust(tokens);
    }

    receive() external payable {}

    /**
     * Private functions
     */

    /// @dev Transfers ERC20 tokens from the sender to this contract
    /// @dev Reverts on error
    function _getERC20s(Sweep.ERC20Detail[] calldata erc20Details) private {
        for (uint256 i; i < erc20Details.length; i++) {
            IERC20(erc20Details[i].tokenAddr).safeTransferFrom(
                _msgSender(),
                address(this),
                erc20Details[i].amount
            );
        }
    }

    /// @dev Call proxies
    /// @dev Reverts on error
    function _trade(Sweep.TradeDetails[] memory _tradeDetails) private {
        for (uint256 i; i < _tradeDetails.length; i++) {
            Market memory m = markets[_tradeDetails[i].marketId];
            if (!m.isActive) revert MarketNotActive();

            (bool success, ) = m.isLib
                ? m.proxy.delegatecall(_tradeDetails[i].tradeData)
                : m.proxy.call{value: _tradeDetails[i].value}(
                    _tradeDetails[i].tradeData
                );

            _checkCallResult(success);
        }
    }

    /// @dev If false, reverts with revert reason from call
    function _checkCallResult(bool _success) private pure {
        if (!_success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /// @dev Sends all ETH to msg.sender
    /// @dev Doesn't revert on error
    function _returnETHDust() private {
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    /// @dev Sends all balance of ERC20 to msg.sender
    /// @dev Doesn't revert on error
    function _returnERC20Dust(address[] memory _tokens) private {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 balance = _erc20Balance(_tokens[i]);
            if (balance > 0) {
                _tokens[i].call(
                    abi.encodeCall(
                        IERC20.transfer, // 0xa9059cbb transfer(address,uint256)
                        (_msgSender(), balance)
                    )
                );
            }
        }
    }

    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// @dev https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol
    /// @dev https://github.com/Uniswap/v3-core/commit/7689aa8e2adecbcf94198f79cb4f230d0419d009
    function _erc20Balance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeCall(IERC20.balanceOf, address(this))
        );
        if (!success || data.length < 32) revert GetBalanceFailed();
        return abi.decode(data, (uint256));
    }
}