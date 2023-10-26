// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./NFTMintSale.sol";

contract NFTMintSaleWhitelisting is NFTMintSale, BoringBatchable {
    uint256 public NON_WHITELISTED_MAX_PER_USER;

    event LogInitUser(address indexed user, uint256 maxMintUser);
    event LogSetMerkleRoot(bytes32 indexed merkleRoot, string externalURI, uint256 maxNonWhitelistedPerUser);

    bytes32 public merkleRoot;
    string public externalURI;

    struct UserAllowed {
        uint128 claimed;
        uint128 max;
    }

    mapping(address => UserAllowed) claimed;

    constructor (SimpleFactory vibeFactory_, IWETH WETH_) NFTMintSale(vibeFactory_, WETH_) {
    }

    function setMerkleRoot(bytes32 merkleRoot_, string memory externalURI_, uint256 maxNonWhitelistedPerUser) public onlyOwner {
        merkleRoot = merkleRoot_;
        externalURI = externalURI_;
        NON_WHITELISTED_MAX_PER_USER = maxNonWhitelistedPerUser;
        emit LogSetMerkleRoot(merkleRoot_, externalURI_, maxNonWhitelistedPerUser);
    }

    function _preBuyCheck(address /*recipient*/) internal virtual override {
        require(claimed[msg.sender].claimed < claimed[msg.sender].max, "no allowance left");
        claimed[msg.sender].claimed += 1;
    }

    function initUser(address user, bytes32[] calldata merkleProof, uint256 maxMintUser)
        public payable
    {
        if(merkleRoot != bytes32(0)) {
            require(
                MerkleProof.verify(
                    merkleProof,
                    merkleRoot,
                    keccak256(abi.encodePacked(user, maxMintUser))
                ),
                "invalid merkle proof"
            );
        } else {
            maxMintUser = NON_WHITELISTED_MAX_PER_USER;
        }
        claimed[user].max = uint128(maxMintUser);

        emit LogInitUser(user, maxMintUser);
    }

}