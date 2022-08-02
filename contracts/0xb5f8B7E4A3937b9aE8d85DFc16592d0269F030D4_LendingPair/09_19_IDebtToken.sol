// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {IBSWrapperTokenBase} from "./IBSWrapperToken.sol";

interface IDebtToken is IBSWrapperTokenBase {
    event DelegateBorrow(address from, address to, uint256 amount, uint256 timestamp);

    function increaseTotalDebt(uint256 _amount) external;

    function principal(address _account) external view returns (uint256);

    function mint(
        address _to,
        address _owner,
        uint256 _amount
    ) external;
}