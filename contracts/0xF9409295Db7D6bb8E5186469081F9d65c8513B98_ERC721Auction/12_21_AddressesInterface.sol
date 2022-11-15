// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface AddressesInterface {
    function existingContract(address contractAddr)
        external
        view
        returns (bool);

    function isVerified(address contractAddr) external view returns (bool);
}