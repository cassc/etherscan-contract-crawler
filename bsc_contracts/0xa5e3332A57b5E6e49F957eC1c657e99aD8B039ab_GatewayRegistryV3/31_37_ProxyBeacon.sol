// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract ProxyBeacon is Context, UpgradeableBeacon {
    event LogProxyDeployerUpdated(address indexed oldProxyDeployer, address indexed newProxyDeployer);

    // Only allow one address to call `deployProxy`.
    address private _proxyDeployer;

    modifier onlyProxyDeployer() {
        address proxyDeployer_ = getProxyDeployer();
        require(
            proxyDeployer_ != address(0x0) && _msgSender() == proxyDeployer_,
            "ProxyBeacon: caller is not the proxy deployer"
        );
        _;
    }

    constructor(address implementation_, address contractOwner) UpgradeableBeacon(implementation_) {
        transferOwnership(contractOwner);
    }

    // GETTERS /////////////////////////////////////////////////////////////////

    function getProxyDeployer() public view returns (address) {
        return _proxyDeployer;
    }

    // GOVERNANCE //////////////////////////////////////////////////////////////

    function updateProxyDeployer(address newProxyDeployer) public onlyOwner {
        require(newProxyDeployer != address(0x0), "ProxyBeacon: invalid proxy deployer");
        address oldProxyDeployer = _proxyDeployer;
        _proxyDeployer = newProxyDeployer;
        emit LogProxyDeployerUpdated(oldProxyDeployer, newProxyDeployer);
    }

    // RESTRICTED //////////////////////////////////////////////////////////////

    /// @notice Deploy a proxy that fetches its implementation from this
    /// ProxyBeacon.
    function deployProxy(bytes32 create2Salt, bytes calldata encodedParameters)
        external
        onlyProxyDeployer
        returns (address)
    {
        // Deploy without initialization code so that the create2 address isn't
        // based on the initialization parameters.
        address proxy = address(new BeaconProxy{salt: create2Salt}(address(this), ""));

        Address.functionCall(address(proxy), encodedParameters);

        return proxy;

    }
}

contract RenAssetProxyBeacon is ProxyBeacon {
    string public constant NAME = "RenAssetProxyBeacon";

    constructor(address implementation, address adminAddress) ProxyBeacon(implementation, adminAddress) {}
}

contract MintGatewayProxyBeacon is ProxyBeacon {
    string public constant NAME = "MintGatewayProxyBeacon";

    constructor(address implementation, address adminAddress) ProxyBeacon(implementation, adminAddress) {}
}

contract LockGatewayProxyBeacon is ProxyBeacon {
    string public constant NAME = "LockGatewayProxyBeacon";

    constructor(address implementation, address adminAddress) ProxyBeacon(implementation, adminAddress) {}
}