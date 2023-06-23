// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BigSmileClud is ERC721,Ownable {

  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 2799;
  uint256 public  MINT_PRICE = 4000000000000000;
  uint256 public  MINT_COUNT = 5;
  mapping(address => uint) use;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

    constructor() ERC721("ArbPunks", "ArbPunks") {
          baseTokenURI = "ipfs://bafybeifxbszcmkdp7cpct6zapez2soxztt5ldzjlxzt7crwzqp6qr3xsky/";
          currentTokenId._value = 500;
    }

    function airdrop(uint[] memory tokenIds,address recipient) public onlyOwner returns(uint[] memory){
        uint[] memory result = new uint[](tokenIds.length);
        for(uint i=0; i< tokenIds.length; i++){
            require(tokenIds[i] <= 500, "The airdrop token Id cannot be greater than 500");
        }
        for(uint i=0; i< tokenIds.length; i++){
            _safeMint(recipient, tokenIds[i]);
            result[i] = tokenIds[i];
        }
        return result;
    }


    function batchMint(uint256 amount) public payable returns(uint[] memory){
      uint mintCount = use[msg.sender] + amount;
      uint remainCount = MINT_COUNT-use[msg.sender];
      require(mintCount <= MINT_COUNT, string(abi.encodePacked("only ",Strings.toString(MINT_COUNT), " can be cast at most. You can also mint ", Strings.toString(remainCount))));
      uint256 tokenId = currentTokenId.current() + amount - 1;
      require(tokenId < TOTAL_SUPPLY, "Max supply reached"); 
      uint256 payMoney = 0;
      if(remainCount == 5){
           payMoney = MINT_PRICE * (amount -1);
      }else{
           payMoney = MINT_PRICE * amount;
      }
      require(msg.value >= payMoney, "Transaction value did not equal the mint price");
      uint[] memory result = new uint[](amount);
      for(uint i=0;i< amount;i++){
        uint256 newItemId = _mint();
        result[i] = newItemId;
      }
      use[msg.sender] = mintCount;

      return result;
    }

    function mint() public payable returns (uint256){
      require(use[msg.sender] < MINT_COUNT, string(abi.encodePacked("only ",Strings.toString(MINT_COUNT), " can be cast at most.")));
      if(use[msg.sender] >= 1){
          require(msg.value >= MINT_PRICE, "Transaction value did not equal the mint price");
      }
      uint256 tokenId = currentTokenId.current();
      require(tokenId < TOTAL_SUPPLY, "Max supply reached");
      uint256 newItemId = _mint();
      use[msg.sender] = use[msg.sender] + 1;
      return newItemId;
    }


    function _mint() private returns (uint256){
      currentTokenId.increment();
      uint256 newItemId = currentTokenId.current();
      _safeMint(msg.sender, newItemId);
      return newItemId;
    }


  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner{
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments() public onlyOwner virtual {
      address payee = owner();
      uint256 payment = address(this).balance;
      payable(payee).transfer(payment);
  }

  function setMintPrice(uint256 price) public onlyOwner{
    MINT_PRICE = price;
  }
}