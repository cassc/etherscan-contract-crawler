// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./TransparentUpgradeableProxy.sol";
import "../interface/IPoolDeployer.sol";

contract FungibleOriginationPoolProxy is TransparentUpgradeableProxy {
    /**
     * @dev Storage slot with the poolDeployer contract address.
     * This is the keccak-256 hash of "eip1967.proxy.poolDeployer" subtracted by 1,
     * and is validated in the constructor.
     */
    bytes32 private constant _DEPLOYER_SLOT =
        0x203baa5a38edd7f7142bfc980e12e771638f6aa6d00b04b357e7d7e6be18ebfb;

    constructor(
        address _logic,
        address _proxyAdmin,
        address __poolDeployer
    ) TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {
        assert(
            _DEPLOYER_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.poolDeployer")) - 1)
        );
        _setPoolDeployer(__poolDeployer);
    }

    /**
     * @dev Returns the address of the pool deployer.
     */
    function _poolDeployer()
        internal
        view
        virtual
        returns (address poolDeployer)
    {
        bytes32 slot = _DEPLOYER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            poolDeployer := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the pool deployer slot.
     */
    function _setPoolDeployer(address poolDeployer) private {
        bytes32 slot = _DEPLOYER_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, poolDeployer)
        }
    }

    function upgradeTo(address _implementation) external override ifAdmin {
        require(
            IPoolDeployer(_poolDeployer())
                .fungibleOriginationPoolImplementation() == _implementation,
            "Can only upgrade to latest fungibleOriginationPool implementation"
        );
        _upgradeTo(_implementation);
    }

    function upgradeToAndCall(address _implementation, bytes calldata data)
        external
        payable
        override
        ifAdmin
    {
        require(
            IPoolDeployer(_poolDeployer())
                .fungibleOriginationPoolImplementation() == _implementation,
            "Can only upgrade to latest fungibleOriginationPool implementation"
        );
        _upgradeToAndCall(_implementation, data, true);
    }
}