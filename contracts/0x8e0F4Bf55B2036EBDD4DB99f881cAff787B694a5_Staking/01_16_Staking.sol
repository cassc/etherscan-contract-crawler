//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chocolate-factory/contracts/staking/ReceiverUpgradeable.sol";
import "@chocolate-factory/contracts/staking/TrackerUpgradeable.sol";
import "@chocolate-factory/contracts/signer/SignerUpgradeable.sol";
import "@chocolate-factory/contracts/admin-manager/AdminManagerUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Staking is Initializable, ReceiverUpgradeable, AdminManagerUpgradable, SignerUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    struct Request {
        uint256[] ids;
        address owner;
    }

    bytes32 private constant REQUEST_TYPE_HASH = keccak256("Request(uint256[] ids,address owner)");
    
    bytes32 private constant STAKING_REQUEST_TYPE_HASH = keccak256("StakingRequest(uint256[] ids,address owner,uint256 expiry)");
    bytes32 private constant UNSTAKING_REQUEST_TYPE_HASH = keccak256("UnstakingRequest(uint256[] ids,address owner,uint256 expiry)");

    struct StakingRequest {
        uint256[] ids;
        address owner;
        uint256 expiry;
    }

    struct UnstakingRequest {
        uint256[] ids;
        address owner;
        uint256 expiry;
    }

    event Staked(uint256[] ids, address indexed owner);
    event Unstaked(uint256[] ids, address indexed owner);

    function initialize(
        IERC721Upgradeable nft,
        string memory name,
        string memory version,
        address signer
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __AdminManager_init();
        __Receiver_init(nft);        
        __Signer_init_unchained(name, version, signer);
    }

    function stake(StakingRequest calldata request_, bytes calldata signature_) external whenNotPaused verifyStaking(request_, signature_)  {
        uint256[] memory ids = request_.ids;
        uint256 length = ids.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            _receive(current, msg.sender);
        }
        emit Staked(ids, msg.sender);
    }

    function unstake(UnstakingRequest calldata request_, bytes calldata signature_) external whenNotPaused verifyUnstaking(request_, signature_) {
        uint256[] memory ids = request_.ids;
        uint256 length = ids.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            _return(current, msg.sender);
        }
        emit Unstaked(ids, msg.sender);
    }
    
    function setSigner(address signer_) external onlyAdmin {
        signer = signer_;
    }

    modifier verifyStaking(StakingRequest calldata request_, bytes calldata signature_)  {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    STAKING_REQUEST_TYPE_HASH, 
                    keccak256(abi.encodePacked(request_.ids)),
                    msg.sender
                )
            )
        );
        require(_verify(digest, signature_), "Invalid Signature");
        require(request_.expiry > block.timestamp, "Expired");
        _;
    }

     modifier verifyUnstaking(UnstakingRequest calldata request_, bytes calldata signature_)  {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UNSTAKING_REQUEST_TYPE_HASH, 
                    keccak256(abi.encodePacked(request_.ids)),
                    msg.sender
                )
            )
        );
        require(_verify(digest, signature_), "Invalid Signature");
        require(request_.expiry > block.timestamp, "Expired");
        _;
    }

    function setNFT(IERC721Upgradeable _nft) external onlyAdmin {
        nft = _nft;
    }
}