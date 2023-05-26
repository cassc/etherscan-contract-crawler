// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './interfaces/IBurnableContract.sol';
import './interfaces/IMintPassContract.sol';

contract HighCouncilOfKingz is ERC721, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  // Contract addresses for interfaces
  address public burnableContract;
  address public mintPassContract;

  // Contract controls; defaults to false
  bool public revealed; //defaults to false
  bool public mintEnabled; //defaults to false

  // Mint variables
  uint16 public constant totalTokens = 500;

  // counter
  uint16 private _totalMintSupply = 0; // start with zero

  // metadata URIs
  string private _contractURI; // initially set at deploy
  string private _notRevealedURI; // initially set at deploy
  string private _currentBaseURI = 'ipfs://nope/'; // to be set before reveal
  string private _baseExtension = '.json';

  // Mapping Minter address to token count for mint controls
  mapping(address => uint16) public addressMints;
  // Mapping used mint pass ids
  mapping(uint256 => bool) public usedMintPasses;
  // Mapping burned burnable nfts
  mapping(uint256 => bool) public burnedTokens;
  // Mapping token matrix
  mapping(uint16 => uint16) private tokenMatrix;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initContractURI,
    string memory _initNotRevealedURI,
    address _burnableContract,
    address _mintPassContract
  ) ERC721(_name, _symbol) {
    require(_burnableContract != address(0), 'Zero address');
    require(_mintPassContract != address(0), 'Zero address');
    _contractURI = _initContractURI;
    _notRevealedURI = _initNotRevealedURI;
    burnableContract = _burnableContract;
    mintPassContract = _mintPassContract;
  }

  modifier callerIsUser() {
    require(tx.origin == _msgSender(), 'Caller is another contract');
    _;
  }

  modifier onlyAllowMintEnabledAndValidCount(uint256 _mintAmount) {
    require(_totalMintSupply + _mintAmount <= totalTokens, 'Exceeds supply');
    require(mintEnabled, 'Mint disabled');
    _;
  }

  /**
   * @dev Returns the URI to the contract metadata
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Internal function to return the base uri for all tokens
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _currentBaseURI;
  }

  /**
   * @dev Returns the URI to the tokens metadata
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'Nonexistent token');

    if (revealed == false) {
      return _notRevealedURI;
    }

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), _baseExtension))
        : '';
  }

  /**
   * @dev Returns the total number of tokens in circulation
   */
  function totalSupply() external view returns (uint16) {
    return _totalMintSupply;
  }

  /**
   * @dev Returns list of token ids owned by address
   */
  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    uint256 k = 0;
    for (uint256 i = 1; i <= totalTokens; i++) {
      if (_exists(i) && _owner == ownerOf(i)) {
        tokenIds[k] = i;
        k++;
      }
    }
    delete ownerTokenCount;
    delete k;
    return tokenIds;
  }

  /**
   * @dev mint
   */
  function mint(uint256 _mintPassTokenId, uint256[] memory _burnTokenIds)
    external
    callerIsUser
    onlyAllowMintEnabledAndValidCount(1)
  {
    // make sure we have exactly 5 COK
    require(_burnTokenIds.length == 5, '5 burn tokens');
    // ensure mint pass can only be used once here
    require(!usedMintPasses[_mintPassTokenId], 'Pass used here');
    usedMintPasses[_mintPassTokenId] = true;
    // ensure burnable tokens can only be used once here
    for (uint256 i = 0; i < _burnTokenIds.length; i++) {
      require(!burnedTokens[_burnTokenIds[i]], 'Token used here');
      burnedTokens[_burnTokenIds[i]] = true;
    }
    _totalMintSupply++;
    _safeMint(_msgSender(), _getTokenToBeMinted(_totalMintSupply - 1));
    // ensure owner of mint pass
    require(
      _msgSender() ==
        IMintPassContract(mintPassContract).ownerOf(_mintPassTokenId),
      'Not owner'
    );
    // ensure the mint pass is not Used or Expired
    require(
      IMintPassContract(mintPassContract).isValid(_mintPassTokenId),
      'Pass invalid'
    );
    IBurnableContract(burnableContract).burn(_burnTokenIds);
    // mark the pass as used
    IMintPassContract(mintPassContract).setAsUsed(_mintPassTokenId);
  }

  /**
   * @dev Returns a random available token to be minted
   */
  function _getTokenToBeMinted(uint16 _totalMintedTokens)
    private
    returns (uint16)
  {
    uint16 maxIndex = totalTokens - _totalMintedTokens;
    uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

    uint16 tokenId = tokenMatrix[random];
    if (tokenMatrix[random] == 0) {
      tokenId = random;
    }

    tokenMatrix[maxIndex - 1] == 0
      ? tokenMatrix[random] = maxIndex - 1
      : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

    return tokenId + 1;
  }

  /**
   * @dev Generates a pseudo-random number
   */
  function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
    private
    view
    returns (uint16)
  {
    uint16 random = uint16(
      uint256(
        keccak256(
          abi.encodePacked(
            _totalMintedTokens,
            blockhash(block.number - 1),
            block.coinbase,
            block.difficulty,
            _msgSender()
          )
        )
      )
    );

    return random % _upper;
  }

  /**
   * Owner functions
   */

  /**
   * @dev Owner mint function
   */
  function ownerMint(uint16 _mintAmount)
    external
    onlyOwner
    callerIsUser
    onlyAllowMintEnabledAndValidCount(_mintAmount)
  {
    addressMints[_msgSender()] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _totalMintSupply++;
      _safeMint(_msgSender(), _getTokenToBeMinted(_totalMintSupply - 1));
    }
  }

  /**
   * @dev Setter for the burnable NFT contract address
   */
  function setBurnableContractAddress(address _burnableContract)
    external
    onlyOwner
  {
    require(_burnableContract != address(0), 'Zero address');
    burnableContract = _burnableContract;
  }

  /**
   * @dev Setter for the Mint Pass contract address
   */
  function setMintPassContractAddress(address _mintPassContract)
    external
    onlyOwner
  {
    require(_mintPassContract != address(0), 'Zero address');
    mintPassContract = _mintPassContract;
  }

  /**
   * @dev Reveal the token metadata
   */
  function reveal() external onlyOwner {
    revealed = true;
  }

  /**
   * @dev Set minting enabled
   */
  function setMintEnable() external onlyOwner {
    require(
      IBurnableContract(burnableContract).burnEnabled(),
      'Burnable contract disabled'
    );
    mintEnabled = true;
  }

  /**
   * @dev Setter for the Contract URI
   */
  function setContractURI(string memory _newContractURI) external onlyOwner {
    _contractURI = _newContractURI;
  }

  /**
   * @dev Setter for the Not Revealed URI
   */
  function setNotRevealedURI(string memory _newNotRevealedURI)
    external
    onlyOwner
  {
    _notRevealedURI = _newNotRevealedURI;
  }

  /**
   * @dev Setter for the Base URI
   */
  function setCurrentBaseURI(string memory _newBaseURI) external onlyOwner {
    _currentBaseURI = _newBaseURI;
  }

  /**
   * @dev Setter for the meta data base extension
   */
  function setBaseExtension(string memory _newBaseExtension)
    external
    onlyOwner
  {
    _baseExtension = _newBaseExtension;
  }

  function withdraw() external payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(
      ''
    );
    require(success);
  }

  /**
   * @dev A fallback function in case someone sends ETH to the contract
   */
  fallback() external payable {}

  receive() external payable {}
}