// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Context, Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INFTLocker} from "../interfaces/INFTLocker.sol";
import {IPendingFeeDistributor} from "../interfaces/IPendingFeeDistributor.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PendingFeeDistributor is
    IPendingFeeDistributor,
    Ownable,
    ReentrancyGuard
{
    bytes32 public merkleRoot;

    IERC20 public rewardToken;
    mapping(uint256 => bool) public hasClaimed;
    INFTLocker public locker;

    constructor(
        bytes32 _merkleRoot,
        address _rewardToken,
        address _owner,
        address _locker
    ) {
        merkleRoot = _merkleRoot;
        rewardToken = IERC20(_rewardToken);
        locker = INFTLocker(_locker);
        _transferOwnership(_owner);
    }

    function distribute(
        uint256 _tokenId,
        uint256 _reward,
        bytes32[] memory proof
    ) external override nonReentrant returns (uint256) {
        require(validProof(_tokenId, _reward, proof), "invalid proof");
        require(_tokenId > 0, "Token id = 0");

        if (hasClaimed[_tokenId]) return 0;
        hasClaimed[_tokenId] = true;

        address _owner = locker.ownerOf(_tokenId);
        rewardToken.transfer(_owner, _reward);
        emit HistoricRewardPaid(_owner, _tokenId, _reward);
        return _reward;
    }

    function validProof(
        uint256 _tokenId,
        uint256 _reward,
        bytes32[] memory proof
    ) public view override returns (bool) {
        bytes32 leaf = keccak256(abi.encode(_reward, _tokenId));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function refund(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setProof(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}