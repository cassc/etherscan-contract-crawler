// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ArmorySigner} from "./utils/ArmorySigner.sol";

contract PassengersArmory is OwnableUpgradeable, ArmorySigner{

    mapping(address => bool) public isAssetAllowed;
    mapping(bytes => bool) public isSignatureUsed;
    
    address public designatedSigner;
    uint256 public signatureExpirationTime;
    
    function initialize(address designatedSigner_) public initializer {
        __Ownable_init();
        __Armoury_init();
        designatedSigner = designatedSigner_;
        signatureExpirationTime = 5 minutes;
    }
    
    /**
        * @notice This function is used to lock tokens using the Passengers interface
        * @dev In this function EIP712 signature verification method is used
        * @dev where, the struct params are
        * @dev uint8 actionType;
        * @dev uint64 nonce;
        * @dev uint256 encodedData;
        * @dev address userAddress;
        * @dev address assetAddress;
        * @dev In the encodedData, the array of tokenId is encode and passed.
        * @param tokenIds The tokenIds of the assets
        * @param gear The Gear signature struct
    */
    function lockTokens(uint256[] calldata tokenIds, Gear memory gear) external {
        require(getSigner(gear) == designatedSigner, "Error: Wrong Signer");
        require(gear.encodedData == encodeData(tokenIds), "Error: Invalid Token Ids");
        unchecked {
            require(uint256(gear.nonce) + signatureExpirationTime > block.timestamp, "Error: Expired Lock");
        }
        require(msg.sender == gear.userAddress, "Error: Invalid User Address");
        require(isAssetAllowed[gear.assetAddress], "Error: Asset not allowed");
        require(gear.actionType == 1, "Error: Invalid Action Type");
        require(isSignatureUsed[gear.signature] == false, "Error: Signature already used");
        isSignatureUsed[gear.signature] = true;
        for (uint256 i = 0; i < tokenIds.length;) {
            require(IERC721Upgradeable(gear.assetAddress).ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of this token");
            IERC721Upgradeable(gear.assetAddress).transferFrom(gear.userAddress, address(this), tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }
    
    /**
	    * @notice This function is used to unlock tokens using the Passengers interface
        * @dev In this function EIP712 signature verification method is used
        * @dev where, the struct params are
        * @dev uint8 actionType;
        * @dev uint64 nonce;
        * @dev uint256 encodedData;
        * @dev address userAddress;
        * @dev address assetAddress;
        * @dev In the encodedData, the array of tokenId is encode and passed.
        * @param tokenIds The tokenIds of the assets
        * @param gear The Gear signature struct
    */
    function unlockTokens(uint256[] calldata tokenIds, Gear memory gear) external {
        require(getSigner(gear) == designatedSigner, "Error: Wrong Signer");
        require(gear.encodedData == encodeData(tokenIds), "Error: Invalid Token Ids");
        unchecked{
            require(uint256(gear.nonce) + signatureExpirationTime > block.timestamp, "Error: Signature Expired");
        }
        require(msg.sender == gear.userAddress, "Error: Invalid User Address");
        require(gear.actionType == 2, "Error: Invalid Action Type");
        require(isSignatureUsed[gear.signature] == false, "Error: Signature already used");
        isSignatureUsed[gear.signature] = true;
        for (uint256 i = 0; i < tokenIds.length;) {
            IERC721Upgradeable(gear.assetAddress).transferFrom(address(this), gear.userAddress, tokenIds[i]);
            unchecked{
                i++;
            }
        }
    }
    
    /**
        * @notice This function is used to whitelist a new asset to interact with the contract
        * @param asset The address of the asset which will be whitelisted
    */
    function allowAssetToInteract(address asset) external onlyOwner {
        isAssetAllowed[asset] = true;
    }
    
    /**
        * @notice This function is used to set the designated signer
        * @notice for the EIP712 signature authentication
        * @param signer The address of the designated signer
    */
    function setDesignatedSigner(address signer) external onlyOwner {
        designatedSigner = signer;
    }
    
    /**
        * @notice This function is used by the owner of the contract to remove a token from the contract
        * @notice without using a signature
        * @param userAddress The address where the withdrawn tokens will be transferred
        * @param assetAddress The address of the asset which will be transferred
        * @param tokenIds The tokenIds of the assets
    */
    function forceUnlockToken(
        address userAddress,
        address assetAddress,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        uint256 length = tokenIds.length;
        for (uint256 i=0; i< length; i++) {
            IERC721Upgradeable(assetAddress).transferFrom(address (this), userAddress, tokenIds[i]);
        }
    }
    
    /**
        * @notice This function is used to set the signature expiration time
        * @param timeInSecond The time in seconds after which the signature will be expired
    */
    function setSignatureExpirationTime(uint256 timeInSecond) external onlyOwner {
        signatureExpirationTime = timeInSecond;
    }
    
    /**
        * @notice This function is used to encode the array of tokenIds
        * @param tokenIds The tokenIds which will be encoded
    */
    function encodeData(uint256[] memory tokenIds) public pure returns(uint256) {
        return uint256(keccak256(abi.encode(tokenIds)));
    }
    
    /**
        * @notice This function returns whether the signature is used or not
        * @param signature The signature which will be checked
    */
    function isSignatureUsed_(bytes memory signature) public view returns(bool){
        return isSignatureUsed[signature];
    }
    
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `safeTransfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}