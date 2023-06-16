//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ICLRDeployer {
    function clrImplementation() external view returns (address);

    function deployCLRPool(address _proxyAdmin) external returns (address pool);

    function deploySCLRToken(address _proxyAdmin)
        external
        returns (address token);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function sCLRTokenImplementation() external view returns (address);

    function setCLRImplementation(address _clrImplementation) external;

    function setsCLRTokenImplementation(address _sCLRTokenImplementation)
        external;

    function transferOwnership(address newOwner) external;
}