// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';



pragma solidity ^0.8.7;


contract wtftown is Ownable, ERC721A {
    uint256 public maxSupply   = 3333;
    uint256 public maxPerAddress     = 3;
    bool public revealed = false;
    bool public isMetadataLocked = false;
    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("wtftown", "wtftown") {
               _safeMint(msg.sender, 33);

      
    }


      function mint(uint256 _quantity) external   {
  
        require(
            maxSupply >= totalSupply() + _quantity,
            "Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddress,
            "Exceeds max mints per address!"
        );

        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }




    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealed == false)
        {
            return "ipfs://QmWnMmT7JNzrTu6x68PnSWXjxW2kzPjJjxsZvuN6RLUMs7/reveal.json";
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
        function burnSupply(uint256 _amount) public onlyOwner {
        maxSupply -= _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }  
  
}