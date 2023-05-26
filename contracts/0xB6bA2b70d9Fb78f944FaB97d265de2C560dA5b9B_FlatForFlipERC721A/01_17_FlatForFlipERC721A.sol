// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlatForFlipERC721A.sol";
import "hardhat/console.sol";

import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";


contract FlatForFlipERC721A is ERC721A, IFlatForFlipERC721A, Ownable, RoyaltiesV2Impl {
  uint16 public constant MAX_TOKEN_MINT = 7777;

  uint256 internal _salesEndPeriod;

  address public minter;

  string public customBaseURI;

  event Minter(address newMinter);
  event UpdateSalesEndPeriod( uint256 indexed newSalesEndPeriod);  
 
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 salesEnd, 
    address _royaltyReceiver, 
    uint96 _royaltiesPercentageBasisPoints
  ) ERC721A(_name, _symbol){

    require(_royaltyReceiver != address(0), "Not a valid token address");
    require(_royaltiesPercentageBasisPoints <= 10000, "Royalty percentage can not be greater than 10000");
    require(salesEnd > block.timestamp, "Distribution date is in the past");

    royaltyReceiver = _royaltyReceiver;

    royaltiesPercentageBasisPoints = _royaltiesPercentageBasisPoints;

    _salesEndPeriod = salesEnd;

  }

  modifier onlyFlatForFlipICOContract {
    require(minter == msg.sender, "Only FlatForFlipICO contract can mint or burn token");
    _;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override virtual {

    super._beforeTokenTransfers(from, to, startTokenId, quantity);

    // // Checking that it is actually the transfer is called not mint
    if (from != address(0) && block.timestamp < _salesEndPeriod) {
      revert("Can not make transfer until the sales end period is over");
    }

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function salesEndPeriod() external view virtual override returns (uint256) {
    return _salesEndPeriod;
  }

  function safeMint(address to, uint256 numOfTokenPurchased) external override onlyFlatForFlipICOContract {
    uint256 numOfTokenBeforePurchase = _totalMinted();

    require((numOfTokenBeforePurchase + numOfTokenPurchased) <= MAX_TOKEN_MINT, "The amount of token you want to purchase plus the total token minted exceed the total unknown token");

    _safeMint(to, numOfTokenPurchased);

    uint256 id = numOfTokenBeforePurchase;
  
    for (uint256 i = 0; i < numOfTokenPurchased; i++) {
      id++;
      _originalTokenOwners[id] = to;
    }

  }

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function setTokenMinter(address newMinter) external onlyOwner {
    require(newMinter != address(0), "Invalid address");
    minter = newMinter;
    emit Minter(newMinter);
  }

  function updateSalesEndPeriod(uint256 newSalesEndPeriod) external onlyOwner{
    require(newSalesEndPeriod > block.timestamp, "New sale end period is in the past");
    _salesEndPeriod = newSalesEndPeriod;
    emit UpdateSalesEndPeriod(newSalesEndPeriod);
  } 

  function updateRoyaltyReceiver(address newRoyaltyReceiver) external onlyOwner{
    require(newRoyaltyReceiver != address(0), "Not a valid token address");

    _updateRoyaltyReceiver(newRoyaltyReceiver);
  } 

  function updateRoyaltyShare(uint96 percentageBasisPoints) external onlyOwner{
    require(percentageBasisPoints <= 10000, 'New royalty percentage is too high');

    _updateRoyaltyShare(percentageBasisPoints);
  } 

  function getOriginalTokenOwners(uint256 tokenId) external view returns(address) {
    return _originalTokenOwners[tokenId];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
    if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

}