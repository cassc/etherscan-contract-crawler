// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
⠀⠀⠀⣤⣴⣾⣿⣿⣿⣿⣿⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡄
⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⢰⣦⣄⣀⣀⣠⣴⣾⣿⠃
⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⠀
⠀⠀⣼⣿⡿⠿⠛⠻⠿⣿⣿⡇⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀
⠀⠀⠉⠀⠀⠀⢀⠀⠀⠀⠈⠁⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀
⠀⠀⣠⣴⣶⣿⣿⣿⣷⣶⣤⠀⠀⠀⠈⠉⠛⠛⠛⠉⠉⠀⠀⠀
⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⣶⣦⣄⣀⣀⣀⣤⣤⣶⠀⠀
⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀
⢠⣿⡿⠿⠛⠉⠉⠉⠛⠿⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀
⠘⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⢿⣿⣿⣿⣿⣿⠿⠛⠀

*/
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Weendows69 is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer  {
  uint256 public maxSupply =      1985;
  uint256 public maxPerWallet =   3;
  uint256 public cost =           0.0069 ether;
  bool public    sale =           false;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error NotEnoughETH();
  error NoContractMint();

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) {
    baseURI = "ipfs://bafybeibnski3tl3c6mmeylnrxytbvxfrf3mz2bjpscjzyyziofgiocffqq";
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }
  
  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  string public baseURI;

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function toggleSale(bool _toggle) external onlyOwner {
    sale = _toggle;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = _msgSenderERC721A().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function mintWeendows(uint256 _amount) external payable {
    if (tx.origin != _msgSenderERC721A()) revert NoContractMint();
    if (!sale) revert SaleNotActive();
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (_numberMinted(_msgSenderERC721A()) + _amount > maxPerWallet) revert MaxPerWalletReached();
    if (msg.value < cost * _amount) revert NotEnoughETH();

    _mint(_msgSenderERC721A(), _amount);
  }

  function ownerMint(uint256 _amount, address _to) external onlyOwner {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(_to, _amount);
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  //override
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

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
  }
}