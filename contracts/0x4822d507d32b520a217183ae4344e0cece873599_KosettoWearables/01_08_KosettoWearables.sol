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
    mapping(bytes => bool) public signatureUsed;

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

    function mint(uint256 tokenId, uint256 amount, address to, uint256 nonce, bytes memory signature) public {
        bytes32 hash = keccak256(abi.encodePacked(tokenId, amount, to, nonce));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        require(signer == owner(), "Not signed by owner");
        require(!signatureUsed[signature] , "Signature already used");
        signatureUsed[signature] = true;
        _mint(to, tokenId, amount, "");
    }

    function mint(uint256 tokenId, uint256 amount, address to) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}