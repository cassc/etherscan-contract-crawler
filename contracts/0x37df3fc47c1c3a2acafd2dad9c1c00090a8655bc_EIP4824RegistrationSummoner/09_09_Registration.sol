// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";

/// @title EIP-4824 DAOs
/// @dev See <https://eips.ethereum.org/EIPS/eip-4824>
interface EIP4824 {
    /// @notice A distinct Uniform Resource Identifier (URI) pointing to a JSON object following the "EIP-4824 DAO JSON-LD Schema". This JSON file splits into four URIs: membersURI, proposalsURI, activityLogURI, and governanceURI. The membersURI should point to a JSON file that conforms to the "EIP-4824 Members JSON-LD Schema". The proposalsURI should point to a JSON file that conforms to the "EIP-4824 Proposals JSON-LD Schema". The activityLogURI should point to a JSON file that conforms to the "EIP-4824 Activity Log JSON-LD Schema". The governanceURI should point to a flatfile, normatively a .md file. Each of the JSON files named above can be statically-hosted or dynamically-generated.
    function daoURI() external view returns (string memory _daoURI);
}

error NotDaoOrManager();
error NotDao();
error NotCandidate();
error AlreadyInitialized();
error OfferExpired();

/// @title EIP-4824: DAO Registration
contract EIP4824Registration is EIP4824, AccessControl {
    event NewURI(string daoURI, address daoAddress);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string private _daoURI;

    address daoAddress;

    constructor() {
        daoAddress = address(0xdead);
    }

    /// @notice Set the initial DAO URI and offer manager role to an address
    /// @dev Throws if initialized already
    /// @param _daoAddress The primary address for a DAO
    /// @param _manager The address of the URI manager
    /// @param daoURI_ The URI which will resolve to the governance docs
    function initialize(
        address _daoAddress,
        address _manager,
        string memory daoURI_
    ) external {
        initialize(_daoAddress, daoURI_);
        _grantRole(MANAGER_ROLE, _manager);
    }

    /// @notice Set the initial DAO URI
    /// @dev Throws if initialized already
    /// @param _daoAddress The primary address for a DAO
    /// @param daoURI_ The URI which will resolve to the governance docs
    function initialize(address _daoAddress, string memory daoURI_) public {
        if (daoAddress != address(0)) revert AlreadyInitialized();
        daoAddress = _daoAddress;
        _setURI(daoURI_);

        _grantRole(DEFAULT_ADMIN_ROLE, _daoAddress);
        _grantRole(MANAGER_ROLE, _daoAddress);
    }

    /// @notice Update the URI for a DAO
    /// @dev Throws if not called by dao or manager
    /// @param daoURI_ The URI which will resolve to the governance docs
    function setURI(string memory daoURI_) public onlyRole(MANAGER_ROLE) {
        _setURI(daoURI_);
    }

    function _setURI(string memory daoURI_) internal {
        _daoURI = daoURI_;
        emit NewURI(daoURI_, daoAddress);
    }

    function daoURI() external view returns (string memory daoURI_) {
        return _daoURI;
    }
}

error ArrayLengthsMismatch();

contract EIP4824RegistrationSummoner {
    event NewRegistration(
        address indexed daoAddress,
        string daoURI,
        address registration
    );

    address public template; /*Template contract to clone*/

    constructor(address _template) {
        template = _template;
    }

    function registrationAddress(address by, bytes32 salt)
        external
        view
        returns (address addr, bool exists)
    {
        addr = Clones.predictDeterministicAddress(
            template,
            _saltedSalt(by, salt),
            address(this)
        );
        exists = addr.code.length > 0;
    }

    function summonRegistration(
        bytes32 salt,
        string calldata daoURI_,
        address manager,
        address[] calldata contracts,
        bytes[] calldata data
    ) external returns (address registration, bytes[] memory results) {
        registration = Clones.cloneDeterministic(
            template,
            _saltedSalt(msg.sender, salt)
        );

        if (manager == address(0)) {
            EIP4824Registration(registration).initialize(msg.sender, daoURI_);
        } else {
            EIP4824Registration(registration).initialize(
                msg.sender,
                manager,
                daoURI_
            );
        }

        results = _callContracts(contracts, data);

        emit NewRegistration(msg.sender, daoURI_, registration);
    }

    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================

    /**
     * @dev Call the `contracts` in order with `data`.
     * @param contracts The addresses of the contracts.
     * @param data      The `abi.encodeWithSelector` calldata for each of the contracts.
     * @return results The results of calling the contracts.
     */
    function _callContracts(address[] calldata contracts, bytes[] calldata data)
        internal
        returns (bytes[] memory results)
    {
        if (contracts.length != data.length) revert ArrayLengthsMismatch();

        assembly {
            // Grab the free memory pointer.
            // We will use the free memory to construct the `results` array,
            // and also as a temporary space for the calldata.
            results := mload(0x40)
            // Set `results.length` to be equal to `data.length`.
            mstore(results, data.length)
            // Skip the first word, which is used to store the length
            let resultsOffsets := add(results, 0x20)
            // Compute the location of the last calldata offset in `data`.
            // `shl(5, n)` is a gas-saving shorthand for `mul(0x20, n)`.
            let dataOffsetsEnd := add(data.offset, shl(5, data.length))
            // This is the start of the unused free memory.
            // We use it to temporarily store the calldata to call the contracts.
            let m := add(resultsOffsets, shl(5, data.length))

            // Loop through `contacts` and `data` together.
            // prettier-ignore
            for { let i := data.offset } iszero(eq(i, dataOffsetsEnd)) { i := add(i, 0x20) } {
                // Location of `bytes[i]` in calldata.
                let o := add(data.offset, calldataload(i))
                // Copy `bytes[i]` from calldata to the free memory.
                calldatacopy(
                    m, // Start of the unused free memory.
                    add(o, 0x20), // Location of starting byte of `data[i]` in calldata.
                    calldataload(o) // The length of the `bytes[i]`.
                )
                // Grab `contracts[i]` from the calldata.
                // As `contracts` is the same length as `data`,
                // `sub(i, data.offset)` gives the relative offset to apply to
                // `contracts.offset` for `contracts[i]` to match `data[i]`.
                let c := calldataload(add(contracts.offset, sub(i, data.offset)))
                // Call the contract, and revert if the call fails.
                if iszero(
                    call(
                        gas(), // Gas remaining.
                        c, // `contracts[i]`.
                        0, // `msg.value` of the call: 0 ETH.
                        m, // Start of the copy of `bytes[i]` in memory.
                        calldataload(o), // The length of the `bytes[i]`.
                        0x00, // Start of output. Not used.
                        0x00 // Size of output. Not used.
                    )
                ) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `m` into `resultsOffsets`.
                mstore(resultsOffsets, m)
                resultsOffsets := add(resultsOffsets, 0x20)

                // Append the `returndatasize()` to `results`.
                mstore(m, returndatasize())
                // Append the return data to `results`.
                returndatacopy(add(m, 0x20), 0x00, returndatasize())
                // Advance `m` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                // `0x3f = 32 + 31`. The mask is `type(uint64).max & ~31`,
                // which is big enough for all purposes (see memory expansion costs).
                m := and(add(add(m, returndatasize()), 0x3f), 0xffffffffffffffe0)
            }
            // Allocate the memory for `results` by updating the free memory pointer.
            mstore(0x40, m)
        }
    }

    function _saltedSalt(address by, bytes32 salt)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // Store the variables into the scratch space.
            mstore(0x00, by)
            mstore(0x20, salt)
            // Equivalent to `keccak256(abi.encode(by, salt))`.
            result := keccak256(0x00, 0x40)
        }
    }
}