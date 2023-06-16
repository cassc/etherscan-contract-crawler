//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Mintpass.sol";


contract Satoshis is ERC721URIStorage, Ownable, Pausable, ERC721Enumerable, Mintpass {

    using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;


    //Ensure unique tokenURIs are used
    mapping (string => bool) private _mintedTokenUris;


    //Collection limits and counters
	uint256 public tokensLimit;
	uint256 public tokensMinted;
	uint256 public tokensAvailable;

    uint256 public mintPassTokensLimit;
    uint256 public mintPassTokensMinted;

    uint256 public wlOneTokensLimit;
    uint256 public wlOneTokensMinted;    

    //Mint stages
    bool public wlOneStatus;
    bool public mintPassStatus;
    bool public publicMintStatus;
    bool public gloablMintStatus; //allows for minting to happen even if the contratc is paused & vice versa


    //Destination addresses
	address payable teamOne;
    address payable teamTwo;


    //Load mint passes
    mapping(uint256 => address) private _mintPasses;


    //Mint prices
    uint256 public publicMintPrice;
    uint256 public wlMintPrice;
    
    //whooray, new Satoshi is minted
	event UpdateTokenCounts(uint256 tokensMintedNew,uint256 tokensAvailableNew);


    //Contract constructor
	constructor(uint256 tokensLimitInit, uint256 wlOneTokensLimitInit, uint256 mintPassTokensLimitInit, address payable destAddOne, address payable destAddTwo) public ERC721("We Are Satoshis","W.A.S.") 
    {

		//Set global collection size & initial number of available tokens
        tokensLimit = tokensLimitInit;
		tokensAvailable = tokensLimitInit;
		tokensMinted = 0;

        //Set destination addresses
		teamOne = destAddOne;
        teamTwo = destAddTwo;

        //Set initial mint stages
        wlOneStatus = true;
        mintPassStatus = true;
        publicMintStatus = false;
        gloablMintStatus = true;

        //Set token availability per stage
        wlOneTokensLimit = wlOneTokensLimitInit;
        mintPassTokensLimit = mintPassTokensLimitInit;

        //Set counters for whitelists and mintpasses
        mintPassTokensMinted = 0;
        wlOneTokensMinted = 0;

        publicMintPrice = 80000000000000000;
        wlMintPrice = 60000000000000000;

	}




function masterMint(address to)
    internal
    virtual
    returns (uint256)
    {
        require(tokensAvailable >= 1,"All tokens have been minted");
        require(gloablMintStatus,"Minting is disabled");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);

        tokensMinted = newItemId;
        tokensAvailable = tokensLimit - newItemId;


        emit UpdateTokenCounts(tokensMinted,tokensAvailable);
        return newItemId;
    }


//Minting methods : Mint pass

function mintSingleMintPass (address to, uint256 mintPass)
    public
    virtual
    returns (uint256)
    {
        require(verifyMintPass(mintPass,to),"This mint pass was used already");
        require(mintPassStatus,"Mint pass minting is disabled");
        require(mintPassTokensMinted <= mintPassTokensLimit,"All Mint Pass tokens have already been minted");

        uint256 newTokenId = masterMint(to);
        mintPassTokensMinted++;
        invalidateMintPass(mintPass);

        return newTokenId;
    }



function multiMintPassMint(address to, uint256 quantity, uint[] memory mintPases)
    public
    virtual
    {
        require(quantity <= 10,"Can not mint that many tokens at once");
        uint256 i;
        for(i = 0; i < quantity; i++) {
            mintSingleMintPass(to, mintPases[i]);
        }
    }




//Minting methods : Whitelist

function wlOneMintToken(address to, uint256 quantity) 
	public 
	virtual 
	payable 
    {
        require(msg.value >= (wlMintPrice*quantity),"Not enough ETH sent");
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(wlOneStatus,"Whitelist one is not minting anymore");
        require(wlOneTokensMinted <= wlOneTokensLimit,"All whitelist #1 tokens have been minted");
        require(quantity <= 10,"Can not mint that many tokens at once");

        passOnEth(msg.value);

        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
            wlOneTokensMinted++;
        }
    }

//Minting methods : Public

function publicMintToken(address to, uint256 quantity) 
    public 
    virtual 
    payable 
    {
        require(msg.value >= (publicMintPrice*quantity),"Not enough ETH sent");
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(publicMintStatus,"The General Public Mint is not active at the moment");
        require(quantity <= 10,"Can not mint that many tokens at once");

        passOnEth(msg.value);

        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
        }
    }

//Honorary mint
function honoraryMint(address to, uint256 quantity) 
    public 
    virtual 
    onlyOwner
    {
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(quantity <= 10,"Can not mint that many tokens at once");
        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
        }
    }



/*
    General methods, utilities.
    Utilities are onlyOwner.
*/

//Update collection size
function setCollectionSize (uint256 newCollectionSize)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        require(newCollectionSize >= tokensMinted,"Cant set the collection size this low");
        tokensLimit = newCollectionSize;
        tokensAvailable = tokensLimit - tokensMinted;
        return tokensLimit;
    }

//Modify the limits for WL1, emergency use only
function setWlOneLimit (uint256 newWlOneLimit)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        wlOneTokensLimit = newWlOneLimit;
        return wlOneTokensLimit;
    }

//Modify public sale price
function setPublicSalePrice (uint256 newPublicPrice)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        publicMintPrice = newPublicPrice;
        return publicMintPrice;
    }


//Toggle global minting
function toggleGlobalMinting ()
    public
    onlyOwner
    virtual
    {
        gloablMintStatus = !gloablMintStatus;
    }

//Toggle Wl1 minting
function toggleWlOneMinting ()
    public
    onlyOwner
    virtual
    {
        wlOneStatus = !wlOneStatus;
    }

//Toggle Public minting
function togglePublicMinting ()
    public
    onlyOwner
    virtual
    {
        publicMintStatus = !publicMintStatus;
    }

//Toggle Mint Pass minting
function toggleMintPassMinting ()
    public
    onlyOwner
    virtual
    {
        mintPassStatus = !mintPassStatus;
    }


function pauseContract() public onlyOwner whenNotPaused 
{

	_pause();
}

function unPauseContract() public onlyOwner whenPaused 
{
	_unpause();
}

 function passOnEth(uint256 amount) public payable {
    uint singleAmount = amount/2;

    (bool sentToAddressOne, bytes memory dataToAddressOne) = teamOne.call{value: singleAmount}("");
    (bool sentToAddressTwo, bytes memory dataToAddressTwo) = teamTwo.call{value: singleAmount}("");


    require(sentToAddressOne, "Failed to send Ether to Team Address One");
    require(sentToAddressTwo, "Failed to send Ether to Team Address Two");

}


function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
) internal virtual override (ERC721,ERC721Enumerable)  {
    super._beforeTokenTransfer(from, to, tokenId);
    require(!paused(), "ERC721Pausable: token transfer while paused");

}


function _burn(uint256 tokenId) 
	internal 
	virtual 
	override (ERC721, ERC721URIStorage) 
{
    super._burn(tokenId);

}


function tokenURI(uint256 tokenId)
public 
view 
virtual 
override (ERC721, ERC721URIStorage)
	returns (string memory) 
	{

    return super.tokenURI(tokenId);
}

function _baseURI() 
internal 
view 
virtual 
override (ERC721) 
returns (string memory) 
{
    return "https://meta.wearesatoshis.com/";
}

function supportsInterface(bytes4 interfaceId) 
public 
view 
virtual 
override(ERC721, ERC721Enumerable) returns (bool) 
{
    return super.supportsInterface(interfaceId);
}

}