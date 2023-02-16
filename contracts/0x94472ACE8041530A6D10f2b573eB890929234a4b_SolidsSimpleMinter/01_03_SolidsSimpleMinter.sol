pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface SI {
    function mint(address to) external returns (uint);
    function getTokenLimit() external view returns (uint256);
    function checkPool() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

contract SolidsSimpleMinter is Ownable{
  address public ERC721;
  address public artist;
  uint public price;
  uint public maxMint;

  constructor(address _erc721Address, address _artist, uint _amountInWei, uint _maxMint) {
        ERC721 = _erc721Address;
        artist = _artist;
        price = _amountInWei;
        maxMint = _maxMint;
    }

  function setAddresses (address _erc721Address, address _artist) external onlyOwner {
    ERC721 = _erc721Address;
    artist = _artist;
  }

  function setPrice (uint _amountInWei) external onlyOwner {
    price = _amountInWei;
  }

  function setMaxMint (uint _maxMint) external onlyOwner {
    uint alreadyMinted = SI(ERC721).totalSupply();
    require (_maxMint >= alreadyMinted, "Cannot set limit below already minted");
    maxMint = _maxMint;
  }

  function artistMint (uint _qty) external onlyOwner {
    SI solids = SI(ERC721);
    for (uint i = 0; i < _qty; i++) {
      solids.mint(msg.sender);
    }
  }

  function mint (uint _qty) external payable {
    require(msg.value == price*_qty, "Payment amount insufficient");
    
    SI solids = SI(ERC721);
    uint totalSupply = solids.totalSupply();
    
    require(totalSupply < maxMint, "Minted out");
    uint availableToMint = maxMint - totalSupply;
    require (_qty <= availableToMint, "Not enough available to mint");

    (bool sent, ) = artist.call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    for (uint i = 0; i < _qty; i++) {
      solids.mint(msg.sender);
    }

  }


}