// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IFitcoin.sol";
import "./NFTFitCoin.sol";

contract ChallengeEnroll is PausableUpgradeable, ReentrancyGuardUpgradeable,OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    IFitCoin private token;
    FitcoinNFT private fitcoinNFT;
    bool public initialize;

    mapping(address => bool) private authorizedSigners;
    mapping(bytes32 => bool) private usedHashesChallenge;
    mapping(bytes32 => bool) private usedHashesLock;
    mapping(bytes32 => bool) private usedHashesBonus;
    mapping(address => uint256) public lockAmount;

    mapping(bytes32 => bool) public records;

    event UserEnrolled( uint256 indexed userId, address userAddress, uint256 tokenAmount, uint256 nonce, uint256 indexed challengeId);
    event UserTokenLocked( uint256 indexed userId, address userAddress, uint256 tokenAmount, uint256 nonce);
    event BonusClaimed( uint256 indexed userId, address userAddress, uint256 tokenAmount, uint256 nonce);
    event NFTClaimed( uint256 indexed userId, uint256 challengeId,address userAddress, uint256 nftId, uint256 nonce);
    event UserTokenUnlocked( address userAddress, uint256 tokenAmount);


    function init(address tokenAddress, address nftAddress)external initializer{
        require(initialize == false);
        
        token = IFitCoin(tokenAddress);
        fitcoinNFT = FitcoinNFT(nftAddress);

        __Ownable_init();
        __Pausable_init();

        initialize = true;
    }

    function enrollUser(uint256 userId, address userAddress, uint256 tokenAmount, uint256 nonce, uint256 challengeId) external whenNotPaused {
        bytes32 messageHash = keccak256(abi.encodePacked(userId, userAddress, tokenAmount, nonce, challengeId));
        require(!usedHashesChallenge[messageHash], "Message hash already used");
       
        usedHashesChallenge[messageHash] = true;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        token.burn(tokenAmount);

        emit UserEnrolled(userId, userAddress, tokenAmount, nonce, challengeId);   

    }

    function bonusLock(uint256 userId, address userAddress, uint256 tokenAmount, uint256 nonce) 
        external whenNotPaused nonReentrant {

        require(userAddress != address(0), "Invalid user address");
        require(tokenAmount > 0 , "Invalid token amount");

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        lockAmount[msg.sender] += tokenAmount;

        emit UserTokenLocked(userId, userAddress, tokenAmount, nonce);   
    }

    function bonusUnlock(uint256 tokenAmount) external whenNotPaused nonReentrant{
        require(tokenAmount > 0 , "Invalid token amount");
        require(lockAmount[msg.sender] >= tokenAmount, "Can not unlock more than locked amount");
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        lockAmount[msg.sender] -= tokenAmount;

        emit UserTokenUnlocked(msg.sender, tokenAmount);   
    }

    function updateSignerStatus(address signer, bool status) external onlyOwner {
        authorizedSigners[signer] = status;
    }

    function isSigner(address signer) external view returns (bool) {
        return authorizedSigners[signer];
    }

    function fitcoinMint(uint256 userId, uint256 amount_, uint256 nonce, bytes memory signature_)
        external whenNotPaused nonReentrant returns(bytes32 mintId){
        
        require(nonce > (block.timestamp - 10), "signature expired");
        mintId = keccak256(
            abi.encodePacked(
                userId,
                msg.sender,
                amount_,
                nonce
                )
            );

        bytes32 prefixedHash = mintId.toEthSignedMessageHash();
        address msgSigner = recover(prefixedHash, signature_);

        require (authorizedSigners[msgSigner], "Invalid message signer");

        require(records[mintId] == false, "record exists");
        records[mintId] = true;

        token.mint(msg.sender, amount_);

        emit BonusClaimed(userId, msg.sender, amount_, nonce);

    }

    function fitcoinNFTMint(uint256 userId, uint256 challengeId,uint256 nftId, uint256 nonce, bytes memory signature_)
        external whenNotPaused nonReentrant returns(bytes32 mintId){

        mintId = keccak256(
            abi.encodePacked(
                userId,
                challengeId,
                msg.sender,
                nftId,
                nonce
                )
            );

        bytes32 prefixedHash = mintId.toEthSignedMessageHash();
        address msgSigner = recover(prefixedHash, signature_);

        require (authorizedSigners[msgSigner], "Invalid message signer");

        require(records[mintId] == false, "record exists");
        records[mintId] = true;

        // mint NFT here
        fitcoinNFT.mint(msg.sender, nftId);

        emit NFTClaimed(userId, challengeId, msg.sender, nftId, nonce);
    }

    function recover(bytes32 hash, bytes memory signature_) private pure returns(address) {
        return hash.recover(signature_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}