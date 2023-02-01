// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/ISwapV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Injection is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * External contracts.
     */
    IERC20 private _usdc;
    IERC20 private _fur;
    ISwapV2 private _swap;
    address private _vault;

    /**
     * Properties.
     */
    uint256 private _injectionPerWeek;
    uint256 private _minimumInjection;
    uint256 private _maximumInjection;
    mapping(uint256 => uint256) private _injections;

    /**
     * Setup.
     */
    function setup() external
    {
        _injectionPerWeek = 37500e18;
        _minimumInjection = 1e18;
        _maximumInjection = 10000e18;
        _usdc = IERC20(addressBook.get("payment"));
        _fur = IERC20(addressBook.get("token"));
        _swap = ISwapV2(addressBook.get("swap"));
        _vault = addressBook.get("vault");
    }

    /**
     * Get available injections.
     */
    function getAvailableInjection() public view returns (uint256)
    {
        uint256 _usdcBalance_ = _usdc.balanceOf(address(this));
        uint256 _injectionPerSecond_ = _injectionPerWeek / 7 days;
        uint256 _availableToInject_ = (_getElapsedTimeThisWeek() * _injectionPerSecond_) - _injections[_getWeek()];
        if(_availableToInject_ < _minimumInjection) _availableToInject_ = 0;
        if(_availableToInject_ > _maximumInjection) _availableToInject_ = _maximumInjection;
        if(_availableToInject_ > _usdcBalance_) _availableToInject_ = _usdcBalance_;
        return _availableToInject_;
    }

    /**
     * Inject.
     */
    function inject() external
    {
        uint256 _availableInjection_ = getAvailableInjection();
        require(_availableInjection_ > 0, "No injection available.");
        _injections[_getWeek()] += _availableInjection_;
        _swap.buy(address(_usdc), _availableInjection_);
        _fur.transfer(_vault, _fur.balanceOf(address(this)));
    }

    /**
     * Get week.
     */
    function _getWeek() internal view returns (uint256)
    {
        return block.timestamp / 7 days;
    }

    /**
     * Elapsed time this week.
     * @return uint256 Seconds elapsed in the week.
     */
    function _getElapsedTimeThisWeek() internal view returns (uint256)
    {
        return block.timestamp % 7 days;
    }
}