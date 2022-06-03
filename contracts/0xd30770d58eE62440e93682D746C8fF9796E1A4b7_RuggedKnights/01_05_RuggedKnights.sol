// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';



pragma solidity ^0.8.7;


contract RuggedKnights is Ownable, ERC721A {
    uint256 public maxSupply   = 1969;
    bool    public saleIsActive  = false;
    uint256 public maxPerAddress     = 10;

    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("Rugged Knights", "RKnights") {
      
    }

    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

      function mint(uint256 _quantity) external payable mintCompliance() {
  
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


    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
  
}