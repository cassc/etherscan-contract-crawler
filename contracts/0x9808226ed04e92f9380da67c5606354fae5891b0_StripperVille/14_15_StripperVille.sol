// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Assets.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StripperVille is Assets, ERC721 {
    
    uint public stripperPrice = 0.095 ether;
    uint private _maxMint = 0;
    string public baseTokenURI = 'https://strippervillebackend.herokuapp.com/';
    
    constructor() ERC721("StripperVille", "SpV") {}
    
    modifier isMine(uint tokenId){
        require(_msgSender() == ownerOf(tokenId), "OWNERSHIP: sender is not the owner");
        _;
    }
    
    modifier canMint(uint qty){
        require((qty + strippersCount) <= stripperSupply, "SUPPLY: qty exceeds total suply");
        _;
    }
    
    function setStripperPrice(uint newPrice) external onlyAdmin {
        stripperPrice = newPrice;
        emit NewStripperPrice(_msgSender(), newPrice);
    }
    
    function setMaxMint(uint newMaxMint) external onlyAdmin {
        _maxMint = newMaxMint;
        emit NewMaxMint(_msgSender(), newMaxMint);
    }
    
    function buyStripper(uint qty) external payable canMint(qty) {
        require((msg.value == stripperPrice * qty),"BUY: wrong value");
        require((qty <= _maxMint), "MINT LIMIT: cannot mint more than allowed");
        for(uint i=0; i < qty; i++) {
            _mintTo(_msgSender());
        }
        emit MintStripper(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty) external onlyOwner canMint(qty) {
        for(uint i=0; i < qty; i++) {
            _mintTo(to);
        }
        emit Giveaway(_msgSender(), to, qty);
    }
    
    function _mintTo(address to) internal {
        require(strippersCount < stripperSupply, "SUPPLY: qty exceeds total suply");
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, assets.length)));
        uint earn = ((rand % 31) + 70)  * (10 ** 18);
        uint tokenId = strippersCount + 1;
        assets.push(Asset(tokenId, STRIPPER, earn, 0, block.timestamp, "", true));
        _safeMint(to, tokenId);
        strippersCount++;
    }
    
    function createClub(string calldata clubName) external onlyAdmin {
        uint tokenId = clubsCount + 1000000;
        assets.push(Asset(tokenId, CLUB, 0, 0, block.timestamp, clubName, true));
        _safeMint(owner(), tokenId);
        clubsCount++;
        emit MintClub(_msgSender(), clubName);
    }
    
    function closeClub(uint tokenId) external onlyAdmin {
        require(ownerOf(tokenId) == owner(), "Ownership: Cannot close this club");
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == CLUB, "CLUB: asset is not a club");
        assets[i].active = false;
        emit CloseClub(_msgSender(), tokenId);
    }
    
    function reopenClub(uint tokenId) external onlyAdmin {
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == CLUB, "CLUB: asset is not a club");
        assets[i].active = true;
        emit ReopenClub(_msgSender(), tokenId);
    }
    
    function setStripperName(uint tokenId, string calldata name) external isMine(tokenId) {
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == STRIPPER, "ASSET: Asset is not a stripper");
        require(COIN.balanceOf(_msgSender()) >= namePriceStripper, "COIN: Insuficient funds");
        COIN.buy(namePriceStripper);
        assets[i].name = name;
        emit NewAssetName(_msgSender(), tokenId, name);
    }
    
    function withdrawAsset(uint tokenId, uint amount) external onlyAdmin {
        require(tx.origin == ownerOf(tokenId),  "OWNERSHIP: sender is not the owner");
        (, uint i) = getAssetByTokenId(tokenId);
        assets[i].withdraw += amount;
    }
    
    function getAssetsByOwner(address owner) public view returns (Asset[] memory) {
        uint balance = balanceOf(owner);
        Asset[] memory assets_ = new Asset[](balance);
        uint j = 0;
        for(uint i = 0; i < assets.length; i++){
            if(ownerOf(assets[i].id) == owner){
                assets_[j] = assets[i];
                j++;
                if(balance == j){
                 break;
                }
            }
            i++;
        }
        return assets_;
    }
    
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
}