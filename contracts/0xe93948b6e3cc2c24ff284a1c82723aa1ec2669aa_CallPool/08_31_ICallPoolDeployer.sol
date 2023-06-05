// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallPoolDeployer {
    function parameters() external view returns (
        address factory,
        address erc721token,
        address ntoken,
        address calltoken,
        address oracle,
        address premium
    );
}