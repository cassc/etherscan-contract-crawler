// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

import "../interfaces/ICLRDeployer.sol";

contract StakedCLRTokenProxy is TransparentUpgradeableProxy {
    /**
     * @dev Storage slot with the clrDeployer contract address.
     * This is the keccak-256 hash of "eip1967.proxy.clrDeployer" subtracted by 1,
     * and is validated in the constructor.
     */
    bytes32 private constant _DEPLOYER_SLOT =
        0x3d08d612cd86aed0e9677508733085e4cbe15d53bdc770ec5b581bb4e0a721ca;

    constructor(
        address _logic,
        address _proxyAdmin,
        address __clrDeployer
    ) TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {
        assert(
            _DEPLOYER_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.clrDeployer")) - 1)
        );
        _setCLRDeployer(__clrDeployer);
    }

    /**
     * @dev Returns the address of the clr deployer.
     */
    function _clrDeployer()
        internal
        view
        virtual
        returns (address clrDeployer)
    {
        bytes32 slot = _DEPLOYER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            clrDeployer := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the clr deployer slot.
     */
    function _setCLRDeployer(address clrDeployer) private {
        bytes32 slot = _DEPLOYER_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, clrDeployer)
        }
    }

    function upgradeTo(address _implementation) external override ifAdmin {
        require(
            ICLRDeployer(_clrDeployer()).sCLRTokenImplementation() ==
                _implementation,
            "Can only upgrade to latest Staked CLR token implementation"
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
            ICLRDeployer(_clrDeployer()).sCLRTokenImplementation() ==
                _implementation,
            "Can only upgrade to latest Staked CLR token implementation"
        );
        _upgradeTo(_implementation);
        Address.functionDelegateCall(_implementation, data);
    }
}