// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract Genesis is ERC721AQueryable, Ownable {

    using Strings for uint256;
    string public baseTokenURI;
    string public hiddenTokenURI;
    uint256 public maxSupply = 8778;
    uint256 public maxCollection = 5;
    uint256 public maxAmountPerTx = 20;

    uint256 public maxAirdropSupply = 6000;
    uint256 public prePrice = 0.1 ether;
    uint256 public publicPrice = 0.1 ether;
    uint256 private lId = 0;
    uint256 public airdropSupply;
    uint256 public revealTime = 0;
    bytes32 public merkleRootWL;
    bytes32[7] public merkleRootTypes;
    bool public isTokenHidden = true;
    bool public isPublicSaleActive = false;
    bool public paused = false;


    modifier onlyNotPaused() {
        require(!paused, '1');
        _;
    }
    
    constructor() ERC721A("Genesis", "GN") {
    }
  /// @notice Set merkle roots for each background type
  /// @dev Passing merkle proofs along with claimed token type avoids spoofing
  /// @param _types array of merkle prrofs for each Genesis background type
    function setMerkleRootTypes(bytes32[] memory _types) public onlyOwner {
        require(_types.length == 7, "2");
        for(uint256 i = 0; i < 7; i++) {
            merkleRootTypes[i] = _types[i];
        }
    }

  /// @notice Get Genesis type
  /// @dev Called by staking contract to validate correct type
  /// @param _merkleProof Proof of Genesis background type
  /// @param _id token ID
  /// @param _claimedType Dapp passes known background type, merkle tree vaildates it
    function getType(bytes32[] calldata _merkleProof,  uint256 _id, uint256 _claimedType) external view returns(uint256) {
        require(_exists(_id), "GetType: URI query for nonexistent token");
        bytes32 leaf = keccak256(abi.encodePacked(_id.toString()));
        if (MerkleProof.verify(_merkleProof, merkleRootTypes[_claimedType], leaf)) {
            return 1;
        }
        return 0;
    }

    function setLId(uint256 _id) public onlyOwner {
        lId = _id;
    }

    function price() public view returns (uint256) {
        if (isPublicSaleActive) {
            return publicPrice;
        } else {
            return prePrice;
        }
    }

    function setPublicSale() public onlyOwner {
        isPublicSaleActive = true;
    }

    function setPreSale() public onlyOwner {
        isPublicSaleActive = false;
    }
    function setMaxAmountPerTx(uint256 _maxAmountPerTx) public onlyOwner {
        maxAmountPerTx = _maxAmountPerTx;
    }
    function mint(bytes32[] calldata _merkleProof,  address _to, uint256 _count) public payable onlyNotPaused {
        if(!isPublicSaleActive) { //is presale
            require(MerkleProof.verify(_merkleProof, merkleRootWL, keccak256(abi.encodePacked(_to))), '3'); 
        }
        require( balanceOf(msg.sender) <= maxCollection && _numberMinted(msg.sender) + _count <= maxCollection , '4'); 
        require(totalSupply() + _count <= maxSupply, '5');
        require(msg.value >= price() * _count, '6'); 
        require(maxAmountPerTx >= _count, '7'); 
        _safeMint(_to, _count);
    }


    function setMerkleRoot(bytes32 _merkleRootWL) public onlyOwner{
        merkleRootWL = _merkleRootWL;
    }

    function airDrop(address[] memory addresses) external onlyOwner onlyNotPaused {
        uint256 supply = totalSupply();
        require(airdropSupply + addresses.length <= maxAirdropSupply, 'This transaction would exceed airdrop max supply');
        require(supply + addresses.length <= maxSupply, 'This transaction would exceed max supply');
        for(uint8 i=0; i<addresses.length; i++) {
            _safeMint(addresses[i], 1);
            airdropSupply += 1;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenTokenURI;
    }
    
    function revealToken() public onlyOwner {
        isTokenHidden = false;
        revealTime = block.timestamp;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = isTokenHidden ? _hiddenURI() : _baseURI();
        return isTokenHidden ?  string(abi.encodePacked(currentBaseURI, "/hidden.json" )) : 
                                string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(),".json") ) ;    
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setHiddenURI(string memory baseURI) public onlyOwner {
        hiddenTokenURI = baseURI;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function numberMinted(address add) public view returns (uint256) {
        return _numberMinted(add);
    }
    
    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }
}