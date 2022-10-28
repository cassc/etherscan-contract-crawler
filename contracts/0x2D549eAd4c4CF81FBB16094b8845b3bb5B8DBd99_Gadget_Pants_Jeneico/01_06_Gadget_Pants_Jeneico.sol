// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Kenchiro.
// Source code forked from Keisuke OHNO.

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Gadget_Pants_Jeneico is ERC721A, Ownable {

  address public withdrawAddress;
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.001 ether;  //★
  uint256 public maxSupply = 8282;    //★

  uint8 public saleStage = 0; //現在のセール内容
                              //0 : consruct paused
                              //1 : WL Sale
                              //2 : Public Sale
                              //3 : BurnMint Sale
           
  uint256 public maxPubSaleMintAmount = 10;
  mapping(address => uint256) public publicMintedAmount;

  uint8 constant MAX_WL_SALE = 30;            //WLセール最大回数
  uint8 public wlSaleCount = 0;               //1回目のセールが0
  uint8[MAX_WL_SALE] public maxWLMintAmount;  //wlSaleCountごとのMint枚数
  bytes32[MAX_WL_SALE] public WLMearkleRoot;  //wlSaleCountに応じたMearkleRoot
  mapping(address => uint8[MAX_WL_SALE]) public WLMintedAmount;   //アドレスに対してwlSaleCountに応じたmint枚数を格納

  uint256 public maxBmSupply = 500;  //★BMで何体出すか
  uint256 public totalBmSupply = 0;  //BMで何体出たか

  constructor(
  ) ERC721A("Gadget_Pants_Jeneico", "GPJ") {
      setBaseURI("https://gpj.lake-web.com/nft_data/meta/");
      setWithdrawAddress(0x2bb23BA44cDB0b19d36E04A8B40D509d2432244F);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    // Owner also can mint.
    if (msg.sender != owner()) {
      require(saleStage == 2, "the contract is not Public Sale");
      require(_mintAmount <= maxPubSaleMintAmount, "max mint amount per session exceeded");
      require(publicMintedAmount[msg.sender] + _mintAmount <= maxPubSaleMintAmount, "max NFT per mint amount exceeded");
      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    _safeMint(msg.sender, _mintAmount);
  }

  function wl_mint(uint8 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    
    if (msg.sender != owner()) {
      require(saleStage == 1, "the contract is not WL Sale");
      require(_mintAmount <= maxWLMintAmount[wlSaleCount], "max mint amount per session exceeded");
      require(isWhitelisted(msg.sender, _merkleProof), "You don't have WL.");
      require(WLMintedAmount[msg.sender][wlSaleCount] + _mintAmount <= maxWLMintAmount[wlSaleCount], "max NFT per address exceeded");
      require(msg.value >= cost * _mintAmount, "insufficient funds. : Wl mint");
      WLMintedAmount[msg.sender][wlSaleCount] += _mintAmount;
    }
    _safeMint(msg.sender, _mintAmount);
  }

  function burnMint(uint256[] memory _burnTokenIds, bytes32[] calldata _merkleProof) external payable {
    require(_burnTokenIds.length > 0, "need to burn-mint at least 1 NFT");
    require(totalBmSupply + _burnTokenIds.length <= maxBmSupply, "Max Burn mint Supply over!");

    if (msg.sender != owner()) {
      require(saleStage == 3, "the contract is not BurnMint Sale");
      require(_burnTokenIds.length <= maxWLMintAmount[wlSaleCount], "max burn mint amount per session exceeded");
      require(isWhitelisted(msg.sender, _merkleProof), "You don't have BMWL.");
      require(WLMintedAmount[msg.sender][wlSaleCount] + _burnTokenIds.length <= maxWLMintAmount[wlSaleCount], "max BM per address exceeded.");
      require(msg.value >= cost * _burnTokenIds.length, "insufficient funds. : BM");
    }

    for (uint256 i = 0; i < _burnTokenIds.length; i++) {
      uint256 tokenId = _burnTokenIds[i];
      require(_msgSender() == ownerOf(tokenId), "you are not owner.");
      totalBmSupply++;
      _burn(tokenId);
    }
    
    WLMintedAmount[msg.sender][wlSaleCount] += (uint8)(_burnTokenIds.length);
    _safeMint(msg.sender, _burnTokenIds.length);
}

  function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
      uint256 supply = totalSupply();
      uint256 totalmintAmount = 0;
      for (uint256 i = 0; i < _UserMintAmount.length; i++) {
          totalmintAmount += _UserMintAmount[i];
      }
      require(totalmintAmount > 0, "need to mint at least 1 NFT");
      require(supply + totalmintAmount <= maxSupply, "max NFT limit exceeded");

      for (uint256 i = 0; i < _UserMintAmount.length; i++) {
          _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
      }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
  }

  function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_user));
    return MerkleProof.verify(_merkleProof, WLMearkleRoot[wlSaleCount], leaf);
  }
  //only owner  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
      maxSupply = _maxSupply;
  }

  function setmaxPubSaleMintAmount(uint256 _newmaxPubSaleMintAmount) public onlyOwner {
    maxPubSaleMintAmount = _newmaxPubSaleMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
      baseExtension = _newBaseExtension;
  }

  function setSaleStage(uint8 _saleStage) public onlyOwner {
    saleStage = _saleStage;
  }

  function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
    withdrawAddress = _withdrawAddress;
  }
 
 //WL
  function setMaxWLMintAmount(uint256 _wlSaleCount, uint8 _maxWLMintAmount) public onlyOwner{
      maxWLMintAmount[_wlSaleCount] = _maxWLMintAmount;
  }
  
  function setWLMearkleRoot(uint256 _wlSaleCount, bytes32 _wlMearkleRoot) public onlyOwner{
      WLMearkleRoot[_wlSaleCount] = _wlMearkleRoot;
  }

  function setWlSaleCount(uint8 _wlSaleCount) public onlyOwner{
      require(_wlSaleCount <= MAX_WL_SALE, "WL Sale count over!");
      wlSaleCount = _wlSaleCount;
  }

//Burn-Mint
  function setMaxBmSupply(uint256 _maxBmSupply) public onlyOwner {
    maxBmSupply = _maxBmSupply;
  }

//Other
  function withdraw() public payable onlyOwner {
      (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
      require(os);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }    
}