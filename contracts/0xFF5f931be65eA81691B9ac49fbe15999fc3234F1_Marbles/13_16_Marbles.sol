// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StripperVille.sol";

contract Marbles is ERC721, Ownable { 
    
    string internal baseTokenURI = '';
    uint public totalSupply = 3000;
    uint public nonce = 0;
    
    StripperVille public NFT;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);
    
    mapping(uint => bool) public stripperMint;
    
    struct Asset {
        uint id;
        uint tokenType;
    }

    
    constructor(address nft) ERC721("StripperVille Marbles", "SMRB") {
        setStripperVilleAddress(nft);
    }
    
    function setStripperVilleAddress(address newAddress) public onlyOwner {
        NFT = StripperVille(newAddress);
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < nonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    function getMyAssets() external view returns(uint[] memory){
        return getAssetsByOwner(tx.origin);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function giveaway(address to, uint qty) external onlyOwner {
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(to, tokenId);
            nonce++;
        }
        emit Giveaway(to, qty);
    }
    
    function getStrippersByOwner(address owner) public view returns (Asset[] memory) {
        uint balance = NFT.balanceOf(owner);
        require(balance > 0, "NOT A STRIPPER HOLDER");
        Asset[] memory assets_ = new Asset[](balance);
        uint j = 0;
        for(uint i = 0; i < NFT.strippersCount(); i++){
            (uint tokenId,uint tokenType,,,,,) = NFT.assets(i);
            if(NFT.ownerOf(tokenId) == owner && tokenType == 0){
                assets_[j] = Asset(tokenId, tokenType);
                j++;
                if(balance == j){
                 break;
                }
            }
            i++;
        }
        return assets_;
    }
    
    function getStrippersCountByOwner(address owner) external view returns (uint) {
        Asset[] memory strippers = getStrippersByOwner(owner);
        return strippers.length;
    }
    
    function mint(uint[] memory ids) external {
        uint qty = 0;
        for(uint i=0; i < ids.length;i++){
            uint tokenId = ids[i];
            require(NFT.ownerOf(tokenId) == _msgSender(), "SENDER IS NOT OWNER");
            if(stripperMint[tokenId] != true){
                qty++;
                uint id = nonce;
                _safeMint(_msgSender(), id);
                nonce++;
                stripperMint[tokenId] = true;
            }
        }
        emit Mint(_msgSender(), qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}