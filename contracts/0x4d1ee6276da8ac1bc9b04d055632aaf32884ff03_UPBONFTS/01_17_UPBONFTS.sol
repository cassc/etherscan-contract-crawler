// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UPBONFTS is 
    ERC721URIStorage,
    IERC721Receiver,
    ReentrancyGuard,
    Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public constant _name = "UPBO DIAMOND NFTs";
    string public constant _symbol = "UPBO";
    uint8 public constant _decimals = 6;
    uint256 public constant ETH_TO_WEI = 10000000000000000;
    string public constant TOKEN_URI = "https://bafybeig7akqa565sdqy4qtbxjftsxx2ahfea6xit243nrndpkjblqlz7iq.ipfs.w3s.link/metadata.json";
    address public UPBO_TOKEN_SMARTCONTRACT_ADDRESS = 0x95EBe18229dd387a1700C15e6D43ED8C239E6503;
    IERC20 public UPBO_TOKEN;
    address public TREASURY_WALLET = 0x3FfC9313789CE24AB4C4190DE8145af4b9Ad58ca;

    //a mapping to determine which contract has access to write data to this contract
    //used in the modifier below
    mapping(address => bool) accessAllowed;

    //initialize the token address
    constructor() ERC721(_name, _symbol) {
        accessAllowed[msg.sender] = true;
        _tokenIds.increment(); 
        UPBO_TOKEN = IERC20(UPBO_TOKEN_SMARTCONTRACT_ADDRESS);
    }
    //function modifier checks to see if an address has permission to update data
    //bool has to be true
    modifier isAllowed() {
        require(accessAllowed[msg.sender] == true);
        _;
    }

    //mintable flag
    bool MINTABLE_FLAG = true; 

    //max mint NFT number
    uint256 NFTS_LIMIT = 5000;

    function currentMintedItem() public view returns (uint256) {
        return _tokenIds.current();
    }
    function configUpBoToken(address tokenAddress) public onlyOwner returns (bool){
        UPBO_TOKEN_SMARTCONTRACT_ADDRESS = tokenAddress;
        return true;
    }
    function configMintFlag(bool status) public onlyOwner returns (bool){
        MINTABLE_FLAG = status;
        return MINTABLE_FLAG;
    }
    function configTreasuryWallet(address treasuryAddress) public onlyOwner returns (bool) {
        TREASURY_WALLET = treasuryAddress;
        return true;
    }
    function nftPrice() public view returns (uint256 price){
        /** 0 - 300 => 0.05 ETH
         *  301 - 2200 => 0.1 ETH
         *  2201 - 5000 => 0.15 ETH
         */
        uint256 firstMilestone = 300;
        uint256 secondMilestone = 2200;
        uint256 thirdMilestone = 5000;
        uint256 pricePerETH = 1;
        if(_tokenIds.current() < firstMilestone){
            pricePerETH = 5;
        }else if(_tokenIds.current() >= firstMilestone && _tokenIds.current() < secondMilestone){
            pricePerETH = 10;
        }else if(_tokenIds.current() >= secondMilestone && _tokenIds.current() < thirdMilestone){
            pricePerETH = 15;
        }else{
            pricePerETH = 100;
        }
        return pricePerETH * ETH_TO_WEI;
    }

    function getmintableFlag() public view returns (bool status){
        return MINTABLE_FLAG;
    }

    //set an address to the accessAllowed map and set bool to true
    //uses the isAllowed function modifier to determine if user can change data
    //this function controls which addresses can write data to the contract
    //if you update the UserContract you would add the new address here
    function allowAccess(address _address) public onlyOwner {
        accessAllowed[_address] = true;
    }

    //set an address to the accessAllowed map and set bool to false
    //uses the isAllowed function modifier to determine if user can change data
    //this function controls which addresses need to have thier write access removed from the contract
    //if you update the UserContract you would set the old contract address to false
    function denyAccess(address _address) public onlyOwner {
        accessAllowed[_address] = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function startToMintNFTs() public payable returns (uint256 itemID){
        require(MINTABLE_FLAG, "Minting flag is disable");
        require(_tokenIds.current() + 1 <=  NFTS_LIMIT, "Reached the max supply!");
        //require the token balance
        uint256 subtotal = nftPrice();
        require(msg.value == subtotal, "Invalid amount send!");
        //send to the liquid address
        payable(TREASURY_WALLET).transfer(subtotal);
        string memory box_uri = TOKEN_URI;
        return mintNFT(msg.sender, box_uri);
        
    }
    function mintNFT(address recipient, string memory tokenURI) internal returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}