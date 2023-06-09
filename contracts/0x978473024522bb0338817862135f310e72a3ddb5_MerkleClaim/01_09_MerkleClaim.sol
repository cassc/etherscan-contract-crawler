//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {MerkleHashValidator} from "./MerkleHashValidator.sol";

contract MerkleClaim is Ownable, Pausable {

    IERC20 public immutable wMinimaToken;
    bytes32 public merkleRoot;
    
    mapping(address => bool) public alreadyClaimed;

    constructor(bytes32 _root, IERC20 _wMinimaToken) {
        merkleRoot = _root;
        wMinimaToken = _wMinimaToken;
    }

    /// @notice Allows a msg.sender to claim their wMINIMA token by providing a
    /// merkle proof proving their address is indeed committed to by the Merkle root
    /// stored in `Airdrop.merkleRoot`
   
    function merkleClaim(bytes32[] calldata _proof, address _to, uint256 _amount) external {
        require(!alreadyClaimed[_to], "merkleClaim: User has already claimed wMinima");
        //generate node from address and amount
        bytes32 _node = keccak256(abi.encodePacked(_to, _amount));
        //check if node is valid
        bool isValidProof = MerkleHashValidator.validateEntry(merkleRoot, _proof, _node);
        require(isValidProof, 'merkleClaim: Incorrect proof');
        //add user to mapping of already claimed users
        alreadyClaimed[_to] = true;
        //send airdrop tokens to user
        wMinimaToken.transfer(_to, _amount);
        //emit Redeemed event
        emit Redeemed(_to, _amount);
    }

    function toLeafFormat(address _claimer, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(bytes(abi.encode(_claimer, _amount)));
    }

    function withdrawWMinima() external onlyOwner {
        wMinimaToken.transfer(msg.sender, wMinimaToken.balanceOf(address(this)));
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    event Redeemed(address addr, uint256 amount);
}