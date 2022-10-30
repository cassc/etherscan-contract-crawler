// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILotteryBank {

    function OPERATOR_ROLE() external view returns(bytes32);

    function token() external view returns (IERC20);

    function balance() external view returns (uint256);

    function updateToken(IERC20 _token) external;

    function recoverTokens(uint256 _amount) external;

    function recoverTokensFor(uint256 _amount, address _to) external;

}