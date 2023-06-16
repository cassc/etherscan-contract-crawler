// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol";


contract Slumz is ERC721A, ERC2981, Ownable {
   
    

    using Strings for uint256;
    uint256 public maxSupply = 4001;
    uint256 public maxFreeAmount = 1000;
    uint256 public maxFreePerWallet = 3;
    uint256 public price = 0.0015 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerWallet = 40;
    bool public mintEnabled = false;
    string public baseURI;

 constructor(uint96 _royaltyFeesInBips, 
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name,_symbol) {
        setBaseURI(_initBaseURI);
        setRoyaltyInfo(msg.sender, _royaltyFeesInBips);
     
    }

function supportsInterface(
    bytes4 interfaceId
) public view virtual override(ERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
}
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }


  function  SlumDrop(uint256 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint256 totalSupply = uint256(totalSupply());
     uint totalAmount =   _amountPerAddress * addresses.length;
    require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
        }

     delete _amountPerAddress;
     delete totalSupply;
  }
        function _startTokenId() internal pure override returns (uint256) {
         return 1;
        }
    function  publicMint(uint256 quantity) external payable  {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
        uint256 cost = price;
        uint256 _maxPerWallet = maxPerWallet;
        

        if (
            totalSupply() < maxFreeAmount &&
            _numberMinted(msg.sender) == 0 &&
            quantity <= maxFreePerWallet
        ) {
            cost = 0;
            _maxPerWallet = maxFreePerWallet;
        }

        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );

        uint256 needPayCount = quantity;
        if (_numberMinted(msg.sender) == 0) {
            needPayCount = quantity - 1;
        }
        require(
            msg.value >= needPayCount * cost,
            "Please send the exact amount."
        );
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}