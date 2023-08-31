// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IBridge {
    function addNativeLiquidity(uint256 _amount)
        external payable;

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}