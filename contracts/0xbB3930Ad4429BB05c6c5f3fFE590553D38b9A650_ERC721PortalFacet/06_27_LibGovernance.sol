// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibGovernance {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 constant STORAGE_POSITION = keccak256("governance.storage");

    struct Storage {
        bool initialized;
        // Set of active validators
        EnumerableSet.AddressSet membersSet;
        // A 1:1 map of active validators -> validator admin
        mapping(address => address) membersAdmins;
        // Precision for calculation of minimum amount of members signatures required
        uint256 precision;
        // Percentage for minimum amount of members signatures required
        uint256 percentage;
        // Admin of the contract
        address admin;
        // used to restrict certain functionality in case of an emergency stop
        bool paused;
    }

    function governanceStorage() internal pure returns (Storage storage gs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    /// @return Returns the admin
    function admin() internal view returns (address) {
        return governanceStorage().admin;
    }

    /// @return Returns true if the contract is paused, and false otherwise
    function paused() internal view returns (bool) {
        return governanceStorage().paused;
    }

    /// @return The current percentage for minimum amount of members signatures
    function percentage() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.percentage;
    }

    /// @return The current precision for minimum amount of members signatures
    function precision() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.precision;
    }

    function enforceNotPaused() internal view {
        require(!governanceStorage().paused, "LibGovernance: paused");
    }

    function enforcePaused() internal view {
        require(governanceStorage().paused, "LibGovernance: not paused");
    }

    function updateAdmin(address _newAdmin) internal {
        Storage storage ds = governanceStorage();
        ds.admin = _newAdmin;
    }

    function pause() internal {
        enforceNotPaused();
        Storage storage ds = governanceStorage();
        ds.paused = true;
    }

    function unpause() internal {
        enforcePaused();
        Storage storage ds = governanceStorage();
        ds.paused = false;
    }

    function updateMembersPercentage(uint256 _newPercentage) internal {
        Storage storage gs = governanceStorage();
        require(_newPercentage != 0, "LibGovernance: percentage must not be 0");
        require(
            _newPercentage < gs.precision,
            "LibGovernance: percentage must be less than precision"
        );
        gs.percentage = _newPercentage;
    }

    /// @notice Adds/removes a validator from the member set
    function updateMember(address _account, bool _status) internal {
        Storage storage gs = governanceStorage();
        if (_status) {
            require(
                gs.membersSet.add(_account),
                "LibGovernance: Account already added"
            );
        } else if (!_status) {
            require(
                LibGovernance.membersCount() > 1,
                "LibGovernance: contract would become memberless"
            );
            require(
                gs.membersSet.remove(_account),
                "LibGovernance: Account is not a member"
            );
        }
    }

    function updateMemberAdmin(address _account, address _admin) internal {
        governanceStorage().membersAdmins[_account] = _admin;
    }

    /// @notice Returns true/false depending on whether a given address is member or not
    function isMember(address _member) internal view returns (bool) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.contains(_member);
    }

    /// @notice Returns the count of the members
    function membersCount() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.length();
    }

    /// @notice Returns the address of a member at a given index
    function memberAt(uint256 _index) internal view returns (address) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.at(_index);
    }

    /// @notice Returns the admin of the member
    function memberAdmin(address _account) internal view returns (address) {
        Storage storage gs = governanceStorage();
        return gs.membersAdmins[_account];
    }

    /// @notice Checks if the provided amount of signatures is enough for submission
    function hasValidSignaturesLength(uint256 _n) internal view returns (bool) {
        Storage storage gs = governanceStorage();
        uint256 members = gs.membersSet.length();
        if (_n > members) {
            return false;
        }

        uint256 mulMembersPercentage = members * gs.percentage;
        uint256 requiredSignaturesLength = mulMembersPercentage / gs.precision;
        if (mulMembersPercentage % gs.precision != 0) {
            requiredSignaturesLength++;
        }

        return _n >= requiredSignaturesLength;
    }

    /// @notice Validates the provided signatures length
    function validateSignaturesLength(uint256 _n) internal view {
        require(
            hasValidSignaturesLength(_n),
            "LibGovernance: Invalid number of signatures"
        );
    }

    /// @notice Validates the provided signatures against the member set
    function validateSignatures(bytes32 _ethHash, bytes[] calldata _signatures)
        internal
        view
    {
        address[] memory signers = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);
            require(isMember(signer), "LibGovernance: invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(
                    signer != signers[j],
                    "LibGovernance: duplicate signatures"
                );
            }
            signers[i] = signer;
        }
    }
}