// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @custom:security-contact [email protected]
contract FurfiPresale is BaseContract
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
    IUniswapV2Router02 private _router;

    /**
     * Properties.
     */
    uint256 public startTime;
    uint256 public endTime;

    /**
     * Mappings.
     */
    mapping(address => uint256) public balance;

    /**
     * Setup.
     */
    function setup() external
    {
        _usdc = IERC20(addressBook.get("payment"));
        _router = IUniswapV2Router02(addressBook.get("router"));
        startTime = 1670860800;
        endTime = 1671033600;
    }

    /**
     * Receive.
     */
    receive() external payable {}

    /**
     * Buy.
     */
    function buy() external payable whenNotPaused
    {
        require(block.timestamp >= startTime, "Presale not started");
        require(block.timestamp <= endTime, "Presale ended");
        balance[msg.sender] += msg.value;
    }

    /**
     * Buy with USDC.
     * @param amount_ Amount of USDC.
     */
    function buyWithUsdc(uint256 amount_) external whenNotPaused
    {
        _buyWithUsdc(msg.sender, amount_);
    }

    /**
     * Buy with USDC for.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC.
     */
    function buyWithUsdcFor(address participant_, uint256 amount_) external whenNotPaused
    {
        _buyWithUsdc(participant_, amount_);
    }

    /**
     * Internal buy with USDC.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC.
     */
    function _buyWithUsdc(address participant_, uint256 amount_) internal
    {
        require(block.timestamp >= startTime, "Presale not started");
        require(block.timestamp <= endTime, "Presale ended");
        require(_usdc.transferFrom(participant_, address(this), amount_), "USDC transfer failed");
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_usdc);
        _path_[1] = _router.WETH();
        _usdc.approve(address(_router), amount_);
        uint256 _startingBnbBalance_ = address(this).balance;
        _router.swapExactTokensForETH(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
        uint256 _bnbReceived_ = address(this).balance - _startingBnbBalance_;
        balance[participant_] += _bnbReceived_;
    }
}