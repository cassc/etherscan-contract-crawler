// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

//solhint-disable
interface ICurveBPAMO {
    function keeperInfo()
        external
        view
        returns (
            address,
            address,
            uint256
        );
}