// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract OriginalGarageSocialClub is Ownable, ERC721Enumerable, ERC721Burnable {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _classIds;
    string private _tokenBaseURI = "";

    bool public isPaused = true;
    uint256 public maxPerMint = 5;

    // Payment addresses + Payments basis points (percentage using 2 decimals - 10000 = 100, 0 = 0)
    address private paymentAddress1 = 0x8dA102738bcaa9d5C490B1989B68C42EfE84011e;
    uint256 private paymentBasisPoints1 = 5000;
    address private paymentAddress2 = 0x12aA16964A1F6E89b77b05B81653F3Bf7042E7Ab;
    uint256 private paymentBasisPoints2 = 4500;
    address private paymentAddress3 = 0xB9302Eff098a224DC4b50cc50a4191e9F8d41D63;
    uint256 private paymentBasisPoints3 = 250;
    address private paymentAddress4 = 0x089553a12C7275269Cbd6A3743507C6EFDCb669B;
    uint256 private paymentBasisPoints4 = 250;
    
    // Royalties address
    address private royaltyAddress = 0x6FD81E439d8f9Cc85B36F579F1950b59aEb40437;

    // Royalties basis points (percentage using 2 decimals - 10000 = 100, 0 = 0)
    uint256 private royaltyBasisPoints = 1000; // 10%

    struct ClassInfo {
        uint256 priceType; // 0 == fixed (uses startPrice), 1 == dutch (uses startPrice and endPrice)
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
    }

    mapping(uint256 => ClassInfo) public classInfos;
    mapping(uint256 => uint256) public tokenClasses; // tokenId => classId
    mapping(uint256 => uint256) public tokenMintOrdering; // tokenId => mint order within class
    mapping(uint256 => uint256) public amountMinted; // classId => amount minted

    constructor(string memory _initialBaseURI) ERC721("OG (Original Garage) Social Club NFT", "OGC") {
      _tokenBaseURI = _initialBaseURI;
    }

    function getPrice(uint256 _classId) public view returns (uint256) {
      ClassInfo memory classInfo = classInfos[_classId];

      uint256 mintPrice = classInfo.startPrice; // fixed price
      if (classInfo.priceType == 1) { // dutch price
        
        if (block.timestamp >= classInfo.endTime) {
          return classInfo.endPrice;
        }

        if (block.timestamp <= classInfo.startTime) {
          return classInfo.startPrice;
        }

        if (classInfo.startPrice > classInfo.endPrice) { // dutch price goes down over time
          mintPrice = classInfo.endPrice + ((classInfo.startPrice - classInfo.endPrice) * (classInfo.endTime - block.timestamp) / (classInfo.endTime - classInfo.startTime));
        } else { // dutch price goes up over time
          mintPrice = classInfo.startPrice + ((classInfo.endPrice - classInfo.startPrice) * (block.timestamp - classInfo.startTime) / (classInfo.endTime - classInfo.startTime));
        }
      }

      return mintPrice;
    }

    function mint(uint256 _classId, uint256 _amount, address _to) public payable {
        require(!isPaused, 'mint: Minting is paused.');
        require(_classId < _classIds.current(), 'mint: ClassId is invalid.');
        ClassInfo memory classInfo = classInfos[_classId];
        uint256 amountMintedForClass = amountMinted[_classId];
        require(block.timestamp >= classInfo.startTime, "mint: Mint for this class hasn't started yet");
        require(block.timestamp <= classInfo.endTime, "mint: Mint for this class has ended");
        require(amountMintedForClass + _amount <= classInfo.maxSupply, "mint: Not enough supply remaining of this class");
        require(_amount <= maxPerMint, "mint: Amount more than max per mint");

        uint256 mintPrice = getPrice(_classId);

        uint256 costToMint = mintPrice * _amount;

        require(costToMint <= msg.value, "mint: ETH amount sent is not correct");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIds.current();
            tokenClasses[tokenId] = _classId;
            tokenMintOrdering[tokenId] = amountMintedForClass + 1;
            _mint(_to, tokenId);
            amountMinted[_classId] = amountMintedForClass + 1;
            _tokenIds.increment();
        }

        uint256 payment1 = costToMint * paymentBasisPoints1 / 10000;
        uint256 payment2 = costToMint * paymentBasisPoints2 / 10000;
        uint256 payment3 = costToMint * paymentBasisPoints3 / 10000;
        uint256 payment4 = costToMint - payment1 - payment2 - payment3;

        Address.sendValue(payable(paymentAddress1), payment1);
        Address.sendValue(payable(paymentAddress2), payment2);
        Address.sendValue(payable(paymentAddress3), payment3);
        Address.sendValue(payable(paymentAddress4), payment4);

        uint256 remainder = msg.value - payment1 - payment2 - payment3 - payment4;

        // Return unused value
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), remainder);
        }
    }

    function ownerMint(uint256 _classId, uint256 _amount, address _to) external onlyOwner {
        require(_classId < _classIds.current(), 'mint: ClassId is invalid.');
        ClassInfo memory classInfo = classInfos[_classId];
        uint256 amountMintedForClass = amountMinted[_classId];
        require(amountMintedForClass + _amount <= classInfo.maxSupply, "mint: Not enough supply remaining of this class");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIds.current();
            tokenClasses[tokenId] = _classId;
            tokenMintOrdering[tokenId] = amountMintedForClass + 1;
            _mint(_to, tokenId);
            amountMinted[_classId] = amountMintedForClass + 1;
            _tokenIds.increment();
        }
    }

    function addClass(uint256 _priceType, uint256 _maxSupply, uint256 _startPrice,
      uint256 _endPrice, uint256 _startTime, uint256 _endTime) external onlyOwner {
        uint256 classId = _classIds.current();
        classInfos[classId].priceType = _priceType;
        classInfos[classId].maxSupply = _maxSupply;
        classInfos[classId].startPrice = _startPrice;
        classInfos[classId].endPrice = _endPrice;
        classInfos[classId].startTime = _startTime;
        classInfos[classId].endTime = _endTime;
        _classIds.increment();
    }

    function updateClass(uint256 _classId, uint256 _priceType, uint256 _maxSupply, uint256 _startPrice,
      uint256 _endPrice, uint256 _startTime, uint256 _endTime) external onlyOwner {
        uint256 nextClassId = _classIds.current();
        require(_classId < nextClassId, 'mint: Class ID does not exist.');
        require(_classId >= 0, 'mint: Class ID must be positive.');
        classInfos[_classId].priceType = _priceType;
        classInfos[_classId].maxSupply = _maxSupply;
        classInfos[_classId].startPrice = _startPrice;
        classInfos[_classId].endPrice = _endPrice;
        classInfos[_classId].startTime = _startTime;
        classInfos[_classId].endTime = _endTime;
    }

    function getTokenClassId(uint256 _tokenId) external view returns (uint256) {
      return tokenClasses[_tokenId];
    }

    function getTokenOrderingInClass(uint256 _tokenId) external view returns (uint256) {
      return tokenMintOrdering[_tokenId];
    }

    function getAmountMinted(uint256 _classId) external view returns (uint256) {
      return amountMinted[_classId];
    }

    function getClassInfo(uint256 _classId) external view returns (ClassInfo memory) {
      return classInfos[_classId];
    }

    // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyAddress,
            (_salePrice.mul(royaltyBasisPoints)).div(10000)
        );
    }

    function setBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint2str(tokenId)));
    }

    // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    function setPaymentAddress(uint256 _index, address _address) public onlyOwner {
      require(_index == 1 || _index == 2 || _index == 3 || _index == 4, "setPaymentAddress: Invalid index");

      if (_index == 1) {
          paymentAddress1 = _address;
      } else if (_index == 2) {
          paymentAddress2 = _address;
      } else if (_index == 3)  {
          paymentAddress3 = _address;
      } else if (_index == 4)  {
          paymentAddress4 = _address;
      }
    }

    function setPaymentBasisPoints(uint256 _index, uint256 _basisPoints) public onlyOwner {
        require(_index == 1 || _index == 2 || _index == 3 || _index == 4, "setPaymentBasisPoints: Invalid index");
        require(_basisPoints >= 0 && _basisPoints <= 10000, "setPaymentBasisPoints: Invalid basis points");

        if (_index == 1) {
            paymentBasisPoints1 = _basisPoints;
        } else if (_index == 2) {
            paymentBasisPoints2 = _basisPoints;
        } else if (_index == 3) {
            paymentBasisPoints3 = _basisPoints;
        } else if (_index == 4) {
            paymentBasisPoints4 = _basisPoints;
        }
    }

    function setRoyaltyAddress(address _address) public onlyOwner {
        royaltyAddress = _address;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) public onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setMaxPerMint(uint256 _maxPerMint) public onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function turnPauseOn() external onlyOwner {
        isPaused = true;
    }

    function turnPauseOff() external onlyOwner {
        isPaused = false;
    }

    function burn(uint256 _tokenId) public override {
        super.burn(_tokenId);
        uint256 classId = tokenClasses[_tokenId];
        amountMinted[classId] = amountMinted[classId] - 1;
        if (amountMinted[classId] < 0) {
          amountMinted[classId] = 0;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}