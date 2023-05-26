// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface DystoPunks {
    function tokensOfOwner(address ownwer) external view returns (uint256[] memory);
}

contract DystoPunksVX is  Ownable, ERC721 {
    address constant public DystoAddress = 0xbEA8123277142dE42571f1fAc045225a1D347977;
    uint public constant MAX_PUNKS = 10077;
    uint public constant RESERVED_PUNKS = 2577;
    uint constant WL_TOKEN_PRICE = 0.07 ether;
    uint constant TOKEN_PRICE = 0.077 ether;
    bool public hasSaleStarted = false;
    bool public hasPrivateSaleStarted = false;
    mapping(address => uint) private _allowList;
    mapping(address => uint8) private _whiteList;
    mapping(uint256 => address) private _claimList;
    mapping(address => uint8) private _freeList;
    mapping(uint => bool) public claimedDysto;
    string private _baseTokenURI;
    uint public minted;
    uint private freeMinted=0;
    uint _totalClaimList;

    constructor(string memory baseTokenURI) ERC721("DystoPunks VX","DYSTOVX")  {
        setBaseURI(baseTokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function checkDystoToClaim(uint id) public view returns (bool) {
         return claimedDysto[id];
    }

    function availableDystoToClaim(address ownwer) public view returns (uint[] memory) {
         uint[] memory punks = DystoPunks(DystoAddress).tokensOfOwner(ownwer);

         uint arrayPunksLength = punks.length;
         uint x=0;
         for (uint i=0; i<arrayPunksLength; i++) {
              uint256 id = punks[i];
              if (claimedDysto[id]==false) {
                  x++;
              }
         }
         uint[] memory punksavAliable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayPunksLength; i++) {
              if (claimedDysto[punks[i]]==false) {
                  punksavAliable[x]=punks[i];
                  x++;
              }
         }
         return punksavAliable;
    }

    function DystosClaim(uint[] calldata ids) public {
        uint[] memory punks = availableDystoToClaim(msg.sender);
        uint arrayIdsLength = ids.length;
        uint arrayPunksLength = punks.length;
        require(arrayPunksLength >= 1, "Nothing to claim");
        require(hasPrivateSaleStarted == true, "Sale has not already started");
        bool mintdystos=true;
        for (uint i=0; i<arrayIdsLength; i++) {
              bool inArray=false;
              for (uint j=0; i<arrayPunksLength; j++) {
                  if (punks[j]==ids[i]) {
                       inArray=true;
                       break;
                  }
              }
              if (inArray==false) {
                  mintdystos=false;
              }
        }
        if (mintdystos) {
            for (uint i=0; i < arrayIdsLength; i++) {
                 _safeMint(msg.sender, ids[i]);
                 claimedDysto[ids[i]] = true;
            }
        }
    }

    function setAllowList(address[] calldata addresses, uint[] calldata num) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = num[i];
        }
    }

    function numAllowMint(address addr) public view returns (uint) {
        return _allowList[addr];
    }

    function mintAllowList(uint numVX) public payable {
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(minted + RESERVED_PUNKS + numVX <= MAX_PUNKS, "Exceeds MAX_PUNKS");
        require(msg.value >= WL_TOKEN_PRICE * numVX, "Ether value sent is below the price");
        require(_allowList[msg.sender] > 0, "Not whitelisted");
        require(numVX <= _allowList[msg.sender], "Exceeds white list num");
        for (uint i = 0; i < numVX; i++) {
            uint mintIndex = minted + RESERVED_PUNKS;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }
        _allowList[msg.sender] -= numVX;
    }

    function setClaimMint(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _claimList[i] = addresses[i];
            _totalClaimList++;
        }
    }

    function availableToClaim(address ownwer) public view returns (uint[] memory) {
        uint x=0;
        for (uint i=0; i<_totalClaimList; i++) {
             if (_claimList[i]==ownwer) {
                 x++;
             }
        }
        uint[] memory punksAvailable = new uint[](x);
        x=0;
        for (uint i=0; i<_totalClaimList; i++) {
             if (_claimList[i]==ownwer) {
                 punksAvailable[x]=i;
                 x++;
             }
        }
        return punksAvailable;
    }

    function mintClaimList() public {
        require(hasPrivateSaleStarted == true, "Sale has not already started");
        uint[] memory punks = availableToClaim(msg.sender);
        require(punks.length > 0, "Not white List");
        for (uint i=0; i<punks.length; i++) {
              uint mintId=punks[i]+2077;
              _safeMint(msg.sender, mintId);
              _claimList[punks[i]]=address(0);
        }

    }

    function setFreeList(address[] calldata addresses, uint8[] calldata num) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeList[addresses[i]] = num[i];
        }
    }

    function numFreeMint(address addr) public view returns (uint8) {
        return _freeList[addr];
    }

    function mintfreeList() public {
        uint8 numVX =_freeList[msg.sender];
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(numVX > 0, "Not white List");
        require(freeMinted + numVX < 301, "Exceeds free List");
        for (uint i = 0; i < numVX; i++) {
            uint mintIndex = freeMinted + 2277;
            _safeMint(msg.sender, mintIndex);
             freeMinted += 1;
        }
        _freeList[msg.sender] -= numVX;
    }

    function publicMint(uint numVX) public payable {
        require(minted + RESERVED_PUNKS < MAX_PUNKS, "Sale has already ended");
        require(hasSaleStarted == true, "Sale has not already started");
        require(numVX < 11, "You can mint minimum 1, maximum 10 VX");
        require(minted + RESERVED_PUNKS + numVX <= MAX_PUNKS, "Exceeds MAX_PUNKS");
        require(msg.value >= TOKEN_PRICE * numVX, "Ether value sent is below the price");
        for (uint i = 0; i < numVX; i++) {
            uint mintIndex = minted + RESERVED_PUNKS;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }

    }

    function setWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = 2;
        }
    }

    function numWhiteMint(address addr) public view returns (uint8) {
        return _whiteList[addr];
    }

    function mintWhiteList(uint8 numVX) public payable {
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(minted + RESERVED_PUNKS + numVX <= MAX_PUNKS, "Exceeds MAX_PUNKS");
        require(msg.value >= WL_TOKEN_PRICE * numVX, "Ether value sent is below the price");
        require(_whiteList[msg.sender] > 0, "Not whitelisted");
        require(numVX <= _whiteList[msg.sender], "Exceeds white list num");
        for (uint i = 0; i < numVX; i++) {
            uint mintIndex = minted + RESERVED_PUNKS;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }
        _whiteList[msg.sender] -= numVX;
    }

    function reserveAirdrop(uint numVX) public onlyOwner {
        require(minted + RESERVED_PUNKS < MAX_PUNKS, "Exceeds MAX_PUNKS");
        //require(numVX < 31, "Exceeded airdrop supply");
        for (uint i = 0; i < numVX; i++) {
            uint mintIndex = minted + RESERVED_PUNKS;
            _safeMint(owner(), mintIndex);
            minted += 1;
        }

    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function startPrivateSale() public onlyOwner {
        hasPrivateSaleStarted = true;
    }

    function pausePrivateSale() public onlyOwner {
        hasPrivateSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}