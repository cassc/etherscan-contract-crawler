// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC721K/ERC721K.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error InsufficientFunds();
error ExceedsMaxSupply();
error OutsideSalePeriod();
error FailedTransfer();
error URIQueryForNonexistentToken();
error UnmatchedLength();
error NoShares();

/// @title ERC721 contract for https://heds.io/ HedsTape
/// @author https://github.com/kadenzipfel
contract HedsTape is ERC721K, Ownable {
  struct SaleConfig {
    uint64 price;
    uint32 maxSupply;
    uint32 startTime;
    uint32 endTime;
  }

  /// @notice NFT sale data
  /// @dev Sale data packed into single storage slot
  SaleConfig public saleConfig;

  string private baseUri = 'ipfs://QmYjnCPqpwaPqWWpxpTxwjQD69S3aPZHuhsL5pYBeh8W3Y';

  address private zeroXSplit = 0x14e444B02b8Fccb7e1AfD3EDD9f64727A65a2B0e;

  constructor() ERC721K("hedsTAPE 9", "HT9") {
    saleConfig.price = 0.1 ether;
    saleConfig.maxSupply = 1000;
    saleConfig.startTime = 1666983585;
    saleConfig.endTime = 1667070000;
  }

  /// @notice Mint a HedsTape token
  /// @param _amount Number of tokens to mint
  function mintHead(uint _amount) external payable {
    SaleConfig memory config = saleConfig;
    uint _price = uint(config.price);
    uint _maxSupply = uint(config.maxSupply);
    uint _startTime = uint(config.startTime);
    uint _endTime = uint(config.endTime);

    if (_amount * _price != msg.value) revert InsufficientFunds();
    if (_currentIndex + _amount > _maxSupply + 1) revert ExceedsMaxSupply();
    if (block.timestamp < _startTime || block.timestamp > _endTime) revert OutsideSalePeriod();

    _safeMint(msg.sender, _amount);
  }
 
  /// @notice Update baseUri - must be contract owner
  function setBaseUri(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  /// @notice Return tokenURI for a given token
  /// @dev Same tokenURI returned for all tokenId's
  function tokenURI(uint _tokenId) public view override returns (string memory) {
    if (0 == _tokenId || _tokenId > _currentIndex - 1) revert URIQueryForNonexistentToken();
    return baseUri;
  }

  /// @notice Update sale start time - must be contract owner
  function updateStartTime(uint32 _startTime) external onlyOwner {
    saleConfig.startTime = _startTime;
  }

  /// @notice Update sale end time - must be contract owner
  function updateEndTime(uint32 _endTime) external onlyOwner {
    saleConfig.endTime = _endTime;
  }

  /// @notice Update max supply - must be contract owner
  function updateMaxSupply(uint32 _maxSupply) external onlyOwner {
    saleConfig.maxSupply = _maxSupply;
  }

  /// @notice Withdraw contract balance - must be contract owner
  function withdraw() external onlyOwner {
    (bool success, ) = payable(zeroXSplit).call{value: address(this).balance}("");
    if (!success) revert FailedTransfer();
  }
}