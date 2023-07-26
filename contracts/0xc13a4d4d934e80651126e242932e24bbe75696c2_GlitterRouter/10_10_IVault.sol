// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRouter.sol";

interface IVault {
    event SetMinDeposit(uint256 minDeposit);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetRouter(address router);

    function CONTRACT_ID() external pure returns (bytes32);

    function FEE_DENOMINATOR() external pure returns (uint16);

    function collectFees() external payable;

    function deposit(address _from, uint256 _amount) external payable;

    function fees() external view returns (uint256);

    function maxDeposit() external view returns (uint256);

    function minDeposit() external view returns (uint256);

    function refund(address _to, uint256 _amount) external payable;

    function release(
        address _to,
        uint256 _amount,
        uint16 _feeRate
    ) external payable;

    function router() external view returns (IRouter);

    function setMaxDeposit(uint256 _maxDeposit) external;

    function setMinDeposit(uint256 _minDeposit) external;

    function setParams(uint256 _minDeposit, uint256 _maxDeposit) external;

    function setRouter(IRouter _router) external;

    function token() external view returns (IERC20);

    function decimals() external view returns (uint8);
}