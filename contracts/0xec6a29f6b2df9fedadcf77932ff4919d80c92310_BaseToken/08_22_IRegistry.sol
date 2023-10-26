// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IRegistry {

    enum ProjectStatus { Locked, Whitelist, Active, WhitelistByToken}

    function getProjectMaxSupply(address project)
        external
        view
        returns(uint256);
    function getProjectStatus(address project)
        external
        view
        returns(ProjectStatus);
    function getProjectPrice(address project)
        external
        view
        returns(uint256);
    function getProjectMaxBlockPurchase(address project)
        external
        view
        returns(uint256);
    function getProjectMaxWalletPurchase(address project)
        external
        view
        returns(uint256);
    function getProjectFreeStatus(address project)
        external
        view
        returns(bool);
    function getProjectLicense(address project)
        external
        view
        returns(string memory);
}