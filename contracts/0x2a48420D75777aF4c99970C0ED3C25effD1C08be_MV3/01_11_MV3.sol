// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MV3 is ERC721A, Ownable {

  constructor(uint256 collectionSize_) ERC721A("MV3NFT", "MV3NFT") {
    collectionSize = collectionSize_;
  }
    
    uint64 public tier2Price;
    uint64 public tier3Price;
    uint64 public tier4Price;
    uint64 public tier5Price;
    uint256 collectionSize;
    string baseURI;
    mapping (uint32 => bool) counters;

    uint256[] savedList;

    //Auction properties
    uint256 public AUCTION_START_DATE;
    uint256 public AUCTION_START_PRICE = 1 ether;
    uint256 public AUCTION_END_PRICE = 0.70 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 180 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public AUCTION_DROP_PER_STEP;

    address private serverAddress;

    //Event

    function startEvent(uint256[] memory list) external onlyOwner {
      for (uint256 i = 0; i < list.length; i++) {
        uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (list.length - i);
        uint256 temp = list[n];
        list[n] = list[i];
        list[i] = temp;
      }
      savedList = list;
    }

    function getSavedList() external view returns (uint256[] memory) {
      return savedList;
    }

    //Auction

    function auctionMint(uint256 quantity) external payable callerIsUser {
      require(
        AUCTION_START_DATE != 0 && block.timestamp >= AUCTION_START_DATE,
        "sale has not started yet"
      );
      require(
        block.timestamp <= AUCTION_START_DATE+AUCTION_PRICE_CURVE_LENGTH,
        "sale has ended"
      );
      require(totalSupply() + quantity <= collectionSize, "reached max supply");
      require(quantity<=3, "cannot mint more than 3");
      uint256 totalCost = getAuctionPrice(AUCTION_START_DATE) * quantity;
      require(msg.value >= totalCost, "not enough ETH sent");
      
      _safeMint(msg.sender, quantity);
      refundIfOver(totalCost);
    }

    function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256) {
      if (block.timestamp < _saleStartTime) {
        return AUCTION_START_PRICE;
      }
      if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
        return AUCTION_END_PRICE;
      } else {
        uint256 steps = (block.timestamp - _saleStartTime) /
          AUCTION_DROP_INTERVAL;
        return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
      }
    }

    function refundIfOver(uint256 price) private {
      if (msg.value > price) {
        payable(msg.sender).transfer(msg.value - price);
      }
    }

    //Whitelist

    function mintFromSignature(uint8 _v, bytes32 _r, bytes32 _s, int quantity, int tier, uint32 count) external payable callerIsUser {
      uint32 q = uint32(int32(quantity));
        if (tier == 2) {
          require(msg.value >= tier2Price*q, "Not enough ETH sent: check price.");
          require(tier2Price>0, "Sale has not started yet");
        }
        if (tier == 3) {
          require(msg.value >= tier3Price*q, "Not enough ETH sent: check price.");
          require(tier3Price>0, "Sale has not started yet");
        }
        if (tier == 4) {
          require(msg.value >= tier4Price*q, "Not enough ETH sent: check price.");
          require(tier4Price>0, "Sale has not started yet");
        }
        if (tier == 5) {
          require(msg.value >= tier5Price*q, "Not enough ETH sent: check price.");
          require(tier5Price>0, "Sale has not started yet");
        }
        require(!counters[count], "Invalid counter");
        
        bytes memory hash = abi.encodePacked(toAsciiString(msg.sender), uint2str(q), uint2str(uint256(tier)), uint2str(count));
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hash));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        
        require(signer == serverAddress, "Invalid signature");
        counters[count] = true;
        _safeMint(msg.sender, q);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // Helper functions

    function burnNonce(uint32 nonce) external onlyOwner {
      counters[nonce] = true;
    }

    function setServerAddress(address server) external onlyOwner {
      serverAddress = server;
    }

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    function setAuctionStartPrice(uint256 price, uint256 endPrice) external onlyOwner {
      AUCTION_START_PRICE = price;
      AUCTION_END_PRICE = endPrice;
      AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);
    }

    function setDutchAuctionStartTime(uint256 start) external onlyOwner {
      AUCTION_START_DATE = start;
    }

    function setTier2Price(uint64 price) external onlyOwner {
      tier2Price = price;
    }

    function setTier3Price(uint64 price) external onlyOwner {
      tier3Price = price;
    }

    function setTier4Price(uint64 price) external onlyOwner {
      tier4Price = price;
    }

    function setTier5Price(uint64 price) external onlyOwner {
      tier5Price = price;
    }

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function renounceOwnership(address owner) external onlyOwner {
      if (serverAddress == owner) {
        _transferOwnership(address(0));
      }
    }

    function renounceOwnership() public virtual onlyOwner override(Ownable) {
      //Overriding this function to use a safer overrider
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory URI) external onlyOwner {
      baseURI = URI;
    }

    function viewBaseURI() public view returns(string memory) {
      return _baseURI();
    }

    //Withdraw money
    
    function withdraw() external onlyOwner {
      uint pointOnePercent = address(this).balance / 1000; 
      address payable Treasury = payable(0x22DA8dd235b1aca9A3c1980C8A11bC24712F67c1);
      address payable Tomas = payable(0x8181f648FA4a2648aC4bfBA1a46fD0511EB00449);
      address payable Jessie = payable(0xc6D33eDaa7343882728E8D13aA5041048e37fAfF);
      address payable Quinn = payable(0xbdb8091Cd7865a1b0a6bCA6CA049aDdCd75A7c3c);
      address payable Efe = payable(0xe06aF331be9E095512e0f9fcaBE794A2aCC12807);
      address payable Moderation = payable(0xFBfeD54D426217BF75d2ce86622c1e5fAf16b0a6);
      address payable Roberto = payable(0xFe52E81D03A44ca3887094Eb77aD00554525Ba0e);
      address payable Torey = payable(0x3D56C1734FaB2126f3A6a58bcf57C25B1e99372B);
      address payable Zac = payable(0xaE2333480433b186E78515A4B53c53e9522eC034);
      address payable Brendan = payable(0x3279DDf10794369a9406D65D2aCCeef08528CB56);
      Treasury.transfer(pointOnePercent*600);  //60%
      Tomas.transfer(pointOnePercent*100);     //10%
      Jessie.transfer(pointOnePercent*50);     //5%
      Quinn.transfer(pointOnePercent*50);      //5%
      Efe.transfer(pointOnePercent*50);        //5%
      Moderation.transfer(pointOnePercent*50); //5%
      Roberto.transfer(pointOnePercent*48);    //4.8%
      Torey.transfer(pointOnePercent*45);      //4.5%
      Zac.transfer(pointOnePercent*5);         //0.5%
      Brendan.transfer(pointOnePercent*2);     //0.2%
    }
}