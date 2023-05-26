// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IInsuranceFund {
    function claimDDXFromInsuranceMining(address _claimant) external;
}