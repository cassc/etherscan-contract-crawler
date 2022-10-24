// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

import "../interfaces/INonRewardPoolDeployer.sol";

contract NonRewardPoolProxy is TransparentUpgradeableProxy {
    /**
     * @dev Storage slot with the nonRewardPoolDeployer contract address.
     * This is the keccak-256 hash of "eip1967.proxy.nonRewardPoolDeployer" subtracted by 1,
     * and is validated in the constructor.
     */
    bytes32 private constant _DEPLOYER_SLOT =
        0xa31c8a9c15ab83630b8333276b3d2f13132daf1ee481355dbdc6ab0253791319;

    constructor(
        address _logic,
        address _proxyAdmin,
        address __poolDeployer
    ) TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {
        assert(
            _DEPLOYER_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.proxy.nonRewardPoolDeployer")) -
                        1
                )
        );
        _setNonRewardPoolDeployer(__poolDeployer);
    }

    /**
     * @dev Returns the address of the non reward pool deployer.
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
    function _setNonRewardPoolDeployer(address poolDeployer) private {
        bytes32 slot = _DEPLOYER_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, poolDeployer)
        }
    }

    function upgradeTo(address _implementation) external override ifAdmin {
        require(
            INonRewardPoolDeployer(_poolDeployer())
                .nonRewardPoolImplementation() == _implementation,
            "Can only upgrade to latest NonRewardPool implementation"
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
            INonRewardPoolDeployer(_poolDeployer())
                .nonRewardPoolImplementation() == _implementation,
            "Can only upgrade to latest NonRewardPool implementation"
        );
        _upgradeTo(_implementation);
        Address.functionDelegateCall(_implementation, data);
    }
}