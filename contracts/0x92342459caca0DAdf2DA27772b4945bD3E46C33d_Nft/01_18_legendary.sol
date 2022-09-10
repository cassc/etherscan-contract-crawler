// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Nft is ERC721Enumerable,ReentrancyGuard, Ownable {
    address tokenAddress;
   using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public price = 68 ether;
    uint256 public premintprice = 30 ether;
    address t1 = 0x3C10D90796Ce828644951c0682012B3fabA52F8f;
    uint256 public maxSupply = 444;
    bool public revealed = false;
    bool public saleIsActive = false;
    bool public salePremActive = false;
    uint256 public makenftlimit = 124;
    uint256 public premintlimit = 186;
    uint256 public brandlimit = 20;
    uint256 public premintSaleCounter = 0;
    uint256 public nftSaleCounter = 0;
    uint256 public brandSaleCounter = 0;
    
    struct User {
        uint256 counter;
    }
    mapping(address => User) userStructs;

   struct metaData {
        uint256 tokenid;
        string data;
        address addr;
  }

metaData[] public Metadata;

event Mintedlegendary(
        uint256 tokenId,
        uint256 amount,
        address indexed buyer,
        string saleType
    );
   
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function premintNFT(uint256 _mintAmount) public payable nonReentrant {
        uint256 supply = totalSupply();
        IERC1155 token = IERC1155(tokenAddress);
       
        require(tokenAddress != address(0x0), "Zero address found");
        
        require(token.balanceOf(msg.sender, 3) >= 1, "No Mintpass found");
       require(salePremActive, "Sale is not active");
        require(supply + _mintAmount <= maxSupply, "Sold out");
         require(_mintAmount > 0, "need to mint at least 1 NFT");
      require(msg.value == premintprice * _mintAmount, "Funds Incorrect");
      require(premintSaleCounter + _mintAmount <= premintlimit,"Premint Sale Limit Reached");
        
       for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);

            emit Mintedlegendary(supply + i, _mintAmount, msg.sender,"Premint");
        }
        addPremintCount(_mintAmount);

        
         
    }

     function makeNft(uint256 _mintAmount) public payable nonReentrant {
        uint256 supply = totalSupply();
        
        IERC1155 token = IERC1155(tokenAddress);
        require(tokenAddress != address(0x0), "Zero address found");
        uint256 brand = token.balanceOf(msg.sender, 1);
        uint256 artist = token.balanceOf(msg.sender, 2);
        uint256 legendaryplus = token.balanceOf(msg.sender, 3);
        uint256 legendary = token.balanceOf(msg.sender, 4);

        require(saleIsActive, "Sale is not active");
        require(supply + _mintAmount <= maxSupply, "Sold out");
         require(brand >= 1 || artist >= 1 || legendaryplus >= 1 || legendary >= 1, "No Mintpass found");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(msg.value == price * _mintAmount, "Funds Incorrect");
        require(nftSaleCounter + _mintAmount <= makenftlimit,"NFT Sale Limit Reached");
       
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            emit Mintedlegendary(supply + i, _mintAmount, msg.sender,"Make NFT");
        }
       
        addnftCount(_mintAmount);
    }

    function giftNft(uint256 _mintAmount, address _address, string memory _saleType) public onlyOwner {
        uint256 supply = totalSupply();
       require(supply + _mintAmount <= maxSupply, "Sold out");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
       
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_address, supply + i);
             emit Mintedlegendary(supply + i, _mintAmount, msg.sender,_saleType);
        }
    }


    function brandNft(uint256 _mintAmount) public payable nonReentrant {
        uint256 supply = totalSupply();
        IERC1155 token = IERC1155(tokenAddress);
        require(tokenAddress != address(0x0), "Zero address found");
        require(token.balanceOf(msg.sender, 1) >= 1, "No Mintpass found");
        require(salePremActive, "Sale is not active");
        require(supply + _mintAmount <= maxSupply, "Sold out");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(brandSaleCounter + _mintAmount <= brandlimit,"Brand Sale Limit Reached");
        require(msg.value == price * _mintAmount, "insufficient funds");
         require(
            viewBrandCount(msg.sender) + _mintAmount <= 2,
            "you have reached your limit"
        );
        uint256 count = viewBrandCount(msg.sender);
        addBrandCounts(_mintAmount);
       for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            emit Mintedlegendary(supply + i, _mintAmount, msg.sender,"Brand NFT");
        }
        
        addBrandCount(count +_mintAmount);
         
    }

    function setMintPass(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function addPremintCount(uint256 y) private
    {
       premintSaleCounter= premintSaleCounter + y;
    }

    function addnftCount(uint256 y) private
    {
      nftSaleCounter= nftSaleCounter + y;
    }

     function addBrandCounts(uint256 y) private
    {
       brandSaleCounter= brandSaleCounter + y;
    }

    function addBrandCount(uint256 counter) private {
        userStructs[msg.sender].counter = counter;
    }

function updateMeta(uint256 _tokenid,string calldata  data) public {
    
        require(ownerOf(_tokenid) == msg.sender, "You are not the owner of this NFT");
        Metadata.push(
            metaData({
                tokenid: _tokenid,
                data: data,
                addr: msg.sender
            })
        );
    }
   

    function reveal() public onlyOwner {
        revealed = true;
    }

    function notreveal() public onlyOwner {
        revealed = false;
    }

    function setPrice(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMakeNftLimit(uint256 _newMakeNftLimit) public onlyOwner {
        makenftlimit = _newMakeNftLimit;
    }

    function setPremintLimit(uint256 _newPremintLimit) public onlyOwner {
        premintlimit = _newPremintLimit;
    }

    function setBrandLimit(uint256 _newBrandLimit) public onlyOwner {
        brandlimit = _newBrandLimit;
    }

    

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

   

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSale() public onlyOwner {
             salePremActive = !salePremActive;
    }
 
    function viewBrandCount(address _inst) public view returns (uint256) {
        return userStructs[_inst].counter;
    }


     function withdrawAll() public payable onlyOwner {
      (bool success, ) =  payable(t1).call{value: address(this).balance}("");
         require(success);
    }

    function withdrawFixed(uint256 _amt) public payable onlyOwner {
      (bool success, ) =  payable(t1).call{value: _amt}("");
         require(success);
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}