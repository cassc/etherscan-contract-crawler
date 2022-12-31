// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;
pragma solidity >=0.4.22 <0.9.0;

interface IReferralStorage {
    function setTraderReferralCode(address _account, bytes32 _code) external;

    function getTraderReferralInfo(address _account)
        external
        view
        returns (bytes32, address);
}