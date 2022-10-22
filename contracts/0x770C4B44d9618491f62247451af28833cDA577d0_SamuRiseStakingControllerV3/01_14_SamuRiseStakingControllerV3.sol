// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./IERC721NES.sol";

import "hardhat/console.sol";

/**
 * SamuRise Staking controller
 */
contract SamuRiseStakingControllerV3 is OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    
    // Address of the ERC721 token contract
    address tokenContract;
    
    // For each token, this map stores the the block.number
    // of the block they started staking in.
    // if token is mapped to 0, it is currently unstaked.
    mapping(uint256 => uint256) public tokenToWhenStaked;

    // For each token, this map stores the total duration staked
    // measured by block.number
    mapping(uint256 => uint256) public tokenToTotalDurationStaked;

    // Lock down of staking actions for launching boat to L2
    bool stakingPaused;
    
    // tracks whether contract has been initialized
    bool private initialized;

    // V3 variables:
    address public signatureVerifier;
    mapping(bytes32 => bool) public usedHashes;
    mapping(address => mapping(uint256 => bool)) public addressToTokenIdToInitalized;
    mapping(address => mapping(uint256 => uint256)) public addressToTokenIdToNonce;
    
    /**
     *  @dev constructor
     */
    function initialize(address _tokenContract) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        tokenContract = _tokenContract;

        __UUPSUpgradeable_init();
        __Ownable_init();
        
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(message));
        require(messageHash.recover(_signature) == signatureVerifier, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Hash has already been used");

        usedHashes[messageHash] = true;
        _;
    }

    /**
     *  @dev returns the additional balance between when token was staked until now
     */
    function getCurrentAdditionalBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (tokenToWhenStaked[tokenId] > 0) {
            return block.number - tokenToWhenStaked[tokenId];
        } else {
            return 0;
        }
    }

    /**
     *  @dev returns total duration the token has been staked.
     */
    function getCumulativeDurationStaked(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return tokenToTotalDurationStaked[tokenId] + getCurrentAdditionalBalance(tokenId);
    }

    /**
     *  @dev Returns the amount of tokens rewarded up until this point.
     */
    function getStakingRewards(uint256 tokenId) public view returns (uint256) {
        return getCumulativeDurationStaked(tokenId); 
    }

    /**
     *  @dev Returns the amount of tokens rewarded up until this point.
     */
     function stakeFromTokenContract(uint256 tokenId, address originator) public {
        require(
            msg.sender == tokenContract,
            "Function can only be called from token contract"
        );
        require(
            IERC721NES(tokenContract).ownerOf(tokenId) == originator,
            "Originator is not the owner of this token"
        );
        tokenToWhenStaked[tokenId] = block.number;
        IERC721NES(tokenContract).stakeFromController(tokenId, originator);
    }

    /**
     *  @dev Stakes a token and records the start block number or time stamp.
     */
    function stake(uint256 tokenId) internal {
        require(
            IERC721NES(tokenContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(
            IERC721NES(tokenContract).isStaked(tokenId) == false,
            "Token is already staked"
        );
        require(!stakingPaused, "Staking is currently paused");

        tokenToWhenStaked[tokenId] = block.number;
        IERC721NES(tokenContract).stakeFromController(tokenId, msg.sender);
    }

    /**
     *  @dev Unstakes a token and records the start block number or time stamp.
     */
    function unstake(uint256 tokenId) internal {
        require(
            IERC721NES(tokenContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(
            IERC721NES(tokenContract).isStaked(tokenId) == true,
            "Token is not staked"
        );
        require(!stakingPaused, "Unstaking is currently paused");

        tokenToTotalDurationStaked[tokenId] += getCurrentAdditionalBalance(tokenId);
        tokenToWhenStaked[tokenId] = 0;
        IERC721NES(tokenContract).unstakeFromController(tokenId, msg.sender);
    }

        /**
     *  @dev Stakes multiple tokens
     */
    function stakeTokens(bytes memory _signature, uint256[] memory _tokenIds, uint256 _nonce) 
        hasValidSignature(_signature, abi.encodePacked(msg.sender, _tokenIds, _nonce))
        public 
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(!addressToTokenIdToInitalized[msg.sender][_tokenIds[i]] || 
                    addressToTokenIdToNonce[msg.sender][_tokenIds[i]] < _nonce, "Nonce is not greater than previous nonce");
            
            addressToTokenIdToInitalized[msg.sender][_tokenIds[i]] = true;
            addressToTokenIdToNonce[msg.sender][_tokenIds[i]] = _nonce;
            stake(_tokenIds[i]);
        }
    }

    /**
     *  @dev Unstakes multiple tokens
     */
    function unstakeTokens(bytes memory _signature, uint256[] memory _tokenIds, uint256 _nonce) 
        hasValidSignature(_signature, abi.encodePacked(msg.sender, _tokenIds, _nonce))
        public 
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(!addressToTokenIdToInitalized[msg.sender][_tokenIds[i]] || 
                    addressToTokenIdToNonce[msg.sender][_tokenIds[i]] < _nonce, "Nonce is not greater than previous nonce");
            
            addressToTokenIdToInitalized[msg.sender][_tokenIds[i]] = true;
            addressToTokenIdToNonce[msg.sender][_tokenIds[i]] = _nonce;
            unstake(_tokenIds[i]);
        }
    }

    /* owner functions */
   function _authorizeUpgrade(address) internal override onlyOwner {}

   function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
   {
        signatureVerifier = _signatureVerifier;
   }

}