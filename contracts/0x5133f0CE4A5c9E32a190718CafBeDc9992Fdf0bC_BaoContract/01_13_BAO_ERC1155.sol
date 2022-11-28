// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract BaoContract is ERC1155, Ownable,ReentrancyGuard {
  
     //To concatenate the URL of an NFT
    using Strings for uint256;

    //To check the addresses in the whitelist
    bytes32 private mR;   

    //name of the collection
    //string public name = "KPK Relics"; 
    string public name = "Bao"; 

    uint256 public numberTokenSold;

    //Is the contract paused ?
    bool public paused = false;

    mapping(address => uint256) public nftsPerWallet;
    mapping(address => uint256) public nftsBurnPerWallet;
        

    constructor() ERC1155("https://kopokostudio.s3.eu-west-3.amazonaws.com/BAO/metadata/{id}.json") {

        transferOwnership(msg.sender);
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://kopokostudio.s3.eu-west-3.amazonaws.com/BAO/metadata/",
                Strings.toString(_tokenid),".json"
            )
        );
    }

    /**
    * @notice Edit the Merkle Root 
    *
    * @param _newMerkleRoot The new Merkle Root
    **/
    function changeMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
    }

    /** 
    * @notice Set pause to true or false
    *
    * @param _paused True or false if you want the contract to be paused or not
    **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

     /**
    * @notice Allows to mint one NFT if whitelisted
    *
    * 
    * @param _proof The Merkle Proof
    * @param _amount The ammount of NFTs the user wants to mint
    * @param maxAmount The max NFT the user can mint
    **/
    function mintBAO(bytes32[] calldata _proof, uint256 _amount, uint256 maxAmount) external payable nonReentrant {
        

        require(!paused, "Break time...");
        require(nftsPerWallet[msg.sender] + _amount <= maxAmount, "You can't mint anymore");
        //Is this user on the whitelist ?
        require(isWhiteListed(msg.sender, _proof), "You are not on the whitelist");

        //Mint the user NFT
        _mint(msg.sender, 1, _amount, "");

        //Increment the number of NFTs this user minted
        nftsPerWallet[msg.sender] += _amount;
        

    }


    /**
    * @notice Allows to burn one NFT to an address
    *
    * @param tokenID The id of the token
    * @param amount The amount to burn
    **/
    function burn(uint256 tokenID, uint256 amount) external {
        require(!paused,"You can't burn yet...");
        _burn(msg.sender, tokenID, amount);
        nftsBurnPerWallet[msg.sender] += amount;
       
    }

    /**
    * @notice Allows to gift one NFT to an address
    *
    * @param _account The account of the happy new owner of one NFT
    **/
    function gift(address _account) external onlyOwner {
       
        //Mint the user NFT
        _mint(_account, 1, 1, "");

        //Increment the number of NFTs this user minted
        nftsPerWallet[_account] += 1;
        numberTokenSold += 1;

    }

    
    /**
    * @notice Return true or false if the account is whitelisted or not
    *
    * @param account The account of the user
    * @param proof The Merkle Proof
    *
    * @return true or false if the account is whitelisted or not
    **/
    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
           
        return _verify(_leaf(account),proof);
    }

    /**
    * @notice Return the account hashed
    *
    * @param account The account to hash
    *
    * @return The account hashed
    **/
    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /** 
    * @notice Returns true if a leaf can be proved to be a part of a Merkle tree defined by root
    *
    * @param leaf The leaf
    * @param proof The Merkle Proof
    *
    * @return True if a leaf can be provded to be a part of a Merkle tree defined by root
    **/
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, mR, leaf);
    }


}