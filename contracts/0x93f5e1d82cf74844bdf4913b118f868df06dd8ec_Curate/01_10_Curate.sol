// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev the same as @openzeppelin's ERC721 except
 *  _mint has been merged into a single _safeMint function
**/
import "./ERC721.sol";

contract Curate is ERC721 {

    string public baseURI;
    address public owner;
    uint16 private _totalSupply;
    bool public mintingActive = true;

    constructor() ERC721("Curate NFT", "XCUR") {
        owner = msg.sender;
    }

    function _baseURI() internal view override returns (string memory) {
      return baseURI;
    }

    function setBaseURI(string memory newURI) public {
        require(msg.sender == owner, "Not Owner");
        baseURI = newURI;
    }

    function totalSupply() public view returns (uint16){
        return _totalSupply;
    }

    function toggleMinting() external {
        require(msg.sender == owner, "Not Owner");
        mintingActive = !mintingActive;
    }

    function mintTo(uint256 tokenId, address to) public {
        require(msg.sender == owner, "Not Owner");
        require(mintingActive, "Minting not active");
        _safeMint(to, tokenId);
        _totalSupply++;
    }

    function batchMint(uint256[] memory tokens, address to) public {
        require(msg.sender == owner, "Not Owner");
        require(mintingActive, "Minting not active");
        for(uint16 i = 0; i < tokens.length; i++){
            _safeMint(to, tokens[i]);
            _totalSupply++;
        }
    }

}