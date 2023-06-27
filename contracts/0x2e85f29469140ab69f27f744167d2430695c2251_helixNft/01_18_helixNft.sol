// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

//on Goerli at: 0x345ae50FF5Ef912aFccf5171a986Fb0a5e5705E3
//on Mainet at: 0x2E85F29469140Ab69f27F744167d2430695C2251



import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract helixNft is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public totNft;    //_tokenIds;

    address public wtfManAddr;//=ownerOf(wtfManager);             //set var for managers address
    address public wtfManAddr1;//=ownerOf(wtfManager1);
    address public wtfManAddr2;//=ownerOf(wtfManager2);


    constructor() ERC721("helixNft", "HLX") { 
    
    }

    //mint func for setting up beginer nft's
    function ownerMint(string memory tokenURI) external onlyOwner {
        totNft.increment();

        uint256 newItemId = totNft.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        //totNft = newItemId; //update total number of NFTs for this contract

        //set nftStat[newItemId]. struct items

    }

    function setWtfMngr(uint256 _mngrId, address _addr) external onlyOwner{
        if(_mngrId==0){
            wtfManAddr=_addr;
        }
        if(_mngrId==1){
            wtfManAddr1=_addr;
        }
        if(_mngrId==2){
            wtfManAddr2=_addr;
        }
    }
    
    //this is the mint function for managers only
    function mint(string memory tokenURI) public {
        //address wtfManAddr=ownerOf(wtfManager);             //set var for managers address
        //address wtfManAddr1=ownerOf(wtfManager1);
        //address wtfManAddr2=ownerOf(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        totNft.increment();

        uint256 newItemId = totNft.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);


        /*
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totNft = newItemId; //update total number of NFTs for this contract
        */
        //set nftStat[newItemId]. struct items

    }
    
}