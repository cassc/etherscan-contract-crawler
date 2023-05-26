// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import { ERC721, ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { Ownable } from "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

/**
 * @title PoolTogether Inc. Pooly NFT
 * @notice NFT to help PoolTogether Inc. raise funds that will be used to cover cost of the legal fees.
 */
contract PoolyNFT is ERC721Royalty, Ownable {
  /**
   * @notice Emitted when the NFT is initialized.
   * @param name Name of the NFT collection
   * @param symbol Symbol of the NFT collection
   * @param nftPrice NFT price in ETH
   * @param maxNFT Max number of NFTs available in this collection
   * @param maxMint Max number of NFTs that can be minted in a single transaction
   * @param startTimestamp Timestamp at which the NFT sale starts
   * @param endTimestamp Timestamp at which the NFT sale ends
   * @param owner Address of the contract owner
   */
  event NFTInitialized(
    string name,
    string symbol,
    uint128 nftPrice,
    uint32 maxNFT,
    uint32 maxMint,
    uint32 startTimestamp,
    uint32 endTimestamp,
    address owner
  );

  /**
   * @notice Emitted when one or more NFTs are minted.
   * @param to Address who received the minted NFTs
   * @param numberOfTokens Number of NFTs minted
   * @param amount Amount of ETH received
   */
  event NFTMinted(address indexed to, uint256 numberOfTokens, uint256 amount);

  /**
   * @notice Emitted when royalty fee has been set.
   * @param owner Address of the caller. Owner of this contract.
   * @param recipient Address to whom the royalty fee will be paid
   * @param fee Fee expressed in basis points
   */
  event RoyaltyFeeSet(address indexed owner, address indexed recipient, uint96 fee);

  /**
   * @notice Emitted when ETH are withdrawn from the contract.
   * @param owner Address of the caller and recipient. Owner of this contract.
   * @param amount Amount of ETH withdrawn
   */
  event Withdrawn(address indexed owner, uint256 amount);

  /* ============ Variables ============ */

  /// @notice NFT price in ETH
  uint128 public immutable nftPrice;

  /// @notice Max number of NFTs available in this collection
  uint32 public immutable maxNFT;

  /// @notice Max number of NFTs that can be minted in a single transaction
  uint32 public immutable maxMint;

  /// @notice Timestamp at which the NFTs will be available for minting
  uint32 public immutable startTimestamp;

  /// @notice Timestamp at which the NFTs will be unavailable for minting
  uint32 public immutable endTimestamp;

  /// @notice Total supply of NFTs
  uint256 public totalSupply;

  /// @notice NFT tokens base URI
  string public baseURI;

  /* ============ Constructor ============ */

  /**
   * @notice Initializes the NFT contract
   * @param _name NFT collection name
   * @param _symbol NFT collection symbol
   * @param _nftPrice NFT price in ETH
   * @param _maxNFT Max number of NFTs available in this collection
   * @param _maxMint Max number of NFTs that can be minted in a single transaction
   * @param _startTimestamp Timestamp at which the NFT sale will start
   * @param _endTimestamp Timestamp at which the NFT sale will end
   * @param _owner Owner of this contract
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint128 _nftPrice,
    uint32 _maxNFT,
    uint32 _maxMint,
    uint32 _startTimestamp,
    uint32 _endTimestamp,
    address _owner
  ) ERC721(_name, _symbol) Ownable(_owner) {
    require(_owner != address(0), "PTNFT/owner-not-zero-address");
    require(_nftPrice > 0, "PTNFT/price-gt-zero");
    require(_maxNFT > 0, "PTNFT/max-nft-gt-zero");
    require(_maxMint > 0, "PTNFT/max-mint-gt-zero");
    require(_startTimestamp > block.timestamp, "PTNFT/startTimestamp-gt-block");
    require(_endTimestamp > _startTimestamp, "PTNFT/endTimestamp-gt-start");

    nftPrice = _nftPrice;
    maxNFT = _maxNFT;
    maxMint = _maxMint;
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;

    emit NFTInitialized(
      _name,
      _symbol,
      _nftPrice,
      _maxNFT,
      _maxMint,
      _startTimestamp,
      _endTimestamp,
      _owner
    );
  }

  /* ============ External Functions ============ */

  /**
   * @notice Mints a new number of NFTs.
   * @param _numberOfTokens Number of NFTs to mint
   */
  function mintNFT(uint256 _numberOfTokens) external payable {
    uint256 _currentTimestamp = block.timestamp;

    require(
      _currentTimestamp >= startTimestamp && _currentTimestamp < endTimestamp,
      "PTNFT/sale-inactive"
    );

    uint256 _totalSupply = totalSupply;

    require(_totalSupply + _numberOfTokens <= maxNFT, "PTNFT/nfts-sold-out");
    require(_numberOfTokens <= maxMint, "PTNFT/exceeds-max-mint");

    uint256 _amount = _numberOfTokens * nftPrice;
    require(_amount == msg.value, "PTNFT/insufficient-funds");

    for (uint256 index; index < _numberOfTokens; index++) {
      uint256 _mintIndex = _totalSupply + index;

      if (_mintIndex < maxNFT) {
        _safeMint(msg.sender, _mintIndex);
      }
    }

    totalSupply = _totalSupply + _numberOfTokens;

    emit NFTMinted(msg.sender, _numberOfTokens, _amount);
  }

  /**
   * @notice Set NFT tokens base URI
   * @dev This function is only callable by the owner of the contract.
   * @param baseURI_ NFT tokens base URI
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  /**
   * @notice Sets the royalty fee that all ids in this contract will default to.
   * @dev Fees are expressed in basis points. For example: 1000 = 10%
   * @param _recipient Address to whom the royalty fee will be paid
   * @param _fee Percentage of the secondary sales that will be paid to the `_recipient`
   */
  function setRoyaltyFee(address _recipient, uint96 _fee) external onlyOwner {
    _setDefaultRoyalty(_recipient, _fee);

    emit RoyaltyFeeSet(msg.sender, _recipient, _fee);
  }

  /**
   * @notice Withdraw ETH from the contract.
   * @dev This function is only callable by the owner of the contract.
   * @param _amount Amount of ETH to withdraw
   */
  function withdraw(uint256 _amount) external onlyOwner {
    require(_amount > 0, "PTNFT/withdraw-amount-gt-zero");

    (bool _success, ) = msg.sender.call{ value: _amount }("");

    require(_success, "PTNFT/failed-to-withdraw-eth");

    emit Withdrawn(msg.sender, _amount);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Set NFT base URI.
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   * @return NFT tokens base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}