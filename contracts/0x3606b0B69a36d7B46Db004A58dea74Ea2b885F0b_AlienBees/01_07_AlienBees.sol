//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";    
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
contract AlienBees is ERC721A, Ownable{    
    uint256 public immutable MAX_SUPPLY;
    string public baseURI;
    uint public limitPerWallet;    
    uint32 public reservedNFTCount;   
    address public reservedWalletAddress; 
    uint256 public reservedSupply;
    mapping(address => bool) public whiteListedWallets;

    bool public publicRevealFlag;
    bool public whiteListedUsersRevealFlag;
    uint256 public total_supply ;
    constructor(address _reservedNFTaddress, uint32 _reservedNFTCount, address[] memory whiteListedAddress, uint256 _limitPerWallet, uint256 _MAX_SUPPLY, string memory _baseURI, string memory name_, string memory symbol_ ) ERC721A(name_, symbol_){
        MAX_SUPPLY      =   _MAX_SUPPLY;
        baseURI         =   _baseURI;
        limitPerWallet  =   _limitPerWallet;

        reservedWalletAddress = _reservedNFTaddress;
        reservedNFTCount = _reservedNFTCount;
        
        for(uint32 walletLoop =0; walletLoop < whiteListedAddress.length; walletLoop++){
            if(whiteListedWallets[whiteListedAddress[walletLoop]] != true ){
                whiteListedWallets[whiteListedAddress[walletLoop]] = true;
            }
        }
    }

    function setPublicRevealFlage(bool flag) external onlyOwner{
        publicRevealFlag = flag;
    }

    function setWhiteListedRevealFlage(bool flag) external onlyOwner{
        whiteListedUsersRevealFlag = flag;
    }

    function addNewWalletForWhiteList(address[] memory WhiteListAddress)external onlyOwner{  
        for(uint32 walletLoop =0; walletLoop < WhiteListAddress.length; walletLoop++){
            if(whiteListedWallets[WhiteListAddress[walletLoop]] != true ){
                whiteListedWallets[WhiteListAddress[walletLoop]] = true;
            }
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI =  _baseURI;
    }

    function updateWalletLimit(uint256 newLimit) external onlyOwner {
        limitPerWallet = newLimit;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintBee(uint256 quantity) external {
        require( (quantity + total_supply + reservedNFTCount) <= MAX_SUPPLY, "All NFTs are already minted");
        require(whiteListedWallets[msg.sender] == true && whiteListedUsersRevealFlag == true || publicRevealFlag == true ,"You can not mint because of admin permissions!");
        require( (_numberMinted(msg.sender) + quantity) <= limitPerWallet,"You have reached the maximum limit of minting");
        _safeMint(msg.sender, quantity);
        total_supply += quantity;
    }
    function mintReserved(uint256 quantity) external {
        require(reservedWalletAddress == msg.sender, "You can not call this Function");
        require( (quantity + total_supply) <= MAX_SUPPLY, "All NFTs are already minted");
        require( (reservedSupply + quantity) <= reservedNFTCount,"You have reached the maximum limit of minting!");    
        _safeMint(msg.sender, quantity);
        total_supply += quantity;
        reservedSupply +=quantity;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "ERC721AMetadata: URI query for nonexistent token" );
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId),".json"));
    }
  }