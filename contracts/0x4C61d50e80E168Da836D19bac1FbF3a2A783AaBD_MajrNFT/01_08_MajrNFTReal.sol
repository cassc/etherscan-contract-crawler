// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Splitter.sol";

contract MajrNFT is Splitter, ERC721A, Pausable {
  /// @notice Mint price of a Majr ID
  uint256 public price;

  /// @notice Base URI to get the metadata for each Majr ID
  string private tokenBaseURI;

  /// @notice URI to get the contract-level metadata
  string private contractMetadataURI;

  /// @notice An event emitted when the new price is set
  event NewPrice(uint256 price, uint256 timestamp);

  /// @notice An event emitted when the new base URI is set
  event NewBaseURI(string baseURI, uint256 timestamp);

  /// @notice An event emitted when the new contract metadata URI is set
  event NewContractMetadataURI(string contractMetadataURI, uint256 timestamp);

  /**
   * @notice Constructor
   * @param _name string memory
   * @param _symbol string memory
   * @param _price uint256
   * @param _splitAddresses address payable[] memory
   * @param _splitAmounts uint256[] memory
   * @param _referralAddresses address payable[] memory
   * @param _referralAmounts uint256[] memory 
   * @param _cap uint256
   * @param _tokenBaseURI string memory
   * @param _contractMetadataURI string memory
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _price,

    address payable[] memory _splitAddresses,
    uint256[] memory _splitAmounts,
    address payable[] memory _referralAddresses,
    uint256[] memory _referralAmounts,
    uint256 _cap,

    string memory _tokenBaseURI,
    string memory _contractMetadataURI
  )
  Splitter(
    _splitAddresses,
    _splitAmounts,
    _referralAddresses,
    _referralAmounts,
    _cap
  )
  ERC721A(
    _name,
    _symbol
  )
  {
    price = _price;
    tokenBaseURI = _tokenBaseURI;
    contractMetadataURI = _contractMetadataURI;
  }

  receive() external payable {}

  /**
   * @notice Pauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Updates the mint price of a Majr ID
   * @param _price uint256
   * @dev Only owner can call it and only when the contract is paused amd the price can't be zero
   */
  function setPrice(uint256 _price) external onlyOwner whenPaused {
    require(_price > 0, "MajrNFT: Mint price must be greater than zero.");

    price = _price;

    emit NewPrice(_price, block.timestamp);
  }

  /**
   * @notice Mints the desired amount of Majr IDs to the user calling the function and splits the mint fee to the split addresses (rewards, DAO treasury & company wallets)
   * @param quantity uint256
   * @dev Can only be called while the contract is not paused and user must send the exact value of ether that's required or the transaction will revert
   */
  function mint(uint256 quantity) external payable whenNotPaused {
    require(msg.value == price * quantity, 'MajrNFT: Must send the correct mint fee.');

    _safeMint(msg.sender, quantity);
    this.split{value: msg.value}();
  }

  /**
   * @notice Mints the desired amount of Majr IDs to the user calling the function and splits the mint fee to the referral addresses (rewards, DAO treasury, company & referrer wallets)
   * @param quantity uint256
   * @param referrer address payable
   * @dev Can only be called while the contract is not paused and user must send the exact value of ether that's required or the transaction will revert, and the referrer address cannot be the same as the minter address
   */
  function mintWithReferrer(uint256 quantity, address payable referrer) external payable whenNotPaused {
    require(msg.value == price * quantity, 'MajrNFT: Must send the correct mint fee.');
    require(msg.sender != referrer, 'MajrNFT: Cannot mint with yourself as the referrer.');

    _safeMint(msg.sender, quantity);
    this.referralSplit{value: msg.value}(referrer);
  }

  /**
   * @notice Burns the NFT with a specified ID (user must own the NFT of that ID)
   * @param _tokenId uint256
   * @dev Can only be called while the contract is not paused
   */
  function burn(uint256 _tokenId) external whenNotPaused {
    require(msg.sender == ownerOf(_tokenId), 'MajrNFT: You do not own this token.');

    _burn(_tokenId);
  }

  /**
   * @notice Returns true or false based on whether the specified token ID exists (i.e. it's minted by someone before and not burned afterwards)
   * @param _tokenId uint256
   * @return bool
   */
  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @notice Returns an array of all token IDs owned by the user
   * @param user address
   * @return uint256[] memory
   * @dev This function shouldn't encounter the out-of-gas error up to a certain point. When the collection grows too big, this function should be replaced by the multiple calls of the tokensOfUserIn method
   */
  function tokensOfUser(address user) external view returns (uint256[] memory) {
    unchecked {
      uint256 tokenIdsLength = balanceOf(user);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      uint256 tokenIdsIndex;

      for (uint256 i = 0; tokenIdsIndex != tokenIdsLength; i++) {
        address owner;

        if (_exists(i)) {
          owner = ownerOf(i);
        }

        if (owner == user) {
          tokenIds[tokenIdsIndex++] = i;
        }
      }
      return tokenIds;
    }
  }

  /**
   * @notice Returns an array of all token IDs owned by the user in a specified range
   * @param user address
   * @param start uint256
   * @param stop uint256
   * @return uint256[] memory
   * @dev This function allows for tokens to be queried if the collection grows too big for a single call of the tokensOfUser method
   */
  function tokensOfUserIn(address user, uint256 start, uint256 stop) external view returns (uint256[] memory) {
    require (start >= 0 && start < stop, "MajrNFT: Invalid query range.");
    
    unchecked {
      uint256 tokenIdsMaxLength = balanceOf(user);
      uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);

      if (tokenIdsMaxLength == 0) {
        return tokenIds;
      }

      uint256 tokenIdsIndex;

      for (uint256 i = 0; i != stop && tokenIdsIndex != tokenIdsMaxLength; i++) {
        address owner;

        if (_exists(i)) {
          owner = ownerOf(i);
        }

        if (owner == user) {
          tokenIds[tokenIdsIndex++] = i;
        }
      }

      // Downsize the array to fit
      assembly {
        mstore(tokenIds, tokenIdsIndex)
      }
      return tokenIds;
    }
  }

  /**
   * @notice Returns the total number of tokens ever minted by the user
   * @param _user address
   * @return uint256
   */
  function numberMinted(address _user) public view returns (uint256) {
    return _numberMinted(_user);
  }

  /**
   * @notice Returns the total number of tokens ever burned by the user
   * @param _user address
   * @return uint256
   */
  function numberBurned(address _user) external view returns (uint256) {
    return _numberBurned(_user);
  }

  /**
   * @notice Returns the token metadata URI for a specified Majr ID
   * @param tokenId uint256
   * @return string memory
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(tokenBaseURI,Strings.toString(tokenId)));
  }

  /**
   * @notice Returns the base URI for Majr ID metadata
   * @return string memory
   */
  function baseURI() external view returns (string memory) {
    return tokenBaseURI;
  }

  /**
   * @notice Sets the new base URI for the Majr IDs
   * @param _tokenBaseURI string calldata
   * @dev Only owner can call it
   */
  function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
    tokenBaseURI = _tokenBaseURI;

    emit NewBaseURI(_tokenBaseURI, block.timestamp);
  }

  /**
   * @notice Returns the contract-level metadata URI
   * @return string memory
   */ 
  function contractURI() external view returns (string memory) {
    return contractMetadataURI;
  }

  /**
   * @notice Sets the new contract URI for the Majr IDs
   * @param _contractMetadataURI string calldata
   * @dev Only owner can call it
   */
  function setContractURI(string calldata _contractMetadataURI) external onlyOwner {
    contractMetadataURI = _contractMetadataURI;

    emit NewContractMetadataURI(_contractMetadataURI, block.timestamp);
  }
}