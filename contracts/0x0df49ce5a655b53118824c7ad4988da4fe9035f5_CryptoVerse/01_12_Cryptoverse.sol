// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CryptoVerse is ERC721, Ownable {
		
    event SetPresaleMerkleRoot(bytes32 root);

    event SetOGMintMerkleRoot(bytes32 root);

    event CryptoVerseMinted(uint tokenId, address sender);

    uint256 public TOTAL_SUPPLY = 3333;

    uint256 public price = 0.03 ether;

    uint256 public presalePrice = 0.02 ether;

    uint256 public MAX_PURCHASE = 3;

    uint256 public MAX_PRESALE_TOKENS = 3;

    uint256 public MAX_OG_TOKENS = 4;

    bool public saleIsActive = false;

    bool public presaleIsActive = false;

    bool public ogMintIsActive = false;

    string private baseURI;

    uint256 private _currentTokenId = 0;

    bytes32 public merkleRoot;
    
    bytes32 public merkleRootOG;

    mapping(address => uint) public whitelistClaimed;
    mapping(address => uint) public whitelistOGClaimed;


    constructor(string memory _baseURI) ERC721("CryptoVerseSpike","CVSpike") {
            setBaseURI(_baseURI);

    }
	
    //PUBLIC MINT 
    function mintSpikesTo(uint numberOfTokens) external payable {
          require(saleIsActive, "Wait for sales to start!");
          require(numberOfTokens <= MAX_PURCHASE, "Too many Spikes to mint!");
          require(_currentTokenId + numberOfTokens <= TOTAL_SUPPLY, "All Spikes has been minted!");
          require(msg.value >= price * numberOfTokens, "insufficient ETH");

          for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _currentTokenId+1);
                emit CryptoVerseMinted(_currentTokenId+1, msg.sender);
                _incrementTokenId();
          }
    }

    //RESERVE MINT
    function reserveMint(uint numberOfTokens) external onlyOwner {
            for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _currentTokenId+1);
                emit CryptoVerseMinted(_currentTokenId+1, msg.sender);
                _incrementTokenId();
            }
    }

    

    //OG MINT
  	function ogMint(bytes32[] calldata _merkelProof, uint numberOfTokens) external payable {
        uint256 reserved = whitelistOGClaimed[msg.sender];
        require(ogMintIsActive, "Wait for OG mint to start!");
        require(_currentTokenId + numberOfTokens <= TOTAL_SUPPLY, "All Spikes has been minted!");
        require(msg.value >= presalePrice * numberOfTokens, "insufficient ETH");
        require(reserved + numberOfTokens <= MAX_OG_TOKENS,string(abi.encodePacked("You have ", uint2str( MAX_OG_TOKENS - reserved ), " tokens left to mint")));
        require(numberOfTokens <= MAX_OG_TOKENS, "Too many Spikes to mint!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkelProof, merkleRootOG, leaf), "Invalid proof.");

        reserved = MAX_OG_TOKENS - numberOfTokens;
        
        for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _currentTokenId+1);
                emit CryptoVerseMinted(_currentTokenId+1, msg.sender);
                _incrementTokenId();
                whitelistOGClaimed[msg.sender] += 1;
        }
    }

    //WHITELIST MINT
  	function whitelistMint(bytes32[] calldata _merkelProof, uint numberOfTokens) external payable {
        uint256 reserved = whitelistClaimed[msg.sender];
        require(presaleIsActive, "Wait for presale to start!");
        require(_currentTokenId + numberOfTokens <= TOTAL_SUPPLY, "All Spikes has been minted!");
        require(msg.value >= presalePrice * numberOfTokens, "insufficient ETH");
        require(reserved + numberOfTokens <= MAX_PRESALE_TOKENS,string(abi.encodePacked("You have ", uint2str( MAX_PRESALE_TOKENS - reserved ), " tokens left to mint ")));
        require(numberOfTokens <= MAX_PRESALE_TOKENS, "Too many Spikes to mint!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkelProof, merkleRoot, leaf), "Invalid proof.");

        reserved = MAX_PRESALE_TOKENS - numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _currentTokenId+1);
                emit CryptoVerseMinted(_currentTokenId+1, msg.sender);
                _incrementTokenId();
                whitelistClaimed[msg.sender] += 1;

        }
    }

    function assetsLeft() public view returns (uint256) {
        if (supplyReached()) {
            return 0;
        }   

        return TOTAL_SUPPLY - _currentTokenId;
    }

    function whilteListMintedQty(address userAddress) public view returns (uint) {
        return MAX_PRESALE_TOKENS - whitelistClaimed[userAddress];
    } 

    function OGMintedQty(address userAddress) public view returns (uint) {
        return MAX_OG_TOKENS - whitelistOGClaimed[userAddress];
    } 

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function supplyReached() public view returns (bool) {
        return _currentTokenId > TOTAL_SUPPLY;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function switchOGSaleIsActive() external onlyOwner {
        ogMintIsActive = !ogMintIsActive;
    }

    function switchSaleIsActive() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function switchPresaleIsActive() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit SetPresaleMerkleRoot(root);
    }

    function setOGMintMerkleRoot(bytes32 root) external onlyOwner {
        merkleRootOG = root;
        emit SetOGMintMerkleRoot(root);
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setBaseURI(string memory _newUri) public onlyOwner {
      baseURI = _newUri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

    function withdraw() external onlyOwner {
          uint balance = address(this).balance;
          payable(msg.sender).transfer(balance);
    }

    function uint2str(uint256 _i) internal pure  returns (string memory _uintAsString) {
      if (_i == 0) {
        return "0";
      }
      uint256 j = _i;
      uint256 len;
      while (j != 0) {
        len++;
        j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint256 k = len;
      while (_i != 0) {
        k = k - 1;
        uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
      }
      return string(bstr);
    }

}