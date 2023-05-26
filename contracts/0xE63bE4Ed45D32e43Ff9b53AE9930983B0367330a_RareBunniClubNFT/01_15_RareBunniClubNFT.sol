// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//Join the RareBunniClub 5500k RareBunnies!

//Twitter twitter.com/rarebunni
//Discord https://discord.gg/js6ZDpMguS
//Web rarebunniclub.com

contract RareBunniClubNFT is ERC721, Ownable, ERC721Enumerable, Pausable  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RareBunniClub", "RareBunni") {}

    // Maximum limit of tokens that can ever exist
    uint16 constant MAX_SUPPLY = 5501; //its 5500 
    uint16 constant MAX_MINT = 21; //its 20

    // Price of each token converted to WEI
    uint256 public price = 0.02 ether;

    string public baseTokenURI = "";

    // Starting and stopping sale and presale
    bool public presaleActive = false;
    bool public saleActive = false;

    // Team addresses
    address public teamW1;
    address public CommunityW;

    // List of addresses that have a number of reserved tokens for presale
    mapping (address => uint16) public presaleAddresses;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Exclusive Presale Bunni Mint
    function mintPresaleToken(uint16 _amount) public payable {
        require( presaleActive,                  "Presale is not active" );
        uint16 reservedAmt = presaleAddresses[msg.sender];
        require( reservedAmt > 0,                "No tokens reserved for your address" );
        require( _amount < reservedAmt,         "Cannot mint more than reserved" );
        uint16 supply = uint16(totalSupply());
        require( supply + _amount < MAX_SUPPLY, "Cannot mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        presaleAddresses[msg.sender] = reservedAmt - _amount;
        for(uint16 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // Mint a Bunni
    function mintSaleToken(uint16 _amount) public payable {
        require( saleActive,                     "Sale is not active" );
        require( _amount < MAX_MINT,    "You can only Mint 20 tokens at once" );
        uint16 supply = uint16(totalSupply());
        require( supply + _amount < MAX_SUPPLY, "Cannot mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        for(uint16 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
////////ONLY OWNER BELOW SOZ
    
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    // Free Bunnies!
    function giveAway(address _to, uint16 _amount) public onlyOwner() {
        require( _amount < MAX_MINT,    "You can only Mint 20 tokens at once" );
        uint16 supply = uint16(totalSupply());
        require( supply + _amount < MAX_SUPPLY, "Cannot mint more than max supply" );
        
        for(uint16 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
    }

    // Start and stop presale
    function setPresaleActive(bool _val) public onlyOwner {
        presaleActive = _val;
    }

    // Start and stop sale
    function setSaleActive(bool _val) public onlyOwner {
        saleActive = _val;
    }

    // Set new baseURI
    function setBaseURI(string memory _baseURIVar) public onlyOwner {
        baseTokenURI = _baseURIVar;
    }

    // Set team addresses
    function setTeamAddresses(address[] memory _a) public onlyOwner {
        teamW1 = _a[0];
        CommunityW = _a[1];
    }

    //Priced in WEI. This is just incase ETH goes TO DAMN HIGH, and we need to lower the mint price
    function updateMintPrice(uint256 _newPrice) external onlyOwner() {
        price = _newPrice;
    }
    
    //Set reserved presale spots
    function setPresaleReservedAddresses(address[] memory _a, uint16[] memory _amount) public onlyOwner {
        uint16 length = uint16(_a.length);
        for(uint16 i; i < length; i++){
            presaleAddresses[_a[i]] = _amount[i];
        }
    }

    //IN WEI Monies go back into development, Community Wallet Visit our Discord https://discord.gg/js6ZDpMguS RareBunniClub!
    function payTheBunniTeam(uint256 _amount) public payable onlyOwner {
        uint256 percent = _amount / 100;
        require(payable(teamW1).send(percent * 84));
        require(payable(CommunityW).send(percent * 16));
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
}