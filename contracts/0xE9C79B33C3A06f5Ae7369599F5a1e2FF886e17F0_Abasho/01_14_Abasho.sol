pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Abasho is ERC721 {
    using SafeMath for uint256;
    uint public constant MAX_ABASHOS = 250;

    constructor() ERC721("Abasho", "ABASHO") {
        _setBaseURI("https://ipfs.io/ipfs/QmReAPcCPH3u9sBNWLbsJWDyuVCNnFFtVGB3LNZeVw8JNr/");
    }
    
   function mintAbasho() public payable {
        require(totalSupply() < MAX_ABASHOS, "Sale has already ended");
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }
}