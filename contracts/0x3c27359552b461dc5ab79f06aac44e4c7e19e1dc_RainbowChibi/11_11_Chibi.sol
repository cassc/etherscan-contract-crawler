//// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
 
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract RainbowChibi is ERC721A, Ownable, DefaultOperatorFilterer {


  error MintInactive();
  error ContractCaller();
  error ExceedsWalletMax();
  error ExceedsSupply();
  error InvalidValue();
  error LengthsDoNotMatch();
  error InvalidToken();
  error NotTokenOwner();
  error TokenHasMinted(uint256 tokenId);

  using Strings for uint256;

  IERC721A public Hiroko;

  string public baseURI;

  uint256 public price = 0.003 ether;
  uint256 public constant MAX_SUPPLY = 444;
  uint256 public constant MAX_PER_WALLET = 5;

  bool public holderSaleActive = false;
  bool public saleActive = false;

  mapping(uint256 => bool) hirokoTokenHasMinted;

  constructor(address hirokoAddress) ERC721A("Rainbow Chibi", "Rainbow Chibi") {
    _mint(msg.sender, 1);
    Hiroko = IERC721A(hirokoAddress);
  }

  function holderMint(uint256[] calldata hirokoTokenIdsHeld) public payable {
    if (!holderSaleActive) revert MintInactive();
    if (msg.sender != tx.origin) revert ContractCaller();
    uint256 length = hirokoTokenIdsHeld.length;
    unchecked {
      if (length + totalSupply() > MAX_SUPPLY) revert ExceedsSupply();
      for (uint256 i = 0; i < length; i++) {
        if (hirokoTokenHasMinted[hirokoTokenIdsHeld[i]]) revert TokenHasMinted(hirokoTokenIdsHeld[i]);
        if (Hiroko.ownerOf(hirokoTokenIdsHeld[i]) != msg.sender) revert NotTokenOwner();
        hirokoTokenHasMinted[hirokoTokenIdsHeld[i]] = true;
      }
    }
    _mint(msg.sender, length);
  }

  function mint(uint256 mintAmount_) public payable {
    if (!saleActive) revert MintInactive();
    if (msg.sender != tx.origin) revert ContractCaller();
    unchecked {
      if (balanceOf(msg.sender) + mintAmount_ > MAX_PER_WALLET) revert ExceedsWalletMax();
      if (mintAmount_ + totalSupply() > MAX_SUPPLY) revert ExceedsSupply();
      if (msg.value != mintAmount_ * price) revert InvalidValue();
    }
    _mint(msg.sender, mintAmount_);
  }

  function mintForAddress(uint256 mintAmount_, address to_) external onlyOwner {
    _mint(to_, mintAmount_);
  }

  function batchMintForAddresses(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
    if (addresses_.length != amounts_.length) revert LengthsDoNotMatch();
    unchecked {
      for (uint32 i = 0; i < addresses_.length; i++) {
        _mint(addresses_[i], amounts_[i]);
      }
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function flipSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function flipHolderSale() external onlyOwner {
    holderSaleActive = !holderSaleActive;
  }

  function setPrice(uint256 price_) external onlyOwner {
    price = price_;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setBaseURI(string memory newBaseURI_) external onlyOwner {
    baseURI = newBaseURI_;
  }

  function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
    if (!_exists(tokenId_)) revert InvalidToken();
    return string(abi.encodePacked(baseURI, tokenId_.toString(), ".json"));
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from){
    super.safeTransferFrom(from, to, tokenId, data);
  }

}