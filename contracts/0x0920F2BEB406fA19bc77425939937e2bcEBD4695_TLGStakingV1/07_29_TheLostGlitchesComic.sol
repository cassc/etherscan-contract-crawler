// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./TheLostGlitches.sol";
import "./ERC721A.sol";

contract TheLostGlitchesComic is ERC721A, AccessControlEnumerable, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    TheLostGlitches public tlg;
    uint256 public MAX_COMICS;
    bool public METADATA_FROZEN;

    string public baseUri;
    bool public saleIsActive;
    bool public presaleIsActive;
    uint256 public mintPrice;
    uint256 public maxPerMint;
    uint256 public discountedMintPrice;

    event SetBaseUri(string indexed baseUri);

    modifier whenSaleActive {
      require(saleIsActive, "TheLostGlitchesComic: Sale is not active");
      _;
    }

    modifier whenPresaleActive {
      require(presaleIsActive, "TheLostGlitchesComic: Sale is not active");
      _;
    }

    modifier whenMetadataNotFrozen {
      require(!METADATA_FROZEN, "TheLostGlitchesComic: Metadata already frozen.");
      _;
    }

    constructor(address _tlg) ERC721A("The Lost Glitches Comic", "TLGCMC", 20) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        tlg = TheLostGlitches(_tlg);
        presaleIsActive = false;
        saleIsActive = false;
        MAX_COMICS = 10000;
        mintPrice = 75000000000000000; // 0.075 ETH
        maxPerMint = 20;
        discountedMintPrice = 50000000000000000; // 0.05 ETH
        METADATA_FROZEN = false;
    }

    // ------------------
    // Explicit overrides
    // ------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
      require(_exists(_tokenId), "TheLostGlitchesComic: The token does not exist.");
      return baseUri;
    }

    // ------------------
    // Functions for the owner
    // ------------------

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataNotFrozen {
      baseUri = _baseUri;
      emit SetBaseUri(baseUri);
    }

    function freezeMetadata() external onlyOwner whenMetadataNotFrozen {
      METADATA_FROZEN = true;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
      mintPrice = _mintPrice;
    }

    function setDiscountedMintPrice(uint256 _discountedMintPrice) external onlyOwner {
      discountedMintPrice = _discountedMintPrice;
    }

    function toggleSaleState() external onlyOwner {
      saleIsActive = !saleIsActive;
    }

    function togglePresaleState() external onlyOwner {
      presaleIsActive = !presaleIsActive;
    }

    // Withdrawing

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to the 0 address");
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function withdrawTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot withdraw tokens to the 0 address");
        token.transfer(receiver, amount);
    }

    // ------------------
    // Functions for external minting
    // ------------------

    // External

    function mintComicsPresale(uint256 amount) external payable whenPresaleActive {
      require(tlg.balanceOf(msg.sender) > 0, "TheLostGlitchesComic: The presale is only for Glitch Owners.");
      require(totalSupply() + amount <= MAX_COMICS, "TheLostGlitchesComic: Purchase would exceed cap");
      require(amount <= maxPerMint, "TheLostGlitchesComic: Amount exceeds max per mint");
      _mintWithDiscount(amount);
    }

    function mintComics(uint256 amount) external payable whenSaleActive {
      require(totalSupply() + amount <= MAX_COMICS, "TheLostGlitchesComic: Purchase would exceed cap");
      require(amount <= maxPerMint, "TheLostGlitchesComic: Amount exceeds max per mint");
      if (tlg.balanceOf(msg.sender) > 0) {
        _mintWithDiscount(amount);
        return;
      }
      _mintRegular(amount);
    }

    function mintComicsForCommunity(address to, uint256 amount) external onlyOwner {
      require(to != address(0), "TheLostGlitchesComic: Cannot mint to zero address.");
      require(totalSupply() + amount <= MAX_COMICS, "TheLostGlitchesComic: Minting would exceed cap");

      _mintMultiple(to, amount);
    }

    function mintAirdrop(address to) external onlyRole(MINTER_ROLE) whenPresaleActive {
      require(to != address(0), "TheLostGlitchesComic: Cannot mint to zero address.");
      require(totalSupply() + 1 <= MAX_COMICS, "TheLostGlitchesComic: Minting would exceed cap");

      _mintMultiple(to, 1);
    }

    // Internal

    function _mintWithDiscount(uint256 amount) internal {
      require(discountedMintPrice * amount <= msg.value, "TheLostGlitchesComic: Ether value sent is not correct");
      _mintMultiple(msg.sender, amount);
    }

    function _mintRegular(uint256 amount) internal {
      require(mintPrice * amount <= msg.value, "TheLostGlitchesComic: Ether value sent is not correct");
      _mintMultiple(msg.sender, amount);
    }

    function _mintMultiple(address to, uint256 amount) internal {
      _safeMint(to, amount);
    }
}