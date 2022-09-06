// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PLZ is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAXSUPPLY = 3210;
    address public mainAddress = 0xd854EB0555BAC34cc92E979A77d08906FbFa6c6e;
    string public baseURI;
    mapping(address => uint256) public addressCheck;
    bool public mintControl=false;
    bool public freeMintControl=false;
    constructor(
        string memory _initBaseURI
    ) ERC721("PLZ", "PLZ") {
        setBaseURI(_initBaseURI);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return 3210;
    }


    function freeMint(uint256 ammount)
    public
    payable
    nonReentrant
    {
        uint256 supply = totalSupply();
        require(freeMintControl, "PLZ: Free sale is not started yet");
        require(supply + ammount <= 1000, "PLZ: Mint too large!");
        addressCheck[msg.sender] += 1;
          for (uint256 i = 0; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    function Mint(uint256 ammount) public payable nonReentrant {
        uint256 price = 0.0099 ether;
        uint256 supply = totalSupply();
        require(mintControl, "PLZ: Mint is not started yet");
        require(msg.value >= price * ammount, "PLZ: Insuficient funds");
        require(ammount <= 20, "PLZ: You can only mint up to 20 token at once!");
        require(supply + ammount <= publicSaleLimit(), "PLZ: Mint too large!");
        addressCheck[msg.sender] += ammount;
        for (uint256 i = 0; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }


    // Before All.

    function setUpMint(bool newbool) external onlyOwner {
        mintControl = newbool;
    }
     function setUpFreeMint(bool newbool) external onlyOwner {
        freeMintControl = newbool;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
  
     function withdrawAll() public payable onlyOwner {
        uint256 mainadress_balance = address(this).balance;
        require(payable(mainAddress).send(mainadress_balance));
    }
    function changeWallet(address _newwalladdress) external onlyOwner {
        mainAddress = _newwalladdress;
    }

    // FACTORY
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}