// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./interfaces/IMembershipsFactory.sol";
import "./interfaces/IMembershipsProxy.sol";

/// @title MembershipsProxy
/// @notice Proxy contract that will be deployed by MembershipsFactory
/// @author Coinvise
contract MembershipsProxy is ERC1967Proxy, IMembershipsProxy {
    /// @notice Emitted when being called by other than registered factory contract
    error Unauthorized();

    /// @notice Emitted when MembershipsFactory.memberships() is zero address
    error InvalidMemberships();

    /// @dev Storage slot with the factory of the contract.
    ///      This is the keccak-256 hash of "co.coinvise.memberships.factory" subtracted by 1,
    ///      and is validated in the constructor
    bytes32 private constant _FACTORY_SLOT = 0x1ad0e7da7a8ae5b58d3a6900c5b9701c3c2713e4e7cef4d5a30267fc422c6301;

    /// @dev Only factory can call
    modifier onlyFactory() {
        if (msg.sender != _factory()) revert Unauthorized();
        _;
    }

    /// @notice Deploys and initializes ERC1967 proxy contract
    /// @dev Reverts if memberships implementation address not set in MembershipsFactory.
    ///      Sets caller as factory
    /// @param _membershipsVersion version of Memberships implementation
    /// @param _memberships address of Memberships implementation contract
    /// @param _data encoded data to be used to initialize proxy
    constructor(
        uint16 _membershipsVersion,
        address _memberships,
        bytes memory _data
    ) ERC1967Proxy(_memberships, _data) {
        assert(_FACTORY_SLOT == bytes32(uint256(keccak256("co.coinvise.memberships.factory")) - 1));

        if (IMembershipsFactory(msg.sender).membershipsImpls(_membershipsVersion) != _memberships)
            revert InvalidMemberships();

        _setFactory(msg.sender);
    }

    /// @notice Upgrade proxy implementation contract
    /// @dev Callable only by factory
    /// @param _memberships address of membership implementation contract to upgrade to
    function upgradeMemberships(address _memberships) public onlyFactory {
        _upgradeTo(_memberships);
    }

    /// @notice Get implementation contract address
    /// @dev Reads address set in ERC1967Proxy._IMPLEMENTATION_SLOT
    /// @return address of implementation contract
    function memberships() public view returns (address) {
        return _implementation();
    }

    /// @notice Get factory contract address
    /// @dev Reads address set in _FACTORY_SLOT
    /// @return address of factory contract
    function membershipsFactory() public view returns (address) {
        return _factory();
    }

    /// @dev Returns the current factory.
    function _factory() internal view returns (address factory) {
        bytes32 slot = _FACTORY_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            factory := sload(slot)
        }
    }

    /// @dev Stores a new address in the EIP1967 factory slot.
    function _setFactory(address factory) private {
        bytes32 slot = _FACTORY_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, factory)
        }
    }
}