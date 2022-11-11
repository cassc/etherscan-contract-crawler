// SPDX-License-Identifier: UNLICENSED

//     ()_()         ()_()         ()_()     
//     (o o)         (o o)         (o o)      
// ooO--`o'--Ooo-ooO--`o'--Ooo-ooO--`o'--Ooo
//  __ _  __   ____  ____  ____  ____  __  
// (  / )/  \ / ___)(  __)(_  _)(_  _)/  \ 
//  )  ((  O )\___ \ ) _)   )(    )( (  O )
// (__\_)\__/ (____/(____) (__)  (__) \__/ 
//     ()_()         ()_()         ()_()    
//     (o o)         (o o)         (o o)    
// ooO--`o'--Ooo-ooO--`o'--Ooo-ooO--`o'--Ooo

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "solmate/src/tokens/ERC1155.sol";
import "solmate/src/utils/LibString.sol";
import "hardhat/console.sol";

contract KosettoWearables is ERC1155, Ownable {
    using ECDSA for bytes32;

    string public baseMetadataURI;
    mapping(string => uint256) public listingMintedAmount;

    event ShopMint(address minter, string listingId, uint256 tokenId, uint256 amount, uint256 price);

    constructor() ERC1155() {
    }

    function setURI(string memory baseMetadataURI_) public onlyOwner {
        baseMetadataURI = baseMetadataURI_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return strConcat(baseMetadataURI, LibString.toString(id));
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      string memory ab = new string(_ba.length + _bb.length);
      bytes memory bab = bytes(ab);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
      return string(bab);
    }

    function mint(string memory listingId, uint256 tokenId, uint256 amount, uint256 price, uint256 listingSupply, bytes memory signature) public payable {
        bytes32 hash = keccak256(abi.encodePacked(listingId, tokenId, amount, price, listingSupply));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        require(signer == owner(), "Not signed by owner");
        require(listingSupply >= listingMintedAmount[listingId] + amount , "Out of stock");
        require(msg.value >= price * amount, "Insufficient payment");
        listingMintedAmount[listingId] += amount;
        emit ShopMint(msg.sender, listingId, tokenId, amount, price);
        _mint(msg.sender, tokenId, amount, "");
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}