// 1024 Generative Designs From Our Concept Art
// Goes through 5 generations before landing on the isometric artstyle we have chosen utilzing the talent of @futureboy3lll
//      ___           ___            ___           ___           ___           ___         ___     
//     /\  \         /|  |          /\__\         /\__\         /\  \         /\  \       /\__\    
//     \:\  \       |:|  |         /:/ _/_       /:/  /        /::\  \       /::\  \     /:/ _/_   
//      \:\  \      |:|  |        /:/ /\  \     /:/  /        /:/\:\  \     /:/\:\__\   /:/ /\__\  
// _____\:\  \   __|:|__|       /:/ /::\  \   /:/  /  ___   /:/ /::\  \   /:/ /:/  /  /:/ /:/ _/_ 
// /::::::::\__\ /::::\__\_____ /:/_/:/\:\__\ /:/__/  /\__\ /:/_/:/\:\__\ /:/_/:/  /  /:/_/:/ /\__\
// \:\~~\~~\/__/ ~~~~\::::/___/ \:\/:/ /:/  / \:\  \ /:/  / \:\/:/  \/__/ \:\/:/  /   \:\/:/ /:/  /
//  \:\  \           |:|~~|      \::/ /:/  /   \:\  /:/  /   \::/__/       \::/__/     \::/_/:/  / 
//   \:\  \          |:|  |       \/_/:/  /     \:\/:/  /     \:\  \        \:\  \      \:\/:/  /  
//    \:\__\         |:|__|         /:/  /       \::/  /       \:\__\        \:\__\      \::/  /   
//     \/__/         |/__/          \/__/         \/__/         \/__/         \/__/       \/__/    
//      ___           ___           ___           ___           ___           ___                  
//     /\__\         /\  \         /\  \         /\__\         /\__\         /\  \                 
//    /:/  /        /::\  \        \:\  \       /:/  /        /:/ _/_       /::\  \       ___      
//   /:/  /        /:/\:\  \        \:\  \     /:/  /        /:/ /\__\     /:/\:\__\     /\__\     
//  /:/  /  ___   /:/  \:\  \   _____\:\  \   /:/  /  ___   /:/ /:/ _/_   /:/ /:/  /    /:/  /     
// /:/__/  /\__\ /:/__/ \:\__\ /::::::::\__\ /:/__/  /\__\ /:/_/:/ /\__\ /:/_/:/  /    /:/__/      
// \:\  \ /:/  / \:\  \ /:/  / \:\~~\~~\/__/ \:\  \ /:/  / \:\/:/ /:/  / \:\/:/  /    /::\  \      
//  \:\  /:/  /   \:\  /:/  /   \:\  \        \:\  /:/  /   \::/_/:/  /   \::/__/    /:/\:\  \     
//   \:\/:/  /     \:\/:/  /     \:\  \        \:\/:/  /     \:\/:/  /     \:\  \    \/__\:\  \    
//    \::/  /       \::/  /       \:\__\        \::/  /       \::/  /       \:\__\        \:\__\   
//     \/__/         \/__/         \/__/         \/__/         \/__/         \/__/         \/__/   
//      ___           ___                                                                          
//    /\  \         /\  \                                                                         
//    /::\  \       /::\  \         ___                                                            
//   /:/\:\  \     /:/\:\__\       /\__\                                                           
//  /:/ /::\  \   /:/ /:/  /      /:/  /                                                           
// /:/_/:/\:\__\ /:/_/:/__/___   /:/__/                                                            
// \:\/:/  \/__/ \:\/:::::/  /  /::\  \                                                            
//  \::/__/       \::/~~/~~~~  /:/\:\  \                                                           
//   \:\  \        \:\~~\      \/__\:\  \                                                          
//   \:\__\        \:\__\          \:\__\                                                         
//     \/__/         \/__/           \/__/        
// Studio - twitter.com/Augminted
// Artist - twitter.com/futureboy3lll
// Developer - twitter.com/ohdotss
// Game Twitter - twitter.com/n0xscape
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract n0xAlphaArt is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _price = 0.05 ether;
    bool public _paused = true;
    address public vault;

    constructor() ERC721("N0XSCAPE CONCEPT ART", "NSCA")  {
    }

    function mintTokens(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused, "Art Sale Is Paused" );
        require( num < 6, "You can only grab 5 token" );
        require( supply + num < 1024, "Exceeds maximum token supply" );
        require( msg.value >= _price * num, "Ether sent is below the price of mint" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    //Reserve 40 for friends and family.
    function reserve(uint256 _reservedArt) public onlyOwner() {
        uint256 supply = totalSupply();
        require(_paused, 'Cannot reserve art while sale is in process');
        uint256 index;
        for (index = 0; index < _reservedArt; index++) {
            _safeMint(owner(), supply + index);
        }
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner() {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }


    function pause(bool val) public onlyOwner() {
        _paused = val;
    }

   function setVault(address _newVaultAddress) public onlyOwner() {
        vault = _newVaultAddress;
    }

    function withdraw(uint256 _amount) public onlyOwner() {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(_amount));
    }

    function withdrawAll() public payable onlyOwner() {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(address(this).balance));
    }
}