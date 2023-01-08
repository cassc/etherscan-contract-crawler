// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "./PaymentMinimum.sol";

//    __                 _             _        
//   / _|               | |           (_)       
//  | |_    ___    ___  | |_   _ __    _  __  __
//  |  _|  / _ \  / _ \ | __| | '_ \  | | \ \/ /
//  | |   |  __/ |  __/ | |_  | |_) | | |  >  < 
//  |_|    \___|  \___|  \__| | .__/  |_| /_/\_\
//                            | |               
//                            |_|               

contract Feetpix is ERC721A, Ownable, PaymentMinimum, OperatorFilterer {
  /** Maximum number of tokens per wallet */
  uint256 public constant MAX_WALLET = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 10000;
  /** Price per token */
  uint256 public cost = 0.0039 ether;
  /** Max free */
  uint256 public free = 7000;
  /** Base URI */
  string public baseURI;
  /** Burn service */
  address public authorizedOperator;

  /** Whitelist max per wallet */
  uint256 public constant MAX_PER_WHITELIST = 10;

  /** Public sale state */
  bool public saleActive = false;
  /** Presale state */
  bool public presaleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on presale state change */
  event PresaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  constructor(
    string memory _name, 
    string memory _symbol,
    uint256 _minimum,
    address _builder,
    address[] memory _shareholders, 
    uint256[] memory _shares
  )
    ERC721A(_name, _symbol) 
    PaymentMinimum(_minimum, _builder, _shareholders, _shares) 
    OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {}

  /// @notice Returns the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Gets cost to mint n amount of NFTs, taking account for first one free
  /// @param _numberMinted How many a given wallet has already minted
  /// @param _numberToMint How many a given wallet is planning to mint
  /// @param _costPerMint Price of one nft
  function subtotal(uint256 _numberMinted, uint256 _numberToMint, uint256 _costPerMint) public pure returns (uint256) {
    return _numberToMint * _costPerMint - (_numberMinted > 0 ? 0 : _costPerMint);
  }

  /// @notice Gets number of NFTs minted for a given wallet
  /// @param _wallet Wallet to check
  function numberMinted(address _wallet) external view returns (uint256) {
    return _numberMinted(_wallet);
  }

  /// @notice Sets public sale state
  /// @param _val New sale state
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets presale state
  /// @param _val New presale state
  function setPresaleState(bool _val) external onlyOwner {
    presaleActive = _val;
    emit PresaleStateChanged(_val);
  }

  /// @notice Sets the price
  /// @param _val New price
  function setCost(uint256 _val) external onlyOwner {
    cost = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string calldata _val) external onlyOwner {
    baseURI = _val;
  }

  /// @notice Sets the authorized operator
  /// @param _val The new operator
  /// @dev Allows staking service to transfer nfts
  function setAuthorizedOperator(address _val) external onlyOwner {
    authorizedOperator = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    require(free >= _amt, "Cannot exceed free mint limit.");
    free -= _amt;
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in presale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function preMint(uint256 _amt) external payable {
    require(presaleActive, "Presale is not active.");
    require(_amt <= MAX_PER_WHITELIST, "Amount of tokens exceeds transaction limit.");
    require(_amt <= free, "Amount exceeds supply.");
    require(subtotal(_numberMinted(msg.sender), _amt, cost - 0.0019 ether) == msg.value, "ETH sent not equal to cost.");
    require(free > 0, "Presale has ended.");
    
    free -= _amt;
    // Switch to public once all free mints are gone
    if (free == 0) { presaleActive = false; saleActive = true; }
    
    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    require(saleActive, "Sale is not active.");
    require(_amt <= MAX_WALLET, "Amount of tokens exceeds transaction limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _amt == msg.value, "ETH sent not equal to cost.");

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @dev Override to use filter operator
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  /// @dev We give the staking/other service direct access as a convenience to the consumer (one less transaction, gas)
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    if (authorizedOperator != _msgSender()) {
      require(from == _msgSenderERC721A() || isApprovedForAll(from, _msgSenderERC721A()), "ERC721A: transfer caller is not owner nor approved");
    }
    super.safeTransferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  /// @dev We give the staking/other service direct access as a convenience to the consumer (one less transaction, gas)
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    if (authorizedOperator != _msgSender()) {
      require(from == _msgSenderERC721A() || isApprovedForAll(from, _msgSenderERC721A()), "ERC721A: transfer caller is not owner nor approved");
    }
    super.safeTransferFrom(from, to, tokenId, data);
  }
}