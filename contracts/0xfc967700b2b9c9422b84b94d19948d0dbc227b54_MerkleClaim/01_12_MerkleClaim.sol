//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {MerkleHashValidator} from "./MerkleHashValidator.sol";

contract MerkleClaim is Ownable, Pausable {

    using SafeERC20 for IERC20;

    IERC20 public immutable USDTToken;
    bytes32 public merkleRoot;
    
    mapping(address => bool) public alreadyClaimed;

    constructor(bytes32 _root, IERC20 _USDTToken) {
        merkleRoot = _root;
        USDTToken = _USDTToken;
    }

    /// @notice Allows a msg.sender to claim their USDT token back from the Minima Crowdsale by providing a
    /// merkle proof proving their address is indeed committed to by the Merkle root
   
    function merkleClaim(bytes32[] calldata _proof, address _to, uint256 _amount) external {
        require(!alreadyClaimed[_to], "merkleClaim: User has already claimed USDT");
        //generate node from address and amount
        bytes32 _node = keccak256(abi.encodePacked(_to, _amount));
        //check if node is valid
        bool isValidProof = MerkleHashValidator.validateEntry(merkleRoot, _proof, _node);
        require(isValidProof, 'merkleClaim: Incorrect proof');
        //add user to mapping of already claimed users
        alreadyClaimed[_to] = true;
        //send airdrop tokens to user
        USDTToken.safeTransfer(_to, _amount);
        //emit Refunded event
        emit Refunded(_to, _amount);
    }

    function toLeafFormat(address _claimer, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(bytes(abi.encode(_claimer, _amount)));
    }

    function withdrawUSDT() external onlyOwner {
        USDTToken.safeTransfer(msg.sender, USDTToken.balanceOf(address(this)));
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    event Refunded(address addr, uint256 amount);
}