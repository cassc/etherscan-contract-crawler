// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./utils/Governable.sol";
import "./interfaces/ISGT.sol";

contract Migration is Governable, ReentrancyGuard {
    // state variables
    bool public paused;
    address immutable public token;
    bytes32 immutable public merkleRoot;
    mapping(address => bool) private _migrated;

    // modifiers
    modifier whileUnpaused() {
        require(!paused, "contract paused");
        _;
    }

    // events
    event PauseSet(bool paused);
    event Migrated(address account, uint256 value);

    constructor(address _token, bytes32 _merkleRoot, address _governance) Governable(_governance) {
        require(_token != address(0), "zero address token");
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function migrate(address _account, uint256 _amount, bytes32[] memory _proof) external whileUnpaused nonReentrant {
        // check
        require(!_migrated[_account], "already migrated");
        require(_account != address(0x0), "zero address account");
        require(_amount != 0, "zero amount to migrate");

        // verify proof
        require(verify(_account, _amount, _proof), "invalid account");

        // migrate
        _migrated[_account] = true;
        ISGT(token).mint(_account, _amount);

        // emit
        emit Migrated(_account, _amount);
    }

    function migrated(address _account) public view returns (bool) {
        return _migrated[_account];
    }

    function verify(address _account, uint256 _amount, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, createNode(_account, _amount));
    }

    function createNode(address _account, uint256 _amount) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));
    }

    function setPaused(bool _paused) external onlyGovernance {
        paused = _paused;
        emit PauseSet(_paused);
    }

}