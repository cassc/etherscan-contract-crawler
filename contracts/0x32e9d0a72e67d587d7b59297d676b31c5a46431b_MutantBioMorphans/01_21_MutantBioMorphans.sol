//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MutantBioMorphans is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, IERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bool public saleActive = false;
  bool public transferActive = true;
  uint8 public redeemedGiveaways;
  uint8 private stage;
  uint8 public constant MINT_BATCH_LIMIT = 5; // Max number of Tokens minted in a single txn
  uint8 public constant RESERVED_GIVEAWAYS = 30; // Tokens reserved for giveaway list
  uint16 public constant MAX_TOKENS = 1170; // Max number of token sold in sale
  uint16 public constant SPLIT_BASE = 10000;
  uint16 internal royalty = 700; // base 10000, 7%
  uint16 public constant BASE = 10000;


  string public PROVENANCE_HASH = '';
  string private baseURI;
  string private tokenSuffixURI;
  string private contractMetadata = 'contract.json';

  uint256 public constant SALE_PRICE = 65000000000000000; // 0.065 ETH
  uint256 public constant EVOLVE_PRICE = 25000000000000000; // 0.025 ETH

  uint256 public saleStartsAt;
  uint256 public publicsaleStartsAt;
  uint256 public privatesaleStartsAt;
  uint256 public privatesaleEndsAt;

  bytes32 public whitelistMerkleRoot;

  bytes32 public redeemMerkleRoot;

  address[] private recipients;
  uint16[] private splits;

  mapping(uint256 => uint8) private evolutionLevel;

  mapping(address => bool) public giveawayRedeemed;

  mapping(address => bool) public proxyRegistryAddress;

  event TokenMinted(address indexed owner, uint256 indexed quantity);
  event TokenEvolved(uint256 indexed id, uint8 indexed level, address indexed owner);
  event SaleStatusChange(address indexed issuer, bool indexed status);
  event TransferStatusChange(address indexed issuer, bool indexed status);
  event ContractWithdraw(address indexed initiator, uint256 amount);
  event ContractWithdrawToken(address indexed initiator, address indexed token, uint256 amount);
  event ProvenanceHashSet(address indexed initiator, string previousHash, string newHash);
  event WithdrawAddressChanged(address indexed previousAddress, address indexed newAddress);


  constructor(
    uint256 _saleStartTime,
    uint256 _privateSaleEndsAt,
    uint256 _publicSaleStartsAt,
    string memory _baseContractURI,
    string memory _tokenSuffixURI,
    string memory _provenaceHash,
    address[] memory _recipients,
    uint16[] memory _splits,
    address _proxyAddress
  ) ERC721('MutantBioMorphans', 'MBM') {
    baseURI = _baseContractURI;
    tokenSuffixURI = _tokenSuffixURI;
    saleStartsAt = _saleStartTime; // Unix Timestamp
    privatesaleStartsAt = saleStartsAt; // Start Private Sale,
    privatesaleEndsAt = _privateSaleEndsAt; // End of Private Sale
    publicsaleStartsAt = _publicSaleStartsAt; // Start of Public Sale
    PROVENANCE_HASH = _provenaceHash;
    recipients = _recipients;
    splits = _splits;
    proxyRegistryAddress[_proxyAddress] = true;
    stage = 1;
  }

  function mintNFT(address recipient, uint8 numTokens) external onlyOwner {
    require(block.timestamp >= (publicsaleStartsAt), 'Sale not active');
    require((_tokenIds.current() + numTokens) <= MAX_TOKENS + redeemedGiveaways, 'Sale sold');
    for (uint8 i = 0; i < numTokens; i++) {
      _tokenIds.increment();
      evolutionLevel[_tokenIds.current()] = 3;
      _safeMint(recipient, _tokenIds.current());
    }
    emit TokenMinted(recipient, numTokens);
  }

  function mintGiveawayNFT(bytes32[] memory proof, uint8 numTokens) external {
    require(block.timestamp >= (saleStartsAt), 'Sale not active');
    require(!giveawayRedeemed[msg.sender], 'Already redeemed');
    require((numTokens + redeemedGiveaways) <= RESERVED_GIVEAWAYS, 'All Giveaways Redeemed');
    require(MerkleProof.verify(proof, redeemMerkleRoot, keccak256(abi.encodePacked(msg.sender, numTokens))), 'Restricted Access');
    giveawayRedeemed[msg.sender] = true;
    for (uint8 i = 0; i < numTokens; i++) {
      _tokenIds.increment();
      unchecked {
        redeemedGiveaways++;
      }
      evolutionLevel[_tokenIds.current()] = 3;
      _safeMint(msg.sender, _tokenIds.current());
    }
    emit TokenMinted(msg.sender, numTokens);
  }

  function evolve(uint256 tokenId) external payable {
    require(evolutionLevel[tokenId] < 5, 'Token Fully Evolved');
    require(stage > 2, 'Can not evolve yet');
    require(msg.value >= EVOLVE_PRICE, 'Insufficient ETH');
    require(msg.sender == super.ownerOf(tokenId), 'Access denied');
    unchecked {
      evolutionLevel[tokenId]++;
    }
    emit TokenEvolved(tokenId, evolutionLevel[tokenId], msg.sender);
  }

  function tokenLevel(uint256 tokenId) external view returns (uint8) {
    if (stage == 1 || stage == 2) return stage;
    return evolutionLevel[tokenId];
  }

  function advanceStage() external onlyOwner {
    require(stage < 3, 'Not permitted');
    unchecked {
      stage++;
    }
    emit TokenEvolved(0, stage, msg.sender);
  }

  function setWhitelistMerkleRoot(bytes32 _root) external onlyOwner {
    whitelistMerkleRoot = _root;
  }

  function setRedeemMerkleRoot(bytes32 _root) external onlyOwner {
    redeemMerkleRoot = _root;
  }

  /**
   * @dev mints `numTokens` tokens and assigns it to
   * `msg.sender` by calling _safeMint function.
   *
   * Emits a {TokenMinted} event.
   * Emits two {TransferSingle} events via ERC721 Contract.
   *
   * Requirements:
   * - `saleActive` must be set to true.
   * - Current timestamp must greater than or equal `saleStartsAt`.
   * - Current timestamp must within period of private sale `privatesaleStartsAt` - `privatesaleEndsAt`.
   * - `msg.sender` is among whitelisted memebrs based on the merkle proof provided
   * - Ether amount sent greater or equal the base price multipled by `numTokens`.
   * - `numTokens` within limits of max number of tokens minted in single txn.
   * - Max number of tokens for the private sale not reahced
   * @param numTokens - Number of tokens to be minted
   * @param proof -The merkle proof for the whitelisted address
   */
  function mintPrivateSale(uint8 numTokens, bytes32[] memory proof) external payable {
    require(!Address.isContract(msg.sender), 'Cannot mint to a contract');
    uint256 time = (block.timestamp);
    require(saleActive && time >= (saleStartsAt), 'Sale not active');
    require(time > (privatesaleStartsAt) && time < (privatesaleEndsAt), 'Private sale over');

    require((_tokenIds.current() + numTokens) <= MAX_TOKENS + redeemedGiveaways, 'Private sale sold');

    // bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), 'Restricted Access');

    require(msg.value >= SALE_PRICE * numTokens, 'Insufficient ETH');
    require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, 'Invalid Num Token');

    for (uint256 i = 0; i < numTokens; i++) {
      _tokenIds.increment();
      evolutionLevel[_tokenIds.current()] = 3;
      _safeMint(msg.sender, _tokenIds.current());
    }

    emit TokenMinted(msg.sender, numTokens);
  }

  /**
   * @dev mints `numTokens` tokens and assigns it to
   * `msg.sender` by calling _safeMint function.
   *
   * Emits a {TokenMinted} event.
   * Emits two {TransferSingle} events via ERC721 Contract.
   *
   * Requirements:
   * - `saleActive` must be set to true.
   * - Current timestamp must greater than or equal `saleStartsAt`.
   * - Current timestamp must within period of public sale `publicsaleStartsAt` - `publicsaleEndsAt`.
   * - Ether amount sent greater or equal the current price multipled by `numTokens`.
   * - `numTokens` within limits of max number of tokens minted in single txn.
   * - Max number of tokens for the sale not reahced
   * @param numTokens - Number of tokens to be minted
   */
  function mintPublicSale(uint8 numTokens) external payable {
    require(!Address.isContract(msg.sender), 'Cannot mint to a contract');

    require(saleActive && block.timestamp >= (publicsaleStartsAt), 'Sale not active');

    require(msg.value >= SALE_PRICE * numTokens, 'Insufficient ETH');
    require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, 'Wrong Num Token');
    require((_tokenIds.current() + numTokens) <= MAX_TOKENS + redeemedGiveaways, 'Public sale sold');
    for (uint8 i = 0; i < numTokens; i++) {
      _tokenIds.increment();
      evolutionLevel[_tokenIds.current()] = 3;
      _safeMint(msg.sender, _tokenIds.current());
    }
    emit TokenMinted(msg.sender, numTokens);
  }

  function setBaseURI(string memory baseContractURI) external onlyOwner {
    baseURI = baseContractURI;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory baseContractURI = _baseURI();
    return bytes(baseContractURI).length > 0 ? string(abi.encodePacked(baseContractURI, tokenId.toString(), tokenSuffixURI)) : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev returns the base contract metadata json object
   * this metadat file is used by OpenSea see {https://docs.opensea.io/docs/contract-level-metadata}
   *
   */
  function contractURI() external view returns (string memory) {
    string memory baseContractURI = _baseURI();
    return string(abi.encodePacked(baseContractURI, contractMetadata));
  }

  /**
   * @dev Changes the sale status 'saleActive' from active to not active and vice versa
   *
   * Only Contract Owner can execute
   *
   * Emits a {SaleStatusChange} event.
   */
  function changeSaleStatus() external onlyOwner {
    saleActive = !saleActive;
    emit SaleStatusChange(msg.sender, saleActive);
  }

  /**
   * @dev Changes the sale status 'transferActive' from active to not active and vice versa
   *
   * Only Contract Owner can execute
   *
   * Emits a {TransferStatusChange} event.
   */
  function changeTransferStatus() external onlyOwner {
    transferActive = !transferActive;
    emit TransferStatusChange(msg.sender, transferActive);
  }

  /**
   * @dev withdraws the contract balance and send it to the withdraw Addresses based on split ratio.
   *
   * Emits a {ContractWithdraw} event.
   */
  function withdraw() external nonReentrant onlyOwner {
    uint256 balance = address(this).balance;

    for (uint256 i = 0; i < recipients.length; i++) {
      (bool sent, ) = payable(recipients[i]).call{value: (balance * splits[i]) / SPLIT_BASE}('');
      require(sent, 'Withdraw Failed.');
    }

    emit ContractWithdraw(msg.sender, balance);
  }

  /// @notice Calculate the royalty payment
  /// @param _salePrice the sale price of the token
  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    return (address(this), (_salePrice * royalty) / BASE);
  }

  /// @dev set the royalty
  /// @param _royalty the royalty in base 10000, 700 = 7%
  function setRoyalty(uint16 _royalty) external onlyOwner {
    require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

    royalty = _royalty;
  }

  /// @dev withdraw ERC20 tokens divided by splits
  function withdrawTokens(address _tokenContract) external nonReentrant onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    // transfer the token from address of Catbotica address
    uint256 balance = tokenContract.balanceOf(address(this));

    for (uint256 i = 0; i < recipients.length; i++) {
      tokenContract.transfer(recipients[i], (balance * splits[i]) / SPLIT_BASE);
    }

    emit ContractWithdrawToken(msg.sender, _tokenContract, balance);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function changeWithdrawAddress(address _recipient) external {
    require(_recipient != address(0), 'Cannot use zero address.');
    require(_recipient != address(this), 'Cannot use this contract address');
    require(!Address.isContract(_recipient), 'Cannot set recipient to a contract address');

    // loop over all the recipients and update the address
    bool _found = false;
    for (uint256 i = 0; i < recipients.length; i++) {
      // if the sender matches one of the recipients, update the address
      if (recipients[i] == msg.sender) {
        recipients[i] = _recipient;
        _found = true;
        break;
      }
    }
    require(_found, 'The sender is not a recipient.');
    emit WithdrawAddressChanged(msg.sender, _recipient);
  }

  function getRemSaleSupply() external view returns (uint256) {
    // if (_tokenIds.current() >= MAX_TOKENS) return 0;
    return (MAX_TOKENS + RESERVED_GIVEAWAYS - _tokenIds.current());
  }

  /**
   * @dev sets `PROVENANCE_HASH`
   *
   * Only Contract Owner can execute
   *
   * @param provenanceHash the string for the metadata and images hash
   */
  function setProvenanceHash(string memory provenanceHash) external onlyOwner {
    emit ProvenanceHashSet(msg.sender, PROVENANCE_HASH, provenanceHash);
    PROVENANCE_HASH = provenanceHash;
  }

  function setSplitRatio(uint16[] memory _splits) external onlyOwner {
    splits = _splits;
  }

  receive() external payable {}

  /**
   * Override isApprovedForAll to whitelisted marketplaces to enable gas-free listings.
   *
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    // check if this is an approved marketplace
    if (proxyRegistryAddress[_operator]) {
      return true;
    }
    // otherwise, use the default ERC721 isApprovedForAll()
    return super.isApprovedForAll(_owner, _operator);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(),'ERC721Pausable: token transfer while paused');
    require(transferActive || from == address(0),'ERC721Pausable: token transfer while paused');
  }

  /*
   * Function to set status of proxy contracts addresses
   *
   */
  function setProxy(address _proxyAddress, bool _value) external onlyOwner {
    proxyRegistryAddress[_proxyAddress] = _value;
  }

  function pause() external onlyOwner {
    super._pause();
  }

  function unpause() external onlyOwner {
    super._unpause();
  }

}