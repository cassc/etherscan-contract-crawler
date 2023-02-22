/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "../RcaShieldNormalized.sol";
import { IMasterChef } from "../../external/Sushiswap.sol";

contract RcaShieldOnsen is RcaShieldNormalized {
    using SafeERC20 for IERC20Metadata;

    IMasterChef public immutable masterChef;

    // Check our masterchef against this to call the correct functions.
    address private constant MCV1 = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    uint256 public immutable pid;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governance,
        address _controller,
        IMasterChef _masterChef,
        uint256 _pid
    ) RcaShieldNormalized(_name, _symbol, _uToken, _uTokenDecimals, _governance, _controller) {
        masterChef = _masterChef;
        pid = _pid;
        uToken.safeApprove(address(masterChef), type(uint256).max);
    }

    function getReward() external {
        if (address(masterChef) == MCV1) {
            masterChef.deposit(pid, 0);
        } else {
            masterChef.harvest(pid, address(this));
        }
    }

    function purchase(
        address _token,
        uint256 _amount, // token amount to buy
        uint256 _tokenPrice,
        bytes32[] calldata _tokenPriceProof,
        uint256 _underlyingPrice,
        bytes32[] calldata _underlyinPriceProof
    ) external {
        require(_token != address(uToken), "cannot buy underlying token");
        controller.verifyPrice(_token, _tokenPrice, _tokenPriceProof);
        controller.verifyPrice(address(uToken), _underlyingPrice, _underlyinPriceProof);
        uint256 underlyingAmount = (_amount * _tokenPrice) / _underlyingPrice;
        if (discount > 0) {
            underlyingAmount -= (underlyingAmount * discount) / DENOMINATOR;
        }

        IERC20Metadata token = IERC20Metadata(_token);
        // normalize token amount to transfer to the user so that it can handle different decimals
        _amount = (_amount * 10**token.decimals()) / BUFFER;

        token.safeTransfer(msg.sender, _amount);
        uToken.safeTransferFrom(msg.sender, address(this), _normalizedUAmount(underlyingAmount));

        if (address(masterChef) == MCV1) masterChef.deposit(pid, underlyingAmount);
        else masterChef.deposit(pid, underlyingAmount, address(this));
    }

    function _uBalance() internal view override returns (uint256) {
        return
            ((uToken.balanceOf(address(this)) + masterChef.userInfo(pid, address(this)).amount) * BUFFER) /
            BUFFER_UTOKEN;
    }

    function _afterMint(uint256 _uAmount) internal override {
        if (address(masterChef) == MCV1) masterChef.deposit(pid, _uAmount);
        else masterChef.deposit(pid, _uAmount, address(this));
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        if (address(masterChef) == MCV1) masterChef.withdraw(pid, _uAmount);
        else masterChef.withdraw(pid, _uAmount, address(this));
    }
}