// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

contract ERC721Drop is ERC721AQueryable, PaymentSplitter, Ownable, DefaultOperatorFilterer {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error CasteSupplyOverflow();
  error InvalidProof();

  struct MintRules {
    uint256 supply;
    uint256 maxPerWallet;
    uint256 freePerWallet;
    uint256 price;
  }

  struct Castes {
    uint64 fire;
    uint64 grass;
    uint64 sun;
    uint64 water;
  }

  modifier onlyWhitelist(bytes32[] calldata _proof, uint256 _freeQuantity) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _freeQuantity))));

    if (!MerkleProof.verify(_proof, _merkleRoot, leaf)) {
      revert InvalidProof();
    }
    _;
  }

  MintRules public mintRules;
  string public baseTokenURI;
  Castes public castesLeft;

  bytes32 private _merkleRoot;
  address[] private _withdrawAddresses;

  mapping(uint256 => uint256) public castePerTokenId;
  mapping(uint256 => uint256) public casteTokenId;
  mapping(uint256 => uint256) public castesSupply;

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721A('Voodoos', 'VDS') PaymentSplitter(_payees, _shares) {
    castesLeft = Castes(399, 700, 800, 600);
    _setWithdrawAddresses(_payees);
  }

  /*//////////////////////////////////////////////////////////////
                         External getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  function casteOf(uint256 _tokenId) public view returns (uint256) {
    return castePerTokenId[_tokenId];
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice _castes Array of characters to mint where
   *  _characters[0] - fire,
   *  _characters[1] - grass,
   *  _characters[2] - sun,
   *  _characters[3] - water,
   */
  function mint(
    uint8[] memory _castes,
    uint256 _freeQuantity,
    bytes32[] calldata _proof
  ) external payable onlyWhitelist(_proof, _freeQuantity) {
    _customMint(_castes, _freeQuantity);
  }

  /**
   * @notice _castes Array of characters to mint where
   *  _characters[0] - fire,
   *  _characters[1] - grass,
   *  _characters[2] - sun,
   *  _characters[3] - water,
   */
  function mint(uint8[] memory _castes) external payable {
    _customMint(_castes, mintRules.freePerWallet);
  }

  /*//////////////////////////////////////////////////////////////
                      Owner functions
  //////////////////////////////////////////////////////////////*/

  function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules calldata _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function withdraw() external onlyOwner {
    for (uint256 i = 0; i < _withdrawAddresses.length; ) {
      address payable withdrawAddress = payable(_withdrawAddresses[i]);

      if (releasable(withdrawAddress) > 0) {
        release(withdrawAddress);
      }

      unchecked {
        ++i;
      }
    }
  }

  function setMerkleRoot(bytes32 _root) external onlyOwner {
    _merkleRoot = _root;
  }

  /*//////////////////////////////////////////////////////////////
                      Overriden ERC721A
  //////////////////////////////////////////////////////////////*/

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return
      string(
        abi.encodePacked(baseTokenURI, _toString(castePerTokenId[tokenId]), '/', _toString(casteTokenId[tokenId]))
      );
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /*//////////////////////////////////////////////////////////////
                      Internal functions
  //////////////////////////////////////////////////////////////*/

  function _customMint(uint8[] memory _castes, uint256 _freeQuantity) internal {
    uint256 _quantity = _calculateQuantity(_castes);
    uint256 _paidQuantity = _calculatePaidQuantity(msg.sender, _quantity, _freeQuantity);

    if (_paidQuantity != 0 && msg.value < mintRules.price * _paidQuantity) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _quantity > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _quantity > mintRules.supply) {
      revert TotalSupplyOverflow();
    }

    if (
      castesLeft.fire < _castes[0] ||
      castesLeft.grass < _castes[1] ||
      castesLeft.sun < _castes[2] ||
      castesLeft.water < _castes[3]
    ) {
      revert CasteSupplyOverflow();
    }

    _safeMint(msg.sender, _quantity);
    _updateCastesData(_castes);
  }

  function _calculateQuantity(uint8[] memory _castes) private pure returns (uint256) {
    uint256 _quantity = 0;

    for (uint8 i = 0; i < _castes.length; i++) {
      _quantity += _castes[i];
    }

    return _quantity;
  }

  function _calculatePaidQuantity(
    address _owner,
    uint256 _quantity,
    uint256 _freeQuantity
  ) internal view returns (uint256) {
    uint256 _alreadyMinted = _numberMinted(_owner);
    uint256 _freeQuantityLeft = _alreadyMinted >= _freeQuantity ? 0 : _freeQuantity - _alreadyMinted;

    return _freeQuantityLeft >= _quantity ? 0 : _quantity - _freeQuantityLeft;
  }

  function _setWithdrawAddresses(address[] memory _addresses) internal {
    _withdrawAddresses = _addresses;
  }

  function _updateCastesData(uint8[] memory _castes) private {
    uint256 _startId = _nextTokenId() - _calculateQuantity(_castes);

    for (uint8 i = 0; i < _castes.length; i++) {
      uint256 _startCastId = castesSupply[i] + 1;
      for (uint8 j = 0; j < _castes[i]; j++) {
        casteTokenId[_startId + j] = _startCastId + j;
        castePerTokenId[_startId + j] = i;
      }
      castesSupply[i] += _castes[i];
      _startId += _castes[i];
    }

    castesLeft = Castes(
      castesLeft.fire - _castes[0],
      castesLeft.grass - _castes[1],
      castesLeft.sun - _castes[2],
      castesLeft.water - _castes[3]
    );
  }

  /*//////////////////////////////////////////////////////////////
                        DefaultOperatorFilterer
  //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}