// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Pausable.sol";

import "Ownable.sol";
import "TransferProtector.sol";

contract TransferProtectorFactory is TransferOwnable, Pausable {
    string public constant NAME = "Cobo TransferProtector Factory";
    string public constant VERSION = "0.1.0";

    /// @dev the default subSafe factory to work with
    address public subSafeFactory;

    /// @dev the protector list
    address[] public protectors;
    /// @dev mapping from `safe` => `protector`
    mapping(address => address) public safeToProtector;
    /// @dev mapping from `protector` => `safe`
    mapping(address => address) public protectorToSafe;

    /// @notice Event fired when a protector is created
    /// @dev Event fired when a a protector is created via `createProtector`
    /// @param safe the protector's owner
    /// @param protector the protector created
    /// @param sender the owner who created the protector
    event TransferProtectorCreated(
        address indexed safe,
        address indexed protector,
        address indexed sender
    );

    /// @notice Create the protector with nonce for safe
    /// @dev The factory contract to create TransferProtector by using provided nonce for safe.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _nonce as the seed of salt
    function createProtector(address payable _safe, uint256 _nonce)
        public
        whenNotPaused
        returns (address _protector)
    {
        require(_safe != address(0), "Invalid safe address");
        require(safeToProtector[_safe] == address(0), "Protector already created");
        bytes memory bytecode = type(TransferProtector).creationCode;

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(_safe)
        );
        bytes32 salt = keccak256(abi.encodePacked(_safe, address(this), _nonce));

        assembly {
            _protector := create2(
                0,
                add(creationCode, 32),
                mload(creationCode),
                salt
            )
        }
        require(_protector != address(0), "Failed to create protector");
        protectors.push(_protector);
        safeToProtector[_safe] = _protector;
        protectorToSafe[_protector] = _safe;

        emit TransferProtectorCreated(_safe, _protector, _msgSender());
    }

    /// @notice Set the factory pause status
    /// @param paused the paused status of true|false
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /// @notice return the total count of created protectors
    /// @return The total count of created protectors
    function protectorsSize() public view returns (uint256) {
        return protectors.length;
    }
}