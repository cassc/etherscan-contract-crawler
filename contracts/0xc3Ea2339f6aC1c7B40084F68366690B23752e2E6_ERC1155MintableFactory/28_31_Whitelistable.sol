// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelistable is AccessControl {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public merkleRoot;
    uint256 startTimeWhitelist = 0;
    uint256 endTimeWhitelist = 0;
    uint256 startTime = 0;
    uint256 endTime = 0;

    error InvalidAction(string);
    error AdminOnly();

    mapping(address => bool) whitelistClaimed;

    // Contains basic availability logic
    function isAvailable(uint256 _start, uint256 _end)
        internal
        view
        returns (bool available)
    {
        // By default we verify if start is greater than block timestampo
        available = block.timestamp >= _start;

        // If _end is greater than zero, it means that it is configured
        if (available && _end > 0) {
            available = block.timestamp < _end;
        }
    }

    function setTime(
        uint256 _startTime,
        uint256 _endTime,
        bool _whitelist
    ) external onlyAdmin {
        if (_whitelist) {
            startTimeWhitelist = _startTime;
            endTimeWhitelist = _endTime;
        } else {
            startTime = _startTime;
            endTime = _endTime;
        }
    }

    function getAvailability() external view returns (uint256[4] memory) {
        return [startTime, endTime, startTimeWhitelist, endTimeWhitelist];
    }

    function setWhitelistMerkleRoot(bytes32 _newMerkleRoot) external onlyAdmin {
        merkleRoot = _newMerkleRoot;
    }

    function isWhiteListed(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    modifier onlyAdmin() {
        if (!hasRole(ROLE_ADMIN, msg.sender)) revert AdminOnly();
        _;
    }
}