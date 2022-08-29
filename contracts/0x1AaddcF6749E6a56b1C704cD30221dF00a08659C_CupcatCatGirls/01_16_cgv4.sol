// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.4;
 import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
 import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


 interface CupCatInterface is IERC721 {
     function walletOfOwner(address _owner) external view returns(uint256[] memory);
 }

 contract CupcatCatGirls is ERC721Enumerable, Ownable, ReentrancyGuard {
     using SafeMath for uint256;
     uint256 public _tokenIdTrackerReserve = 0;
     uint256 public _tokenIdTrackerSale = 0;
     uint256 public constant MAXCLAIMSUPPLY = 5024;
     uint256 public constant MAX_TOTAL_SUPPLY = 10000;
     uint256 public constant MAXRESERVE = 176;
     uint256 public constant MAXSALE = MAX_TOTAL_SUPPLY - MAXCLAIMSUPPLY - MAXRESERVE;
     string public baseURI;
     address public authorizedSigner;
     uint256 public costWl = 0.035 ether;
     uint256 public costPublic = 0.05 ether;
     uint256 public costAl = 0.04 ether;
     bool public claimState = false;
     bool public saleState = false;
     bool public wlState = false;
     bool public alState = false;
     mapping(address => uint256) public addressMintedBalance;
     mapping(address => uint256) public addressAllowListMintedBalance;
     CupCatInterface public cupCats;

     constructor() ERC721("Cupcat Catgirls", "CCG") {
         setBaseURI("/");
         setCupcatSigner(0x8Cd8155e1af6AD31dd9Eec2cEd37e04145aCFCb3, 0x486662389b41B3921491547A9ad0507CD3C8Dd5D);
     }
     // internal
     function _baseURI() internal view virtual override returns(string memory) {
         return baseURI;
     }

     // public
     function whiteListMint(bytes memory signature, uint8 _count, uint8 wlSpot) public payable  nonReentrant {
         require(wlState, "Whitelist sale not started yet.");
         require(_tokenIdTrackerSale.add(_count) <= MAXSALE, "Sold Out!");
         require(msg.value == costWl.mul(_count), "Ether value sent is not correct");
         require(addressMintedBalance[msg.sender].add(_count)<= wlSpot, "All WL Spots have been consumed");
         require(verifySig(wlSpot, signature) == authorizedSigner, "Signer address mismatch");
         for (uint256 i = 0; i < _count; i++) {
             //Mark Mint
             addressMintedBalance[msg.sender]++;
             _safeMint(_msgSender(), MAXCLAIMSUPPLY + _tokenIdTrackerSale);
             _tokenIdTrackerSale += 1;
         }
     }

     function allowListMint(bytes memory signature) public payable  nonReentrant{
          require(alState, "AllowList sale not started yet.");
          require(_tokenIdTrackerSale.add(1) <= MAXSALE, "Sold Out!");
          require(addressAllowListMintedBalance[msg.sender] < 1 , "AL Spots have been consumed");
          require(msg.value == costAl.mul(1),  "Ether value sent is not correct");
          require(verifySig(1, signature) == authorizedSigner, "Signer address mismatch");
          addressAllowListMintedBalance[msg.sender]++;
          _safeMint(_msgSender(), MAXCLAIMSUPPLY +  _tokenIdTrackerSale);
          _tokenIdTrackerSale += 1;
     }

     function mint(uint256 _count) public payable  nonReentrant {
         require(saleState, "sale not started yet");
         require(_tokenIdTrackerSale.add(_count) <= MAXSALE, "Sold Out!");
         require(_count > 0 && _count <= 9, "Can only mint 9 tokens at a time");
         require(msg.value == costPublic.mul(_count), "Ether value sent is not correct");
         for (uint256 i = 0; i < _count; i++) {
             _safeMint(_msgSender(), MAXCLAIMSUPPLY + _tokenIdTrackerSale);
             _tokenIdTrackerSale += 1;
         }
     }

     function claim(uint256[] memory _tokensId) public  nonReentrant {
             require(claimState, "Claim period not started yet.");
             for (uint256 i = 0; i < _tokensId.length; i++) {
             uint256 tokenId = _tokensId[i];
             require(_exists(tokenId) == false, "Already claimed!");
             require(tokenId < MAXCLAIMSUPPLY, "Post-claim cupcat!");
             require(cupCats.ownerOf(tokenId) == _msgSender(), "Bad owner!");
             _safeMint(_msgSender(), tokenId);
         }
     }

     function reserve(uint256 _count) public onlyOwner {
         require(_tokenIdTrackerReserve + _count <= MAXRESERVE, "Exceeded giveaways.");
         for (uint256 i = 0; i < _count; i++) {
             _safeMint(_msgSender(), MAXCLAIMSUPPLY + MAXSALE + _tokenIdTrackerReserve);
             _tokenIdTrackerReserve += 1;
         }
     }

     function checkClaim(uint256 _tokenId) public view returns(bool) {
         return _exists(_tokenId) == false;
     }

     function walletOfOwner(address _owner)
     public
     view
     returns(uint256[] memory) {
         uint256 ownerTokenCount = balanceOf(_owner);
         uint256[] memory tokenIds = new uint256[](ownerTokenCount);
         for (uint256 i; i < ownerTokenCount; i++) {
             tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
         }
         return tokenIds;
     }



     //only owner
     
     function setCupcatSigner(address _cupCats, address _authorizedSigner) public onlyOwner {
         authorizedSigner=_authorizedSigner;
         cupCats = CupCatInterface(_cupCats);
     }

     function setBaseURI(string memory _newBaseURI) public onlyOwner {
         baseURI = _newBaseURI;
     }


     function setSaleState(bool _state) public onlyOwner {
         saleState = _state;
     }

     function setClaimState(bool _state) public onlyOwner {
         claimState = _state;
     }

     function setWlState(bool _state) public onlyOwner {
         wlState = _state;
     }

    function setAlState(bool _state) public onlyOwner {
         alState = _state;
     }

     function withdraw() public payable onlyOwner {
         (bool os, ) = payable(owner()).call {
             value: address(this).balance
         }("");
         require(os);
     }

     //private
     function verifySig(uint8 wlSpot, bytes memory signature) private view returns(address) {
         bytes32 messageDigest = keccak256(abi.encodePacked(msg.sender, wlSpot));
         bytes32 message = ECDSA.toEthSignedMessageHash(messageDigest);
         return ECDSA.recover(message, signature);
     }
 }