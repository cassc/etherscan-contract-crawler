// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/** 
* ERC721 Non-Fungible Token which serves as a deed of ownership for 
* an exclusive, rare, trait dependent random rarity wearable item (PixelHat). 
*/
contract PixelHat is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    IERC20 pixlToken;

    uint256 public mintPriceInPixl;
    uint256 public totalSupply;
    string public baseURI;

    constructor(IERC20 pixlTokenAddress) ERC721("PixelHat", "PHAT") Ownable() {
        pixlToken = pixlTokenAddress;
        totalSupply = 10;
        mintPriceInPixl = 25000 * 1e18;
        // TODO - update to our specific ipfs project, not the base hash!!!
        //  NOTE: for now this is just sappy seals url lol. 
        // We can even delete this if we don't want to manually init, no big deal.
        baseURI = "https://ipfs.io/ipfs/QmXUUXRSAJeb4u8p4yKHmXN1iAKtAV7jwLHjw35TNm5jN7/";
    }

    // Client UI will have the user approve the ERC20 contract in order
    // to let PixelHat transfer PIXL tokens for minting.
    function mint() public returns (uint) {
        uint256 pixlBalance = pixlToken.balanceOf(msg.sender);
        require(pixlBalance >= mintPriceInPixl, "Insufficient funds: not enough PIXL");
        require(_tokenIds.current() < totalSupply, "Supply Exceeded: sold out");
        pixlToken.transferFrom(msg.sender, address(this), mintPriceInPixl);

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        return newItemId;
    }

    function amountMinted() public view returns (uint) {
        return _tokenIds.current();
    }

    function amountUnsold() public view returns (uint) {
        return totalSupply - _tokenIds.current();
    }


    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }


    /****** ADMIN FUNCTIONS *******/

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }


    function withdrawPixl(uint256 _amount) public onlyOwner {
        uint256 pixlBalance = pixlToken.balanceOf(address(this));
        require(pixlBalance >= _amount, "Insufficient funds: not enough PIXL");
        pixlToken.transfer(msg.sender, _amount);
    }

    function withdrawAllPixl() public onlyOwner {
        uint256 pixlBalance = pixlToken.balanceOf(address(this));
        require(pixlBalance > 0, "No PIXL within this contract");
        pixlToken.transfer(msg.sender, pixlBalance);
    }

    // Just in case anyone sends any random coins on accident ;)
    function withdrawErc20(address erc20Contract, uint256 _amount) public onlyOwner {
        uint256 erc20Balance = pixlToken.balanceOf(address(this));
        require(erc20Balance >= _amount, "Insufficient funds: not enough ERC20");
        IERC20(erc20Contract).transfer(msg.sender, _amount);
    }

    // Only use if adding more PixelHats to Pixelverse, followed by an extra push to IPFS
    function updateTotalSupply(uint256 _supply) public onlyOwner {
        totalSupply = _supply;
    }

    function updateMintPrice(uint256 _priceInPixl) public onlyOwner {
        mintPriceInPixl = _priceInPixl;
    }

}