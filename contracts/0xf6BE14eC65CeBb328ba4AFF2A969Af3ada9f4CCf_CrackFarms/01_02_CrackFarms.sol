// SPDX-License-Identifier: MIT
import "./CrackFarm.sol";
pragma solidity ^0.8.17;

contract CrackFarms is ERC721A, DefaultOperatorFilterer , Ownable {
  using Strings for uint256;

  string private uriPrefix;
  string private uriSuffix = ".json";
  string public hiddenURL;

  uint256 public p_tier_1; // (Combined Tier)
  uint256 public p_tier_1_supply;
  uint256 public p_tier_2;
  uint256 public p_tier_2_supply;
  uint256 public p_tier_3;
  uint256 public p_tier_3_supply;

  bytes32 public merkleRoot = 0x0;

  uint16 public whitelistMinted;

  uint8 public maxMintAmountPerTx = 10;

  bool public publicActive = false;
  bool public whitelistActive = false;
  bool public reveal = true;

  mapping (address => uint8) public whitelistMintsPerWallet;

  constructor(string memory prefix) ERC721A("Crack Farms", "CRACK") {
    uriPrefix = prefix;
    delete prefix;
  }

/*
 @dev Burn an NFT ~
*/
  function burn(uint256 tokenId) external {
    require(ownerOf(tokenId) == _msgSender(), "You are not the owner!");
    _burn(tokenId, true);
  }

/*
 @dev Whitelist mint for the cracked
*/
  function whitelistMintFarmer(bytes32[] calldata proof) external payable {
    require(whitelistActive, "Whitelist mint has not started!");
    require(whitelistMintsPerWallet[msg.sender] < 1, "Whitelist mint claimed!");

    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not eligible for presale");
    require(whitelistMinted <= p_tier_1_supply, "Exceeds max supply for whitelist");
    require(msg.value >= currentPrice() * 1, "Insufficient funds!");

    whitelistMintsPerWallet[msg.sender] += 1;
    whitelistMinted += 1;
    
    _safeMint(msg.sender, 1);
  }
 
/*
 @dev Public mint
*/
  function mintFarmer(uint8 _mintAmount) external payable  {
    uint16 totalSupply = uint16(totalSupply());
    require(totalSupply + _mintAmount <= p_tier_1_supply + p_tier_2_supply + p_tier_3_supply, "Exceeds max supply");
    require(_mintAmount <= maxMintAmountPerTx, "Max 10 per transaction");
    require(publicActive, "The contract is publicActive!");
    require(msg.value >= currentPrice() * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender, _mintAmount);

    delete totalSupply;
    delete _mintAmount;
  }
  
/*
 @dev Dev mint
*/
  function Reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     _safeMint(_receiver , _mintAmount);
     delete _mintAmount;
     delete _receiver;
     delete totalSupply;
  }

/*
 @dev For eligible air droppers
*/
  function Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
        }
     delete _amountPerAddress;
     delete totalSupply;
  }

/*
 @dev Gets the current price based on tier and supply
*/
  function currentPrice() public view returns (uint256) {
    uint256 minted = totalSupply();
    uint256 price = 0;
    if (minted < p_tier_1_supply) {
        price = p_tier_1;
    } else if (minted < p_tier_1_supply + p_tier_2_supply) {
        price = p_tier_2;
    } else if (minted < p_tier_1_supply + p_tier_2_supply + p_tier_3_supply) {
        price = p_tier_3;
    } else {
        price = p_tier_3;
    }
    return price;
  }

/*
 @dev Check whitelist elgiiblity
*/
  function check(bytes32[] calldata proof) external view returns (bool) {
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
  }

/*
 @dev Tokens
*/
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    if ( reveal == false)
    {
        return hiddenURL;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
    }

/*
 @dev Sets the metadata url
*/
    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }
    function setHiddenUri(string memory _uriPrefix) external onlyOwner {
        hiddenURL = _uriPrefix;
    }

/*
 @dev Sets the merkle root
*/
    function setMerkleRoot(bytes32 _root) public onlyOwner{
      merkleRoot = _root;
      delete _root;
    }

/*
 @dev Sets the tier supply and values
*/
    function setTier(uint256[] memory _values) public onlyOwner {
        p_tier_1 = _values[0];
        p_tier_1_supply = _values[1];
        p_tier_2 = _values[2];
        p_tier_2_supply = _values[3];
        p_tier_3 = _values[4];
        p_tier_3_supply = _values[5];
        delete _values;
    }

/*
 @dev Sets mint live
*/
    function setActive(bool _public, bool _wl) external onlyOwner {
        publicActive = _public;
        whitelistActive = _wl;
    }

    function setRevealed() external onlyOwner{
        reveal = !reveal;
    }

/*
 @dev Limits the amount of mints per transaction
*/
    function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
        maxMintAmountPerTx = _maxtx;
    }

    function withdraw() external onlyOwner {
    uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance ); 
        
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}