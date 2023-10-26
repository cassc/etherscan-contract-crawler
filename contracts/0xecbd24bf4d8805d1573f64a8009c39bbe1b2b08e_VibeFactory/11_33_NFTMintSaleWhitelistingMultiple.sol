// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./NFTMintSaleMultiple.sol";

contract NFTMintSaleWhitelistingMultiple is NFTMintSaleMultiple, BoringBatchable {

    uint256 public NON_WHITELISTED_MAX_PER_USER;

    event LogInitUser(address indexed user, uint256 maxMintUser, uint256 tier);
    event LogSetMerkleRoot(bytes32 indexed merkleRoot, string externalURI, uint256 maxNonWhitelistedPerUser);

    mapping(uint256 => bytes32) public merkleRoot;
    mapping(uint256 => string) public externalURI;

    struct UserAllowed {
        uint128 claimed;
        uint128 max;
    }

    mapping(uint256 => mapping(address => UserAllowed)) claimed;

    constructor (SimpleFactory vibeFactory_, IWETH WETH_) NFTMintSaleMultiple(vibeFactory_, WETH_) {
    }

    function setMerkleRoot(bytes32[] calldata _merkleRoot, string[] calldata externalURI_, uint256 maxNonWhitelistedPerUser) external onlyOwner{
        for(uint i; i < _merkleRoot.length; i++) {
            merkleRoot[i] = _merkleRoot[i];
            externalURI[i] = externalURI_[i];
            emit LogSetMerkleRoot(_merkleRoot[i], externalURI_[i], maxNonWhitelistedPerUser);
        }
        NON_WHITELISTED_MAX_PER_USER = maxNonWhitelistedPerUser;
    }

    function _preBuyCheck(address /*recipient*/, uint256 tier) internal virtual override {
        require(claimed[tier][msg.sender].claimed < claimed[tier][msg.sender].max, "no allowance left");
        claimed[tier][msg.sender].claimed += 1;
    }

    function initUser(address user, bytes32[] calldata merkleProof, uint256 maxMintUser, uint256 tier)
        public payable
    {
        if (merkleRoot[tier] != bytes32(0)) {
            require(
                MerkleProof.verify(
                    merkleProof,
                    merkleRoot[tier],
                    keccak256(abi.encodePacked(user, maxMintUser))
                ),
                "invalid merkle proof"
            );
        } else {
            maxMintUser = NON_WHITELISTED_MAX_PER_USER;
        }

        claimed[tier][user].max = uint128(maxMintUser);
        emit LogInitUser(user, maxMintUser, tier);
    }

}