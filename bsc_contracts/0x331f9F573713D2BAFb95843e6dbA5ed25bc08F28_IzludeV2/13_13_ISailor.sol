//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISailor {
    function MAX_FEE() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function callFee() external view returns (uint256);

    function kswFee() external view returns (uint256);
}