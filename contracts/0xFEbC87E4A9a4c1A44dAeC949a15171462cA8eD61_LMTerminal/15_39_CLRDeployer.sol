// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./proxies/CLRProxy.sol";
import "./proxies/StakedCLRTokenProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Manages deployment of CLR and StakedCLRToken Proxies
 * Deploys CLR proxies pointing to CLR implementation
 * Deploys StakedCLRToken proxies pointing to StakedCLRToken implementation
 */
contract CLRDeployer is Ownable {
    address public clrImplementation;
    address public sCLRTokenImplementation;

    constructor(address _clrImplementation, address _sclrTokenImplementation) {
        clrImplementation = _clrImplementation;
        sCLRTokenImplementation = _sclrTokenImplementation;
        emit CLRImplementationSet(_clrImplementation);
        emit CLRTokenImplementationSet(_sclrTokenImplementation);
    }

    function deployCLRPool(address _proxyAdmin)
        external
        returns (address pool)
    {
        CLRProxy clrInstance = new CLRProxy(
            clrImplementation,
            _proxyAdmin,
            address(this)
        );
        return address(clrInstance);
    }

    function deploySCLRToken(address _proxyAdmin)
        external
        returns (address token)
    {
        StakedCLRTokenProxy clrTokenInstance = new StakedCLRTokenProxy(
            sCLRTokenImplementation,
            _proxyAdmin,
            address(this)
        );
        return address(clrTokenInstance);
    }

    function setCLRImplementation(address _clrImplementation)
        external
        onlyOwner
    {
        clrImplementation = _clrImplementation;
        emit CLRImplementationSet(_clrImplementation);
    }

    function setsCLRTokenImplementation(address _sCLRTokenImplementation)
        external
        onlyOwner
    {
        sCLRTokenImplementation = _sCLRTokenImplementation;
        emit CLRTokenImplementationSet(_sCLRTokenImplementation);
    }

    // Events

    event CLRImplementationSet(address indexed clrImplementation);

    event CLRTokenImplementationSet(address indexed sCLRTokenImplementation);
}