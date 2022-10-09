//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "erc721a/contracts/IERC721A.sol";

contract BubbleClaim is 
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 private _refundRoot;
    bytes32 private _claimRoot;

    IERC721A public nft;
    
    mapping (address => bool) private _refunded;
    mapping (address => bool) private _claimed;

    uint256 public idCounter;
    address public claimWallet;

    function initialize(bytes32 root_, bytes32 claimRoot_, IERC721A nft_) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _refundRoot = root_;
        _claimRoot = claimRoot_;
        nft = nft_;
        _pause();
    }

    receive() external payable {}

    function claim(uint256 amount_, bytes32[] calldata proof_) external whenNotPaused nonReentrant {
        require(isVerified(msg.sender, amount_, proof_, _claimRoot), "Not valid proof");
        require(!claimed(msg.sender), "Already claimed");
        _claimed[msg.sender] = true;

        uint256 startingId = idCounter;

        for(uint256 i = 0; i < amount_; i++) {
            nft.safeTransferFrom(claimWallet, msg.sender, startingId + i);            
        }

        idCounter += amount_;
    }

    function refund(uint256 amount_, bytes32[] calldata proof_) external whenNotPaused nonReentrant {
        require(isVerified(msg.sender, amount_, proof_, _refundRoot), "Not valid proof");
        require(!refunded(msg.sender), "Already claimed");
        _refunded[msg.sender] = true;

        AddressUpgradeable.sendValue(payable (msg.sender), amount_);
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable (owner()), address(this).balance);
    }

    function isVerified(address to_, uint256 amount_, bytes32[] calldata proof_, bytes32 root_) public view returns (bool) {
        return MerkleProofUpgradeable.verifyCalldata(proof_, root_, keccak256(abi.encodePacked(amount_, to_)));
    }

    function refunded(address to_) public view returns (bool) {
        return _refunded[to_];
    }

    function refundRoot() public view returns (bytes32) {
        return _refundRoot;
    }

    function setRefundRoot(bytes32 root_) external onlyOwner {
        _refundRoot = root_;
    }

    function claimed(address to_) public view returns (bool) {
        return _claimed[to_];
    }

    function claimRoot() public view returns (bytes32) {
        return _claimRoot;
    }

    function setClaimRoot(bytes32 root_) external onlyOwner {
        _claimRoot = root_;
    } 
    
    function setNFT(IERC721A _nft) external onlyOwner {
        nft = _nft;
    }

    function setClaimWallet(address _claimWallet) external onlyOwner {
        claimWallet = _claimWallet;
    }

    function togglePause(bool value_) external onlyOwner {
        if(value_) _pause();
        else _unpause();
    }
}