// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ICollectableDust {
    event DustSent(address _to, address token, uint256 amount);

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external;
}