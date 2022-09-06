// SPDX-License-Identifier: AGPL-1.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721_NFT.sol";
import "./Crypto_SignatureVerifier.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @custom:security-contact [email protected]
contract StakingV3 is SignatureVerifier, Ownable {
    // track staked Token IDs to addresses to return to
    struct stakingStatus {
        address stakedBy;
    }

    mapping(address => mapping(uint256 => stakingStatus)) public records;
    bool public canManualUnstake;
    mapping(address => uint256) public nonces;

    constructor(address signer)
    SignatureVerifier(signer)
    {
    }

    // stake registers the asset into the marketplace
    function stake(address collection, uint256 tokenId) public {
        IERC721 nftContract = ERC721(collection);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "you are not the owner of this token"
        );
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        records[collection][tokenId].stakedBy = msg.sender;
        emit Staked(collection, msg.sender, tokenId);
    }

    // signedUnstake uses a server-side signature to unstake an NFT
    // spreads out the gas cost
    // deregisters from marketplace
    function signedUnstake(
        address collection,
        uint256 tokenId,
        bytes calldata signature,
        uint256 expiry
    ) public {
        require(expiry > block.timestamp, "signature expired");
        uint256 nonce = nonces[msg.sender]++;
        bytes32 messageHash = getUnstakeMessageHash(
            collection,
            msg.sender,
            tokenId,
            nonce,
            expiry
        );
        require(verify(messageHash, signature), "Invalid Signature");
        IERC721 nftContract = ERC721(collection);
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "this contract does not own the requested tokenId"
        );
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        emit SignedUnstaked(collection, msg.sender, tokenId);
    }

    // getUnstakeMessageHash builds the hash
    function getUnstakeMessageHash(
        address collection,
        address owner,
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(collection, owner, tokenId, nonce, expiry));
    }

    // unstake deregisters the asset from the game
    // for manual unstake
    // not for normal operation
    function unstake(address collection, uint256 tokenId) public {
        IERC721 nftContract = ERC721(collection);
        address to = records[collection][tokenId].stakedBy;
        require(canManualUnstake, "manual unstake not enabled");
        require(to == msg.sender, "you are not the original staker");
        nftContract.transferFrom(address(this), to, tokenId);
        records[collection][tokenId].stakedBy = address(0x0);
        emit ManualUnstaked(collection, to, tokenId);
    }

    // remap changes the owner of an NFT
    // is used reconcile multiple transfers that have happened offchain
    // not for normal operation
    function remap(
        address collection,
        uint256 tokenId,
        address newAddr
    ) public onlyOwner {
        records[collection][tokenId].stakedBy = newAddr;
        emit Remap(collection, newAddr, tokenId);
    }

    // setCanUnstake when manual unstake is required
    // not for normal operation
    function setCanUnstake(bool _canManualUnstake) public onlyOwner {
        canManualUnstake = _canManualUnstake;
        emit SetCanManualUnstake(_canManualUnstake);
    }

    event Staked(
        address indexed collection,
        address indexed owner,
        uint256 tokenId
    );
    event ManualUnstaked(
        address indexed collection,
        address indexed owner,
        uint256 tokenId
    );
    event SignedUnstaked(
        address indexed collection,
        address indexed owner,
        uint256 tokenId
    );
    event SetCanManualUnstake(bool _canManualUnstake);
    event Remap(
        address indexed collection,
        address indexed newAddr,
        uint256 tokenId
    );
}