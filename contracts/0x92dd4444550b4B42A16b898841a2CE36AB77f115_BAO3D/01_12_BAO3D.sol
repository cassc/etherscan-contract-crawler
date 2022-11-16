// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface ERC1155Partial {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract BAO3D is ERC1155, Ownable,ReentrancyGuard {
  
     //To concatenate the URL of an NFT
    using Strings for uint256;

    //To check the addresses in the whitelist
    bytes32 private mR;   

    //name of the collection
    //string public name = "KPK Relics"; 
    string public name = "Bao3D"; 

    uint256 public numberTokenSold = 0;
    uint256 public maxSupply = 1000;

    //Is the contract paused ?
    bool public paused = false;

    mapping(address => uint256) public nftsPerWallet;
    mapping(address => uint256) public nftsBurnPerWallet;
    
    //Genesis contract
    ERC1155Partial tokenContract;
    

    constructor() ERC1155("https://kopokostudio.s3.eu-west-3.amazonaws.com/BAO3D/metadata/{id}.json") {

        transferOwnership(msg.sender);
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://kopokostudio.s3.eu-west-3.amazonaws.com/BAO3D/metadata/",
                Strings.toString(_tokenid),".json"
            )
        );
    }


     /** 
    * @notice Set pause to true or false
    *
    * @param _tokenContract True or false if you want the contract to be paused or not
    **/
    function setBAOContract(ERC1155Partial _tokenContract) external onlyOwner {
         tokenContract = _tokenContract;
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
    * @param _tokenID The _tokenID of NFTs the user wants to mint
    * @param _amount The ammount of NFTs the user wants to mint
    **/
    function mintBAO(uint256 _tokenID, uint256 _amount) external payable nonReentrant {
        

        require(!paused, "Break time...");
        require(numberTokenSold + _amount <= maxSupply, "Too many.");
        require(tokenContract.balanceOf(msg.sender,1) > 0,"You don't own BAO NFT");
        require(_amount > 0,"You need to burn more than 0 BAO NFT");
        tokenContract.safeTransferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),_tokenID,_amount,"");
        //Mint the user NFT
        _mint(msg.sender, _tokenID, _amount, "");

        //Increment the number of NFTs this user minted
        nftsPerWallet[msg.sender] += _amount;
        numberTokenSold += _amount;

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
    * @param _tokenID The _tokenID of NFTs the user wants to mint
    * @param _amount The ammount of NFTs the user wants to mint
    **/
    function gift(address _account,uint256 _tokenID, uint256 _amount) external onlyOwner {
       
        //Mint the user NFT
        _mint(_account, _tokenID, _amount, "");

        //Increment the number of NFTs this user minted
        nftsPerWallet[_account] += _amount;
        numberTokenSold += _amount;
        

    }

    


}