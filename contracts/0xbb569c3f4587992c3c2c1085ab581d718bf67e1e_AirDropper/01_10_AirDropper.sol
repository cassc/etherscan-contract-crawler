// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AirDropper is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ClaimEnded();
    error AlreadyClaimed();
    error IncorrectMerkle();

    bytes32 public immutable _root;

    uint256 private immutable _deadline;

    address private immutable _token;

    address private immutable _treasury;

    mapping(address => bool) claimed;

    constructor(
        bytes32 root_,
        uint256 duration_,
        address token_,
        address treasury_
    ) {
        _root = root_;
        _deadline = block.timestamp + duration_;
        _token = token_;
        _treasury = treasury_;
    }

    function deadline() external view returns (uint256) {
        return _deadline;
    }

    function hasClaimed() external view returns (bool) {
        return _hasClaimed(msg.sender);
    }

    function _hasClaimed(address user) private view returns (bool) {
        return claimed[user];
    }

    function claim(
        bytes32[] calldata _proof,
        uint amount
    ) external nonReentrant {
        if (block.timestamp > _deadline) {
            _revert(ClaimEnded.selector);
        }

        if (claimed[msg.sender]) {
            _revert(AlreadyClaimed.selector);
        }
        claimed[msg.sender] = true;

        bytes32 _leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        if (!MerkleProof.verify(_proof, _root, _leaf)) {
            _revert(IncorrectMerkle.selector);
        }

        IERC20(_token).safeTransferFrom(_treasury, msg.sender, amount);
    }

    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}