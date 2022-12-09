//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeKafra {
    function MAX_FEE() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function treasuryFeeWithdraw() external view returns (uint256);

    function kswFeeWithdraw() external view returns (uint256);

    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);

    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;
}