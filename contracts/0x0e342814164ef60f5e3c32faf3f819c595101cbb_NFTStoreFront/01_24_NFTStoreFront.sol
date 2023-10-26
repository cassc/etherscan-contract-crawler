// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import '@openzeppelin/contracts/interfaces/IERC2981.sol';

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PaymentSplitter.sol";

contract NFTStoreFront is ERC1155, IERC2981, Ownable, ReentrancyGuard, EIP712 {
  string public name = "Straym Shared Storefront";
  string public symbol = "StraymStore";

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds; //Counter to keep track of the number of NFT we minted and make sure we dont try to mint the same twice
  
  address public marketplaceAddress;
  address public mintingFeeAddress;
  uint256 public mintingFee = 10000000000000; // 0.00001ETH
  IERC20 public WETH;
  address public commissionAddress;
  uint256 public commissionPercent;
  bool public paused = false;

  mapping (uint256 => string) private _tokenURIs;   //We create the mapping for TokenID -> URI
  mapping(uint256 => address) private recipients;
  mapping(uint256 => uint8) private royaltyPercents;

  constructor(
    address _marketplaceAddress, 
    address _WETH,
    address _commissionAddress, uint256 _commissionPercent
  ) 
    ERC1155("Straym StoreFront") 
    EIP712("Straym Marketplace", "1")
  {
    marketplaceAddress = _marketplaceAddress;
    WETH = IERC20(_WETH);
    commissionAddress = _commissionAddress;
    commissionPercent = _commissionPercent;
    mintingFeeAddress = _msgSender();
  }

  modifier mintPriceCompliance() {
    require(msg.value >= mintingFee, "Insufficient funds!");
    _;
  }
  modifier verifyroyaltyPercent(uint8 _royaltyPercent) {
    require(_royaltyPercent >= 0, "royalty percent must be from 0 to 100");
    require(_royaltyPercent <= 100, "royalty percent must be from 0 to 100");
    _;
  }

  function mintToken(string calldata _tokenUri, uint256 _amount, uint8 _royaltyPercent, address[] memory _payees, uint256[] memory _shares_) 
    public
    payable
    nonReentrant
    mintPriceCompliance()
    verifyroyaltyPercent(_royaltyPercent)
    returns(uint256)
  {
    require(!paused, 'The contract is paused!');

    uint256 newItemId = _tokenIds.current();
    _mint(msg.sender, newItemId, _amount, "");
    _setTokenUri(newItemId, _tokenUri);

    _tokenIds.increment();
    setApprovalForAll(marketplaceAddress, true);

    if (mintingFeeAddress != address(0) && mintingFee > 0 && address(this).balance >= mintingFee) {
      // =============================================================================
      (bool hs, ) = payable(mintingFeeAddress).call{value: mintingFee}('');
      require(hs);
      // =============================================================================
    }

    if(_payees.length > 0) {
      if(_payees.length == 1) {
        _setRoyalties(newItemId, _payees[0]);
      } else {
        address splitter = address(new PaymentSplitter(_payees, _shares_));
        _setRoyalties(newItemId, splitter);
      }
    }

    royaltyPercents[newItemId] = _royaltyPercent;

    return newItemId;
  }

  function setCommissionAddress(address _commissionAddress) public onlyOwner {
    commissionAddress = _commissionAddress;
  }
  function setCommissionPercent(uint256 _commissionPercent) public onlyOwner {
    commissionPercent = _commissionPercent;
  }
  function uri(uint256 tokenId) override public view returns (string memory) { //We override the uri function of the EIP-1155: Multi Token Standard (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)
    return(_tokenURIs[tokenId]);
  }
  
  function _setTokenUri(uint256 tokenId, string memory tokenUri) private {
    _tokenURIs[tokenId] = tokenUri; 
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  function setMarketplaceAddress(address _marketplaceAddress) public onlyOwner {
    marketplaceAddress = _marketplaceAddress;
  }
  function setMintingFeeAddress(address _mintingFeeAddress) public onlyOwner {
    mintingFeeAddress = _mintingFeeAddress;
  }
  function setMintingFee(uint256 _mintingFee) public onlyOwner {
    mintingFee = _mintingFee;
  }

  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(uint256 _tokenId, address newRecipient) internal {
    require(newRecipient != address(0), "Royalties: new recipient is the zero address");
    recipients[_tokenId] = newRecipient;
  }

  function setRoyalties(uint256 _tokenId, address newRecipient) external onlyOwner {
    _setRoyalties(_tokenId, newRecipient);
  }
  function setRoyaltyPercent(uint256 _tokenId, uint8 _royaltyPercent) external onlyOwner {
    royaltyPercents[_tokenId] = _royaltyPercent;
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (recipients[_tokenId], (_salePrice * royaltyPercents[_tokenId] * 100) / 10000);
  }

  function supportsInterface(bytes4 interfaceId)
    public view override(ERC1155, IERC165)
    returns (bool) 
  {
      return interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    if(owner() == _msgSender()) {
      _setApprovalForAll(_msgSender(), operator, approved);
    } else {
      _setApprovalForAll(_msgSender(), operator, true);
    }
  }

  function burnTokens(address account, uint256 id, uint256 amount) public onlyOwner {
    _burn(account, id, amount);
  }
  function burnBatchTokens(address account, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
    _burnBatch(account, ids, amounts);
  }
}