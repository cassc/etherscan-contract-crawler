// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "ERC721A.sol";
import "OperatorFilterer.sol";
import "Ownable.sol";
import "IERC2981.sol";
import "ERC2981.sol";

contract Gooker is ERC721A, ERC2981, OperatorFilterer, Ownable {
  uint256 private constant supply = 2222;
  uint256 private constant maxTx = 6;
  uint256 private constant mintPrice = 0.002 ether;

  string tokenBaseUri = "ipfs://tba/?";

  bool public paused = true;
  bool public operatorFilteringEnabled = true;

  mapping(address => uint256) private _freeMints;

  constructor(string memory _name, string memory _symbol)
    ERC721A(_name, _symbol)
  {
    _registerForOperatorFiltering();
    _setDefaultRoyalty(msg.sender, 750);
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting paused");

    require(_totalMinted() + _quantity <= supply, "Max supply reached");
    require(_quantity <= maxTx, "Max per transaction is 7");

    uint256 payForCount = _quantity;
    uint256 freeMintCount = _freeMints[msg.sender];

    if (freeMintCount < 1) {
      if (_quantity > 1) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMints[msg.sender] = 1;
    }

    require(msg.value == payForCount * mintPrice, "Incorrect ETH amount");

    _mint(msg.sender, _quantity);
  }

  function getFreeMints(address owner) external view returns (uint256) {
    return _freeMints[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(address operator)
    internal
    pure
    override
    returns (bool)
  {
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    payable
    override(ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function mintAirdrops(uint256 _quantity) external onlyOwner {
    require(totalSupply() == 0, "Airdrops minted");

    _mint(msg.sender, _quantity);
  }

  function airdrop(uint256[] calldata tokenIds, address[] calldata recipients)
    external
    onlyOwner
  {
    uint256 tokenIdsLength = tokenIds.length;

    require(tokenIdsLength == recipients.length, "Mismatch length");

    for (uint256 i = 0; i < tokenIdsLength; ) {
      transferFrom(msg.sender, recipients[i], tokenIds[i]);

      unchecked {
        ++i;
      }
    }
  }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }
}