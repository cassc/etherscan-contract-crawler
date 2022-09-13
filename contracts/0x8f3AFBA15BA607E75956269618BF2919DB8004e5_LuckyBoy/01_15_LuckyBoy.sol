// SPDX-License-Identifier: MIT
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";
    import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
    import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


    pragma solidity ^0.8.4;
    pragma abicoder v2;
    
    //░█████╗░██╗░░██╗███████╗███████╗░██████╗███████╗  ░█████╗░██████╗░████████╗  ██╗░░░░░░█████╗░██████╗░░██████╗
    //██╔══██╗██║░░██║██╔════╝██╔════╝██╔════╝██╔════╝  ██╔══██╗██╔══██╗╚══██╔══╝  ██║░░░░░██╔══██╗██╔══██╗██╔════╝
    //██║░░╚═╝███████║█████╗░░█████╗░░╚█████╗░█████╗░░  ███████║██████╔╝░░░██║░░░  ██║░░░░░███████║██████╦╝╚█████╗░
    //██║░░██╗██╔══██║██╔══╝░░██╔══╝░░░╚═══██╗██╔══╝░░  ██╔══██║██╔══██╗░░░██║░░░  ██║░░░░░██╔══██║██╔══██╗░╚═══██╗
    //╚█████╔╝██║░░██║███████╗███████╗██████╔╝███████╗  ██║░░██║██║░░██║░░░██║░░░  ███████╗██║░░██║██████╦╝██████╔╝
    //░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░╚══════╝  ╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░

    //This NFT series is owned by Cheese Art Labs. Being the first NFT series of the ecosystem, these NFT holders have angel investor status and gain many advantages. Check the whitepaper for details.
    
    contract LuckyBoy is ERC721, Ownable, ERC721Enumerable {
      using SafeMath for uint256;
      using Strings for uint256;
    
      uint256 public constant maxTokenPurchase = 3;
      uint256 public constant MAX_TOKENS = 1250;
      uint256 public publicPrice = 0.038 ether;
      uint256 public presalePrice = 0.038 ether;
    
      string public baseURI = ""; // IPFS URI IS OPEN IN THIS NFT SERIES
    
      bool public saleIsActive = false;
      bool public presaleIsActive = false;
      bool public isRevealed = false;
    
      mapping(address => bool) private _presaleList;
      mapping(address => uint256) private _presaleListClaimed;
    
      uint256 public presaleMaxMint = 1000; //UNLIMITED AMOUNT FOR ANGEL INVESTORS.
      uint256 public devReserve = 250;
    
      event LuckyBoyMinted(uint256 tokenId, address owner);
    
      constructor() ERC721("Lucky Boy", "LB") {}
    
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
      }
    
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os);
      }
    
      function reveal() public onlyOwner {
        isRevealed = true;
      } 

      function reserveTokens(address _to, uint256 _reserveAmount)
        external
        onlyOwner
      {
        require(
          _reserveAmount > 0 && _reserveAmount <= devReserve,
          "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
          uint256 id = totalSupply();
          _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
      }
    
      function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
      }
    
      function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
      }
    
      function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
      {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
          // Return an empty array
          return new uint256[](0);
        } else {
          uint256[] memory result = new uint256[](tokenCount);
          uint256 index;
          for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
          }
          return result;
        }
      }
   
      function mintLuckyBoy(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Token");
        require(
          numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
          "Can only mint one or more tokens at a time"
        );
        require(
          totalSupply().add(numberOfTokens) <= MAX_TOKENS,
          "Purchase would exceed max supply of tokens"
        );
        require(
          msg.value >= publicPrice.mul(numberOfTokens),
          "Ether value sent is not correct"
        );
    
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 id = totalSupply().add(1);
          if (totalSupply() < MAX_TOKENS) {
            _safeMint(msg.sender, id);
            emit LuckyBoyMinted(id, msg.sender);
          }
        }
      }
    
      function presaleLuckyBoy(uint256 numberOfTokens) external payable {
        require(presaleIsActive, "Presale is not active");
        require(_presaleList[msg.sender], "You are not on the Presale List");
        require(
          totalSupply().add(numberOfTokens) <= MAX_TOKENS,
          "Purchase would exceed max supply of token"
        );
        require(
          numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
          "Cannot purchase this many tokens"
        );
        require(
          _presaleListClaimed[msg.sender].add(numberOfTokens) <= presaleMaxMint,
          "Purchase exceeds max allowed"
        );
        require(
          msg.value >= presalePrice.mul(numberOfTokens),
          "Ether value sent is not correct"
        );
    
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 id = totalSupply().add(1);
          if (totalSupply() < MAX_TOKENS) {
            _presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, id);
            emit LuckyBoyMinted(id, msg.sender);
          }
        }
      }
    
      function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
    
          _presaleList[addresses[i]] = true;
        }
      }
    
      function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
      {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
    
          _presaleList[addresses[i]] = false;
        }
      }
    
      function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMint = maxMint;
      }
    
      function onPreSaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
      }
    
      function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
    
        string memory currentBaseURI = _baseURI();
    
        if (isRevealed == false) {
          return
            "ipfs://bafybeidbmfmdtcucprodulfegnewwwqxxcatdgz3lk6i25wbf6rxmprrfi/";
        }
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
            
      }
    
      function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
      ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
      }
    
      function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
      {
        return super.supportsInterface(interfaceId);
      }

      function setNewPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
      }
     
      function setNewpresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
      }

    }