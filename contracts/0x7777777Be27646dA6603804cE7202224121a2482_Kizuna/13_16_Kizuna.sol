/*
KKKKKKKKK    KKKKKKK     IIIIIIIIII     ZZZZZZZZZZZZZZZZZZZ     UUUUUUUU     UUUUUUUU     NNNNNNNN        NNNNNNNN                    AAA               
K:::::::K    K:::::K     I::::::::I     Z:::::::::::::::::Z     U::::::U     U::::::U     N:::::::N       N::::::N                   A:::A              
K:::::::K    K:::::K     I::::::::I     Z:::::::::::::::::Z     U::::::U     U::::::U     N::::::::N      N::::::N                  A:::::A             
K:::::::K   K::::::K     II::::::II     Z:::ZZZZZZZZ:::::Z      UU:::::U     U:::::UU     N:::::::::N     N::::::N                 A:::::::A            
KK::::::K  K:::::KKK       I::::I       ZZZZZ     Z:::::Z        U:::::U     U:::::U      N::::::::::N    N::::::N                A:::::::::A           
  K:::::K K:::::K          I::::I               Z:::::Z          U:::::D     D:::::U      N:::::::::::N   N::::::N               A:::::A:::::A          
  K::::::K:::::K           I::::I              Z:::::Z           U:::::D     D:::::U      N:::::::N::::N  N::::::N              A:::::A A:::::A         
  K:::::::::::K            I::::I             Z:::::Z            U:::::D     D:::::U      N::::::N N::::N N::::::N             A:::::A   A:::::A        
  K:::::::::::K            I::::I            Z:::::Z             U:::::D     D:::::U      N::::::N  N::::N:::::::N            A:::::A     A:::::A       
  K::::::K:::::K           I::::I           Z:::::Z              U:::::D     D:::::U      N::::::N   N:::::::::::N           A:::::AAAAAAAAA:::::A      
  K:::::K K:::::K          I::::I          Z:::::Z               U:::::D     D:::::U      N::::::N    N::::::::::N          A:::::::::::::::::::::A     
KK::::::K  K:::::KKK       I::::I       ZZZ:::::Z     ZZZZZ      U::::::U   U::::::U      N::::::N     N:::::::::N         A:::::AAAAAAAAAAAAA:::::A    
K:::::::K   K::::::K     II::::::II     Z::::::ZZZZZZZZ:::Z      U:::::::UUU:::::::U      N::::::N      N::::::::N        A:::::A             A:::::A   
K:::::::K    K:::::K     I::::::::I     Z:::::::::::::::::Z       UU:::::::::::::UU       N::::::N       N:::::::N       A:::::A               A:::::A  
K:::::::K    K:::::K     I::::::::I     Z:::::::::::::::::Z         UU:::::::::UU         N::::::N        N::::::N      A:::::A                 A:::::A 
KKKKKKKKK    KKKKKKK     IIIIIIIIII     ZZZZZZZZZZZZZZZZZZZ           UUUUUUUUU           NNNNNNNN         NNNNNNN     AAAAAAA                   AAAAAAA
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./MerkleRootManager.sol";

/**
 * @author KirienzoEth for Kizuna
 * @title Contract for the Kizuna NFTs
 */
contract Kizuna is ERC721A, ERC2981, Ownable, MerkleRootManager, OperatorFilterer {
  using Strings for uint256;

  uint256 public maxSupply;
  address public treasuryWallet;
  bool public operatorFilteringEnabled;

  // ====================================
  //            METADATA
  // ====================================

  string public baseURI;
  /// @notice if false, all tokens' metadata will be `baseURI`, otherwise it will depend on the token ID
  bool public isRevealed;
  /// @notice if true, the metadata cannot be changed anymore
  bool public isMetadataFrozen;

  // ====================================
  //            PUBLIC SALE
  // ====================================

  bool public isPublicMintPaused = true;
  uint256 public publicPrice = 0.04 ether;
  /// @notice How many NFTs a wallet can mint during the public sale
  uint256 public mintLimitPerWallet = 3;
  /// @notice How many NFTs needs to be reserved for the free mint during the public sale
  uint256 public freeMintSupply;
  /// @notice How many NFTs an address minted during the public mint phase
  mapping(address => uint256) public publicMintAddressesMintedAmount;

  // ====================================
  //       WHITELIST AND FREE MINT
  // ====================================

  bool public isWhitelistMintPhase1Paused = true;
  bool public isWhitelistMintPhase2Paused = true;
  bool public isFreeMintPaused = true;
  uint256 public whitelistPrice = 0.025 ether;
  /// @notice How many NFTs an address minted during the whitelist mint phase
  mapping(address => uint256) public whitelistAddressesMintedAmount;
  /// @notice How many NFTs an address minted during the free mint phase
  mapping(address => uint256) public freeAddressesMintedAmount;

  // ====================================
  //                EVENTS
  // ====================================

  event MetadataFrozen();
  event PauseForWhitelistMintToggled(bool isPaused);
  event PauseForFreeMintToggled(bool isPaused);
  event PauseForPublicMintToggled(bool isPaused);
  event PublicPriceChanged(uint256 newPrice);
  event WhitelistPriceChanged(uint256 newPrice);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  constructor(
    uint256 _maxSupply,
    uint256 _reservedSupply,
    uint256 _freeMintSupply,
    address _treasuryWallet,
    string memory _initialURI
  ) ERC721A("Kizuna", "KZN") {
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;
    maxSupply = _maxSupply;
    freeMintSupply = _freeMintSupply;
    baseURI = _initialURI;
    treasuryWallet = _treasuryWallet;
    _mintERC2309(_treasuryWallet, _reservedSupply);
    _setDefaultRoyalty(_treasuryWallet, 300);
  }

  // ====================================
  //           (UN)PAUSE MINTS
  // ====================================

  function togglePauseForWhitelistMintPhase1() external onlyOwner {
    isWhitelistMintPhase1Paused = !isWhitelistMintPhase1Paused;

    emit PauseForWhitelistMintToggled(isWhitelistMintPhase1Paused);
  }

  function togglePauseForWhitelistMintPhase2() external onlyOwner {
    isWhitelistMintPhase2Paused = !isWhitelistMintPhase2Paused;

    emit PauseForWhitelistMintToggled(isWhitelistMintPhase2Paused);
  }

  function togglePauseForFreeMint() external onlyOwner {
    isFreeMintPaused = !isFreeMintPaused;

    emit PauseForFreeMintToggled(isFreeMintPaused);
  }

  function togglePauseForPublicMint() external onlyOwner {
    isPublicMintPaused = !isPublicMintPaused;

    emit PauseForPublicMintToggled(isPublicMintPaused);
  }

  // ====================================
  //                MINTS
  // ====================================

  function _whitelistMint(
    uint256 _amountToMint,
    uint256 _maxAmountForAddress,
    uint256 _price
  ) private doesNotExceedReservedSupply(_amountToMint) hasEnoughEther(_price, _amountToMint) {
    unchecked {
      // Increase the amount minted by this address
      whitelistAddressesMintedAmount[msg.sender] += _amountToMint;
    }

    // Prevent an address from minting more than its allocation
    require(
      whitelistAddressesMintedAmount[msg.sender] <= _maxAmountForAddress,
      "Kizuna: Mint limit for address reached"
    );

    // Mint
    _mint(msg.sender, _amountToMint);
  }

  function whitelistMintPhase1(
    uint256 _amountToMint,
    uint256 _maxAmountForAddress,
    bytes32[] calldata _merkleProof
  ) external payable {
    require(!isWhitelistMintPhase1Paused, "Kizuna: Whitelist minting is paused");

    // Verify the merkle proof.
    bytes32 _node = keccak256(abi.encodePacked(msg.sender, _maxAmountForAddress));
    require(MerkleProof.verify(_merkleProof, whitelistPhase1MerkleRoot, _node), "Kizuna: Invalid proof");

    _whitelistMint(_amountToMint, _maxAmountForAddress, whitelistPrice);
  }

  function whitelistMintPhase2(
    uint256 _amountToMint,
    uint256 _maxAmountForAddress,
    bytes32[] calldata _merkleProof
  ) external payable {
    require(!isWhitelistMintPhase2Paused, "Kizuna: Whitelist minting is paused");

    // Verify the merkle proof.
    bytes32 _node = keccak256(abi.encodePacked(msg.sender, _maxAmountForAddress));
    require(MerkleProof.verify(_merkleProof, whitelistPhase2MerkleRoot, _node), "Kizuna: Invalid proof");

    _whitelistMint(_amountToMint, _maxAmountForAddress, whitelistPrice);
  }

  function freeMint(
    uint256 _amountToMint,
    uint256 _maxAmountForAddress,
    bytes32[] calldata _merkleProof
  ) external doesNotExceedSupply(_amountToMint) {
    require(!isFreeMintPaused, "Kizuna: Free minting is paused");

    // Verify the merkle proof.
    bytes32 _node = keccak256(abi.encodePacked(msg.sender, _maxAmountForAddress));
    require(MerkleProof.verify(_merkleProof, freeMintMerkleRoot, _node), "Kizuna: Invalid proof");

    unchecked {
      // Increase the amount minted by this address
      freeAddressesMintedAmount[msg.sender] += _amountToMint;
      freeMintSupply -= _amountToMint;
    }

    // Prevent an address from minting more than its allocation
    require(freeAddressesMintedAmount[msg.sender] <= _maxAmountForAddress, "Kizuna: Mint limit for address reached");

    _mint(msg.sender, _amountToMint);
  }

  function mint(
    uint256 _amountToMint
  ) external payable doesNotExceedReservedSupply(_amountToMint) hasEnoughEther(publicPrice, _amountToMint) {
    require(!isPublicMintPaused, "Kizuna: Minting is paused");

    // Prevent an address from minting more than its allocation
    require(
      publicMintAddressesMintedAmount[msg.sender] + _amountToMint <= mintLimitPerWallet,
      "Kizuna: Mint limit for address reached"
    );

    // Increase the amount minted by this address
    publicMintAddressesMintedAmount[msg.sender] += _amountToMint;

    _mint(msg.sender, _amountToMint);
  }

  function teamMint(address _to, uint256 _amountToMint) external doesNotExceedSupply(_amountToMint) onlyOwner {
    _mint(_to, _amountToMint);
  }

  // ====================================
  //               PRICES
  // ====================================

  function setPublicPrice(uint256 _price) external onlyOwner {
    publicPrice = _price;
    emit PublicPriceChanged(_price);
  }

  function setWhitelistPrice(uint256 _price) external onlyOwner {
    whitelistPrice = _price;
    emit WhitelistPriceChanged(_price);
  }

  // ====================================
  //               METADATA
  // ====================================

  function freezeMetadata() external onlyOwner {
    isMetadataFrozen = true;

    emit MetadataFrozen();
  }

  /// @dev See {IERC721Metadata-tokenURI}.
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (!isRevealed) {
      return baseURI;
    }

    return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
  }

  function reveal(string calldata _baseUri) external onlyOwner {
    require(!isMetadataFrozen, "Kizuna: Metadata is frozen");
    baseURI = _baseUri;
    isRevealed = true;
    emit BatchMetadataUpdate(0, type(uint256).max);
  }

  // ====================================
  //                MISC
  // ====================================

  function withdrawBalance() external onlyOwner {
    (bool success, ) = treasuryWallet.call{ value: address(this).balance }("");
    require(success, "Transfer failed.");
  }

  function withdrawBalanceToOwner() external onlyOwner {
    (bool success, ) = owner().call{ value: address(this).balance }("");
    require(success, "Transfer failed.");
  }

  /// @notice Reduce the max supply
  /// @param _newMaxSupply The new max supply, cannot be higher than the current max supply
  function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
    require(_newMaxSupply < maxSupply, "Kizuna: Cannot increase max supply");
    require(_newMaxSupply >= totalSupply(), "Kizuna: Max supply cannot be lower than current supply");

    maxSupply = _newMaxSupply;
  }

  /// @notice Change the royalty parameters
  /// @param _royaltyReceiver The address that will receive the royalties, it cannot be the zero address
  /// @param _feeNumerator How much of a sale proceeds will go to the _royaltyReceiver address (expressed out of 10000, i.e: 250 is 2.5%)
  function changeRoyaltySettings(address _royaltyReceiver, uint96 _feeNumerator) external onlyOwner {
    treasuryWallet = _royaltyReceiver;
    _setDefaultRoyalty(_royaltyReceiver, _feeNumerator);
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC2981.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
  }

  // ====================================
  //    OPERATOR FILTERER OVERRIDES
  // ====================================

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(address operator) internal pure override returns (bool) {
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  // ====================================
  //               MODIFIERS
  // ====================================

  modifier doesNotExceedSupply(uint256 _amountToMint) {
    require(_totalMinted() + _amountToMint <= maxSupply, "Kizuna: Exceeds max supply");
    _;
  }

  modifier doesNotExceedReservedSupply(uint256 _amountToMint) {
    require(
      _totalMinted() + _amountToMint <= maxSupply - freeMintSupply,
      "Kizuna: Exceeds max supply + reserved supply"
    );
    _;
  }

  modifier hasEnoughEther(uint256 _price, uint256 _amountToMint) {
    require(msg.value == _price * _amountToMint, "Kizuna: Wrong amount of ether sent");
    _;
  }
}