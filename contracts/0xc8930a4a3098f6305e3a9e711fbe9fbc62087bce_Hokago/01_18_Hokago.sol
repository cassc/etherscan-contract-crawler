/*        ■■■■■
       ■■■■■■■■■■
     ■■■■■■■    ■■■■
     ■■■■■■      ■■■      ■■■   ■■    ■■■■■    ■■   ■■■     ■■      ■■■■■      ■■■■
    ■■■■■■■■ ■  ■■■■      ■■■   ■■   ■■■ ■■■   ■■  ■■■     ■■■■    ■■■■ ■■■  ■■■  ■■■
    ■■■■■■■■    ■■■■■     ■■■   ■■  ■■■   ■■■  ■■ ■■■      ■■■■   ■■■    ■■ ■■■    ■■
    ■■■■■■■■■■■■■■■■■     ■■■■■■■■  ■■     ■■  ■■■■■      ■■■■■■  ■■■       ■■■    ■■
    ■■■■■■■■■■■■■■■■■     ■■■■■■■■  ■■     ■■  ■■■■■      ■■  ■■  ■■■ ■■■■■ ■■■    ■■
      ■■■■■■■■■■■■■■■     ■■■   ■■  ■■■    ■■  ■■■■■■    ■■■■■■■■ ■■■  ■■■■ ■■■    ■■
     ■■■■■■■■■■■■■■■■■    ■■■   ■■   ■■■■■■■   ■■  ■■■   ■■    ■■  ■■■■■■■■  ■■■■■■■
      ■■■■■■■■■■■■■■■■■   ■■■   ■■    ■■■■■    ■■   ■■■ ■■■    ■■■   ■■■■■    ■■■■■
       ■■■■■■■■■■■■■■■■■
        ■■■ ■■■■■■■■■■■■■                                             ■■■■■■■■
            ■■■■■■■■■■■■■■                                      ■■■■■■■■■■■■■■■■■■■
            ■■■■■■■■■ ■■■■■■■■■                          ■■■■■■■■              ■■■■■■■
            ■■■■■■  ■■  ■■■■■■■■■■■■             ■■■■■■■■■■                     ■■■  ■
           ■■■■■■■■    ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■                          ■■■ ■
         ■■■■■■■■■            ■■■■■■■■■■■■■■■■■■■■■■■                             ■■ ■■
       ■■■■■                       ■■■■■■■■■■■                             ■■    ■■■■
    ■■■                                                                      ■■■■■■
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./HokagoCore.sol";

contract Hokago is HokagoCore{

    using Strings for uint256;

    uint64 public preSalePrice;
    uint64 public publicSalePrice;
    uint64 public saleLimit;
    uint64 public allowListCount;
    bool public isPublicSale;
    bool public isPreSale;
    string public baseTokenURI;

    mapping(address => uint256) private _allowList;
    mapping(address => uint256) private _numberMinted;
    
    constructor(uint64 _preSalePriceWei, uint64 _publicSalePriceWei, uint64 _saleLimit, string memory _baseTokenURI)
    HokagoCore("Hokago", "HOKAGO") 
    {
        preSalePrice = _preSalePriceWei;
        publicSalePrice = _publicSalePriceWei;
        saleLimit = _saleLimit;
        baseTokenURI = _baseTokenURI;
    }


    // Sale Config
    function startPreSale()
        public
        virtual
        onlyOwner
    {
        isPublicSale = false;
        isPreSale = true;
    }

    function startPublicSale()
        public
        virtual
        onlyOwner
    {
        isPublicSale = true;
        isPreSale = false;
    }

    function pausePreSale()
        public
        virtual
        onlyOwner
    {
        isPreSale = false;
    }

    function pausePublicSale()
        public
        virtual
        onlyOwner
    {
        isPublicSale = false;
    }

    function updateSaleLimit(uint64 limit)
        external
        virtual
        onlyOwner
    {
        saleLimit = limit;
    }


    // AllowList Config
    function deleteAllowList(address addr)
        public
        virtual
        onlyOwner
    {
        allowListCount = allowListCount - uint64(_allowList[addr]);
        delete(_allowList[addr]);
    }

    function changeAllowList(address addr, uint256 maxMint)
        public
        virtual
        onlyOwner
    {
        allowListCount = allowListCount - uint64(_allowList[addr]);
        _allowList[addr] = maxMint;
        allowListCount = allowListCount + uint64(maxMint);
    }

    function pushAllowListAddresses(address[] memory list)
        public
        virtual
        onlyOwner
    {
        for (uint i = 0; i < list.length; i++) {
            _allowList[list[i]]++;
            allowListCount++;
        }
    }


    // Mint
    function devMint(uint256[] memory list)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i<list.length; i++) {
            _safeMint(_msgSender(), list[i]);
        }
    }
    
    function preSaleMint(uint256 requestTokenID)
        external
        virtual
        payable
        callerIsUser
    {
        uint256 price = uint256(preSalePrice);
        require(!_exists(requestTokenID), "Request token has already been minted");
        require(requestTokenID != 0, "Can not mintable ID (=0)");
        require(msg.value >= price, "Need to send more ETH");
        require(isPreSale, "Presale has not begun yet");
        require(_allowList[_msgSender()] > 0, "Not eligible for allowlist mint");
        require(requestTokenID <= uint256(saleLimit), "Request character is not available yet");

        _safeMint(_msgSender(), requestTokenID);
        _allowList[_msgSender()]--;
        _numberMinted[_msgSender()]++;
    }

    function publicSaleMint(uint256 requestTokenID)
        external
        virtual
        payable
        callerIsUser
    {
        uint256 price = uint256(publicSalePrice);
        require(!_exists(requestTokenID), "Request token has already been minted");
        require(requestTokenID != 0, "Can not mintable ID (=0)");
        require(msg.value >= price, "Need to send more ETH");
        require(isPublicSale, "Publicsale has not begun yet");
        require(requestTokenID <= uint256(saleLimit), "Request character is not available yet");
        require(_numberMinted[_msgSender()] < 50, "Reached mint limit (=50)");

        _safeMint(_msgSender(), requestTokenID);
        _numberMinted[_msgSender()]++;
    }


    // Generate Random-Mintable TokenID
    function generateRandTokenID(uint256 characterNo, uint256 jsTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 randNumber;
        uint256 counter = 0;
        uint256 startNo = ((characterNo-1) * 400) + 1;
        uint256 endNo = characterNo * 400;
        uint256[] memory mintableIDs = new uint256[](400);

        require(endNo <= uint256(saleLimit), "Request character is not available yet");

        for(uint256 i=startNo; i<=endNo; i++) {
            if(!_exists(i)) {
                mintableIDs[counter] = i;
                counter++;
            }
        }

        if(counter == 0){
            return 0;
        }
        else{
            randNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, jsTimestamp))) % counter;
            return mintableIDs[randNumber];
        }
    }


    // URI
    function setBaseURI(string memory baseURI)
        external
        virtual
        onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), '.json'));
    }


    // Status Chack
    function allowListCountOfOwner(address owner)
        external
        view
        returns(uint256)
    {
        return _allowList[owner];
    }

    function mintedTokens()
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256 array_length = totalSupply();
        uint256[] memory arrayMemory = new uint256[](array_length);
        for(uint256 i=0; i<array_length; i++){
            arrayMemory[i] = tokenByIndex(i);
        }
        return arrayMemory;
    }

    function mintableTokensByCharacter(uint256 characterNo)
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256 counter = 0;
        uint256 startNo = ((characterNo-1) * 400) + 1;
        uint256 endNo = characterNo * 400;
        uint256[] memory mintableIDs = new uint256[](400);

        for(uint256 i=startNo; i<=endNo; i++) {
            if(!_exists(i)) {
                mintableIDs[counter] = i;
                counter++;
            }
        }
        return mintableIDs;
    }
    
    function numberMintedOfOwner(address owner)
        external
        view
        returns (uint256)
    {
            require(owner != address(0), "Number minted query for the zero address");
            return _numberMinted[owner];
    }

}