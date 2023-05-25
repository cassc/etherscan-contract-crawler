// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface CupCatInterface is IERC721{
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract CupcatKittens is ERC721Enumerable, Ownable, ReentrancyGuard  {  
    using SafeMath for uint256;
    uint256 public _tokenIdTrackerReserve;
    uint256 public _tokenIdTrackerSale;
    using Strings for uint256;
    uint256 public constant MAXCLAIMSUPPLY = 5025;
    uint256 public constant MAX_TOTAL_SUPPLY = 10000; 
    uint256 public constant MAXRESERVE = 225;
    uint256 public constant MAXSALE = MAX_TOTAL_SUPPLY - MAXCLAIMSUPPLY - MAXRESERVE;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 17500000000000000;
    bool public paused = false;
    bool public claimState = false;
    bool public saleState = false;
    bytes32 public merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
    mapping(address => uint256) public addressMintedBalance;
    event MerkleRootUpdated(bytes32 new_merkle_root);
    CupCatInterface public cupCats;

constructor(
    ) ERC721("Cupcat Kittens", "CCK") {
    setBaseURI("exampleurl");
    setCupcats(0x8Cd8155e1af6AD31dd9Eec2cEd37e04145aCFCb3);
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }
    //Modify
    modifier claimIsOpen {
          require(claimState, "Claim is Closed");
          require(!paused, "Contract Paused");
          _;
      }
    modifier saleIsOpen {
          require(saleState, "Sale is Closed");
          require(!paused, "Contract Paused");
          _;
      }
    // public
    function whiteListMint(bytes32[] calldata _merkleProof ) public payable  {
          require(!paused, "the contract is paused");
          require(merkleRoot != 0x0000000000000000000000000000000000000000000000000000000000000000 , "White List Mints Closed");
          require(_tokenIdTrackerSale.add(1) <= MAXSALE, "Sold Out!");
          //Verify Already whiteListMint this Wallet
          require(addressMintedBalance[msg.sender] < 1 , "Already Claimed the whitelisted mint");
          //Merkle
          require(MerkleProof.verify(_merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");
          //verify Cost
          require(msg.value == cost.mul(1),  "Ether value sent is not correct");
          //Mark Claim
          addressMintedBalance[msg.sender]++;
          //Mint --
          _safeMint(_msgSender(), MAXCLAIMSUPPLY +  _tokenIdTrackerSale);
          _tokenIdTrackerSale += 1;
    }
    function mint(uint256 _count) public payable saleIsOpen nonReentrant{
          require(!paused, "the contract is paused");
          require(_tokenIdTrackerSale.add(_count) <= MAXSALE, "Sold Out!");
          require(_count > 0 && _count <= 9, "Can only mint 9 tokens at a time");
          require(msg.value==cost.mul(_count), "Ether value sent is not correct");
          for (uint256 i = 0; i < _count; i++) {
              addressMintedBalance[msg.sender]++;
              _safeMint(_msgSender(), MAXCLAIMSUPPLY  + _tokenIdTrackerSale);
              _tokenIdTrackerSale += 1;
          }
    }
    function claim(uint256[] memory _tokensId) public claimIsOpen {
          //Require claimIsOpen True
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
                  _safeMint(_msgSender(), MAXCLAIMSUPPLY + MAXSALE+ _tokenIdTrackerReserve);
                  _tokenIdTrackerReserve += 1;
            }
    }
    function checkClaim(uint256 _tokenId) public view returns(bool) {
        return _exists(_tokenId) == false;
    }
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
        {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
      return tokenIds;
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
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    //only owner
    function setCupcats(address _cupCats) public onlyOwner {
        cupCats = CupCatInterface(_cupCats);
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    function setSaleState(bool _state) public onlyOwner{
        saleState = _state;
    }
    function setClaimState(bool _state) public onlyOwner {
        claimState = _state;
    }
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    // to set the merkle proof
    function updateMerkleRoot(bytes32 newmerkleRoot) external onlyOwner {
        merkleRoot = newmerkleRoot;
        emit MerkleRootUpdated(merkleRoot);
    }
}