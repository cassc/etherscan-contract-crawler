// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: @hammm.eth                  *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Blimpie/ERC721EnumerableB.sol';
import './Blimpie/Delegated.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract FLSxCatharsis is ERC721EnumerableB, Delegated, PaymentSplitter {
    using Strings for uint;
 
    uint public MAX_SUPPLY  = 888;
    uint public MAX_ORDER  = 40;
    uint[] private PRICES = [0.07 ether, 0.08 ether, 0.07 ether, 0.08 ether];

    bool public _paused = false;
        
    string private _baseTokenURI = 'https://gateway.pinata.cloud/ipfs/QmPb7UJzvwPiDPh3V9ZqQKnV4i4wDNiQsLhcfGBBSqyQLk/';
    string private _tokenURISuffix = '.json';

    mapping(uint => uint) private tokenTypeMap;
    
    address withdraw1 = 0x172c418b3bDA2Ad1226287376051f5749567d568;
    address withdraw2 = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;
    address withdraw3 = 0xE75cF2B04B21262d64A262DB4FE650b0bc85D17E;

    address[] addressList = [withdraw1, withdraw2, withdraw3];
    uint[] shareList = [80, 10, 10];

    constructor() 
        ERC721B( "Fame Lady Squad X Catharsis", "FLSxC", 0 )
        PaymentSplitter(addressList, shareList) {
    }

    //external
    function burn(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "Only token owner allowed to burn");
        _burn(tokenId);
    }

    fallback() external payable {}

    //onlyDelegates
    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function togglePaused () external onlyDelegates {
        _paused = !_paused;
    }

    function setPrices ( uint[] calldata _newPrices ) external onlyDelegates {
        require( _newPrices.length == 4, "Invalid input array");
        PRICES = _newPrices;
    }

    function setMaxSupply ( uint _newSupply ) external onlyDelegates { 
        require( _newSupply < totalSupply (), "New Supply less than existing supply" );
        MAX_SUPPLY = _newSupply;
    }

    function setMaxOrder ( uint _newMaxOrder ) external onlyDelegates { 
        MAX_ORDER = _newMaxOrder;
    }

    function mint( uint[] calldata quantity ) external payable {
        require( quantity.length == 4, "Invalid input array" );
        require( !_paused, "Sale is currently paused");
        
        uint cost = 0;
        uint quantitySent = 0;
        for ( uint i = 0; i < PRICES.length; i++ ){
            cost += PRICES[i] * quantity[i];
            quantitySent += quantity[i];
        }

        require( msg.value >= cost, "Ether sent is not correct" );
        require( quantitySent <= MAX_ORDER,         "Order exceeds max order size" );
        uint supply = totalSupply();
        require( supply + quantitySent <= MAX_SUPPLY, "Mint/order exceeds supply" );
        
        // Cycle through token types, then # per token
        for ( uint i = 0; i < quantity.length; i++ ) {
            for (uint j; j < quantity[i]; j++){
                tokenTypeMap[supply] = i;
                _safeMint( msg.sender, supply++ );
            }
        }
    }

    function airdrop( address recipient, uint[] calldata quantity ) public onlyDelegates {
        require( quantity.length == 4, "Invalid input array" );

        uint quantitySent = 0;
        for ( uint i = 0; i < quantity.length; i++ ){
            quantitySent += quantity[i];
        }
        uint supply = totalSupply();
        require( supply + quantitySent <= MAX_SUPPLY, "Mint/order exceeds supply" );
        
        // Cycle through token types, then # per token
        for ( uint i = 0; i < quantity.length; i++ ) {
            for (uint j; j < quantity[i]; j++){
                tokenTypeMap[supply] = i;
                _safeMint( recipient, supply++ );
            }
        }
    }

    function tokenURI(uint tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenTypeMap[tokenId].toString(), _tokenURISuffix));
    }

    function getTokensByOwner(address owner) external view returns(uint256[] memory) {
        return _walletOfOwner(owner);
    }

    function _walletOfOwner(address owner) private view returns(uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[] (balance);
        for(uint256 i; i < balance; i++){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
}