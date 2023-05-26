// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

                   ██ 
     ██████       ██
    ██    ██       ██
    ██    ██ █████ 
    ██    ██       
     ██████


     ██████  ███    ██                         
    ██    ██ ████   ██                         
    ██    ██ ██ ██  ██                         
    ██    ██ ██  ██ ██                         
     ██████  ██   ████                         
                                            
                                            
     ██████ ██   ██  █████  ██ ███    ██       
    ██      ██   ██ ██   ██ ██ ████   ██       
    ██      ███████ ███████ ██ ██ ██  ██       
    ██      ██   ██ ██   ██ ██ ██  ██ ██       
     ██████ ██   ██ ██   ██ ██ ██   ████       
                                            
                                            
    ███    ███ ███████ ███████ ██████  ███████ 
    ████  ████ ██      ██      ██   ██ ██      
    ██ ████ ██ █████   █████   ██████  ███████ 
    ██  ██  ██ ██      ██      ██   ██      ██ 
    ██      ██ ██      ███████ ██   ██ ███████

    (phase 1)
    
    vision: @DadMod_xyz & @galtoshi
    art: @thompsonNFT
    devs: @JofaMcBender & 0xSomeGuy

    with the support of:
    sartoshi: 0xF95752fD023fD8802Abdd9cbe8e9965F623F8A84
    mfer community: 0x79FCDEF22feeD20eDDacbB2587640e45491b757f

*/


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


error MintPriceAintRightMfer();
error NoCanDoContractIsLocked();
error DefinitelyCantMintThatMany();
error WhoaMferPublicMintNotActive();
error ContractsCantMintAtThisTime();
error SorryCouldntWithdrawYourFundsDude();
error YouCanOnlyMintOneForTheFirstSixtyNineMinutes();
error YouAlreadyMintedOneDuringTheFirstSixtyNineMinutes();


contract MferLayerPass is ERC721A, Ownable, ReentrancyGuard
{
    constructor() ERC721A("onchainmfers", "SEED")
    {
        JeffFromAccounting = msg.sender;
        // nothing else to see here folks 👇
    }
    
    // collection size for mfer layers - 112 total tokens (not including 21 1/1s)
    uint256 public constant CollectionSize = 112;
    // sha1 hash of text file that maps index to trait name at time of deployment
    string public constant ProvedHash = "e8bb5ef800ab6b73a4d9bcfac58dbcda06155678";
    // mint cost
    uint256 public MintPrice = .69 ether;
    // base uri for token data
    string public BaseURI;
    // boolean for mint active status
    bool public PublicMintActive;
    // time to begin 69 minute countdown
    uint256 public MaxMintStartTime;
    // contract lock
    bool public ContractLocked;

    // update base uri
    function updateBaseURI(string memory _newBaseURI) external onlyOwner
    {
        if(ContractLocked) revert NoCanDoContractIsLocked();
        BaseURI = _newBaseURI;
    }
    
    // get base uri
    function _baseURI() internal view override returns(string memory)
    {
        return BaseURI;
    }

    // token uri
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        if(!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    // toggle mint status
    function toggleMint() external onlyOwner
    {
        if(ContractLocked) revert NoCanDoContractIsLocked();
        PublicMintActive =!PublicMintActive;
    }

    // open mint and start 69 minute timer
    function launchPublicMint() external onlyOwner
    {
        if(ContractLocked) revert NoCanDoContractIsLocked();
        PublicMintActive = true;
        MaxMintStartTime = block.timestamp;
    }

    // mint layer function
    function mintLayer(uint256 _quantity) external payable nonReentrant
    {
        // check if public mint is open
        if(!PublicMintActive) revert WhoaMferPublicMintNotActive();

        // check if quantity can be minted (tokens start at 0)
        if(_totalMinted() + _quantity > CollectionSize) revert DefinitelyCantMintThatMany();

        // check if max mint active
        if(block.timestamp - MaxMintStartTime < 4140)
        {
            // dont let contracts mint for the first 69 minutes
            if(msg.sender != tx.origin) revert ContractsCantMintAtThisTime();

            // check if quantity is 1
            if(_quantity > 1) revert YouCanOnlyMintOneForTheFirstSixtyNineMinutes();

            // check if address has minted already
            if(_numberMinted(msg.sender) > 0) revert YouAlreadyMintedOneDuringTheFirstSixtyNineMinutes();
        }

        // check if payment correct
        if(MintPrice*_quantity != msg.value) revert MintPriceAintRightMfer(); 

        // mint them thangs
        _mint(msg.sender, _quantity);
    }

    // lock contract
    function lockContract() external onlyOwner
    {
        ContractLocked = true;
    }

    // withdraw address (nod to NN)
    address private JeffFromAccounting;

    // update withdraw address
    function updateAccountant(address _newAddress) external onlyOwner
    {
        JeffFromAccounting = _newAddress;
    }

    // withdraw contract eth
    function moveThatGuap() public
    {
        (bool success, ) = JeffFromAccounting.call{value: address(this).balance}("");
        if(!success) revert SorryCouldntWithdrawYourFundsDude();
    }
}



////////////////////////////////////////////////
//  you are capable of more than you know ❤  //
///////////////////////////////////////////////