// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

/* If you here to read this - GM */ 
contract FourKPunks is ERC721, Ownable, Pausable, ReentrancyGuard, IERC2981, DefaultOperatorFilterer {
  using Strings for uint256;

  enum SaleState { SaleClosed, OGPhase, WLPhase, PublicPhase }

  uint256 public totalSupply = 0;
  uint256 public teamAllocation = 30;
  uint256 public maxTotalSupply = 4444;
  uint256 public ogFreeMax = 2;
  uint256 public mintLimit = 10;
  uint256 public maxPerWallet = 44;

  uint256 public ogFreeRemaining = 444;
  uint256 public wlSupplyRemaining = 1600;
  uint256 public freeMintCount = 0;

  uint256 public wlMintPrice = 0.00444 ether;
  uint256 public publicMintPrice = 0.0069 ether;

  SaleState public saleState;

  string private _baseTokenURI = "https://api-dot-punks4k.oa.r.appspot.com/metadata/token";
  string private _contractURI = "https://api-dot-punks4k.oa.r.appspot.com/metadata/contract";

  bytes32 private ogMerkleRoot = 0x3b748a2c09ca6c8b7b79e4d8068bc9412d279e948fcae3dfba878a294d94d6d2;
  bytes32 private wlMerkleRoot = 0x43478013e7be0ae4fca324e608c565eb4b36ec48072e7620baa1f78286c9b32b;

  address private vaultAddress = address(0);
  uint256 public royaltyPercentage = 5;

  mapping(address => uint256) public paidMintsPerWallet;
  mapping(address => uint256) public freeMintsPerWallet;

 /* --
  Events
  -- */
  event Minted(address indexed to, uint256 indexed tokenId);
  event TeamMinted(address indexed to, uint256 amount);
  event PhaseOpenAnnouncement(string phase);
  event Burnt4k(address indexed burner, uint256 indexed tokenId);
  event MerkleRootsUpdated(bytes32 indexed ogMerkleRoot, bytes32 indexed wlMerkleRoot);
  event VaultAddressUpdated(address indexed newVaultAddress);
  event Withdrawn(address indexed to, uint256 amount);

  /* --
  Modifiers
  -- */
  modifier noContracts() {
    require(!isContract(msg.sender), "Only Humans allowed");
    _;
  }

  function isContract(address _addr) private view returns (bool) {
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  /* --
  OVERRIDES
  -- */

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
    super.transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
    super.safeTransferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    vaultAddress = msg.sender;
  }

  /* ---- OGS Claim ---- */
  /* Thank you for supporting us early - we want to return the love */
  function OGClaimMint(
    bytes32[] memory _whitelistProof
  ) external whenNotPaused nonReentrant noContracts {
    
    require(saleState == SaleState.OGPhase, "Not open yet");

    /* Merkle Verify */
    require(MerkleProof.verify(_whitelistProof, ogMerkleRoot, keccak256(abi.encodePacked(_msgSender()))), "Not OG");

    /* Check all requirements are passed */
    require(ogFreeRemaining > 0, "OG Phase is sold out");
    require(freeMintsPerWallet[_msgSender()] != ogFreeMax, "Exceeds max");

    freeMintsPerWallet[_msgSender()] = ogFreeMax;

    freeMintCount = freeMintCount + 2;
    ogFreeRemaining = ogFreeRemaining - 2;
    totalSupply++;

    /* Automatically bless them with 2 */
    /* FREE FREE - who doesnt love free - GMI */
    _safeMint(_msgSender(), totalSupply);
    emit Minted(_msgSender(), totalSupply);

    totalSupply++;
    _safeMint(_msgSender(), totalSupply);
    emit Minted(_msgSender(), totalSupply);

    if (ogFreeRemaining == 0) {
      saleState = SaleState.WLPhase;
      emit PhaseOpenAnnouncement("WL Sale open");
    }
  }

 function mintWhitelist(
   uint256 _amount 
   , bytes32[] memory _whitelistProof
  ) internal {

    /* Merkle Verify */
    require(MerkleProof.verify(_whitelistProof, wlMerkleRoot, keccak256(abi.encodePacked(_msgSender()))), "Not WL");
    require(wlSupplyRemaining > 0, "No more WL"); 

    uint256 walletCount = paidMintsPerWallet[_msgSender()];
    uint256 walletFreeCount = freeMintsPerWallet[_msgSender()];
    uint256 toMint = _amount > wlSupplyRemaining ? wlSupplyRemaining : _amount;
    uint256 minted = 0;
    bool freeMintApplies = walletFreeCount == 0 ? true : false;

    if(freeMintApplies){
      freeMintsPerWallet[_msgSender()] = 1;
      toMint--;
      wlSupplyRemaining--;

      totalSupply++;
      /* Give them what they came for - FREE 4k Punk */
      _safeMint(_msgSender(), totalSupply);
      emit Minted(_msgSender(), totalSupply);
    } 
    require(toMint <= mintLimit, "Too many");
    require(walletCount + 1 < mintLimit, "You have no more mints");

    require(msg.value == wlMintPrice * toMint, "Ether value sent is not correct");

    /* Mint time ... baby ... GMI */
    for (uint256 i = 0; i < toMint; i++) {
      minted++;
      wlSupplyRemaining--;
      totalSupply++;
      _safeMint(_msgSender(), totalSupply);
      emit Minted(_msgSender(), totalSupply);
    }

    paidMintsPerWallet[_msgSender()] += minted;

    /* Automatically flip to public phase once wlSupply is 0 */
    if (wlSupplyRemaining == 0) {
      saleState = SaleState.PublicPhase;
      emit PhaseOpenAnnouncement("Public Sale open");
    }
  }

  function mintPublic(uint256 _amount) internal {

    /* Pretty standard stuff here */
    require(totalSupply + _amount <= maxTotalSupply, "Exceeds max total supply");
    require(_amount <= maxPerWallet, "Exceeding max");
    require(msg.value == publicMintPrice * _amount, "Ether value sent is not correct");
    require(this.balanceOf(msg.sender) <= maxPerWallet);

    uint256 minted = 0;

    /* mint loop */
    for (uint256 i = 0; i < _amount; i++) {
      minted++;
      totalSupply++;
      _safeMint(_msgSender(), totalSupply);
      emit Minted(_msgSender(), totalSupply);
    }

    paidMintsPerWallet[_msgSender()] += minted;

    /* Lets not keep anyone waiting -- once supply reaches maxTotalSupply - close sale */
    if(totalSupply == maxTotalSupply){
      saleState = SaleState.SaleClosed;
    }
  }

  /* Use one mint function for both WL and Public phases */
  function mint(
    uint256 _amount
    , bytes32[] memory _whitelistProof
  ) external whenNotPaused payable nonReentrant noContracts {
    require(_amount > 0, "Must mint at least one");
    /* Whitelisted Wallets go first */
    if (saleState == SaleState.WLPhase) {
      require(
        saleState == SaleState.WLPhase 
        || _whitelistProof.length > 0
        , "Whitelist proof required for WLPhase");
      mintWhitelist(
        _amount
        , _whitelistProof
      );
    } else {
      require(saleState == SaleState.PublicPhase, "Sale not open");
      mintPublic(_amount);
    }
  }

  /* This will be for the next part of the 4k's journey -- more to come */
  /* shhhhhh - we did say no roadmap didnt we? */
  function burn(uint256 tokenId) public whenNotPaused {
    require(_msgSender() == ownerOf(tokenId), "Only token owner can burn tokens");
    _burn(tokenId);
    emit Burnt4k(msg.sender, tokenId);
  }

  function teamMint() external onlyOwner {
    for (uint256 j = 0; j < teamAllocation; j++) {
      require(totalSupply + 1 <= maxTotalSupply, "Exceeds max total supply");
      totalSupply++;
      _safeMint(vaultAddress, totalSupply);
    }
    emit TeamMinted(vaultAddress, teamAllocation);
  }

  /* incase a pause is needed */
  function togglePause() external onlyOwner {
    if (paused()) {
        _unpause();
    } else {
        _pause();
    }
  }

  function toggleSaleState() external onlyOwner {
    if (saleState == SaleState.SaleClosed) {
      saleState = SaleState.OGPhase;
      emit PhaseOpenAnnouncement("OG Sale open");
    } else {
      saleState = SaleState.SaleClosed;
    }
  }

  function toggleOGPhase() external onlyOwner {
    saleState = SaleState.OGPhase;
    emit PhaseOpenAnnouncement("OG Sale open");
  }

  function toggleWLPhase() external onlyOwner {
    saleState = SaleState.WLPhase;
    emit PhaseOpenAnnouncement("WL Sale open");
  }

  function togglePublicPhase() external onlyOwner {
    saleState = SaleState.PublicPhase;
    emit PhaseOpenAnnouncement("Public Sale open");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
    _baseTokenURI = newBaseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString())) : '';
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory newContractURI) public onlyOwner {
    _contractURI = newContractURI;
  }

  function setPublicMintPrice(uint256 _newPrice) public onlyOwner {
    publicMintPrice = _newPrice;
  }

  function setMerkleRoots(bytes32 _ogMerkleRoot, bytes32 _wlMerkleRoot) external onlyOwner {
    ogMerkleRoot = _ogMerkleRoot;
    wlMerkleRoot = _wlMerkleRoot;
    emit MerkleRootsUpdated(_ogMerkleRoot, _wlMerkleRoot);
  }

  function setVaultAddress(address _newVaultAddress) external onlyOwner {
    vaultAddress = _newVaultAddress;
    emit VaultAddressUpdated(_newVaultAddress);
  }

  function withdraw() external onlyOwner {
    require(vaultAddress != address(0), "Vault address not set");

    uint256 contractBalance = address(this).balance;
    payable(vaultAddress).transfer(contractBalance);
    emit Withdrawn(vaultAddress, contractBalance);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(_tokenId), "Token does not exist");
    receiver = owner();
    royaltyAmount = (_salePrice * royaltyPercentage) / 100;
  }
}