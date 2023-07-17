// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// @title HouseHaeds Minting Smart Contract
contract HouseHaeds is DefaultOperatorFiltererUpgradeable, ERC721AUpgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
  using StringsUpgradeable for uint256;

  bytes32 public merkleRootElderList;
  bytes32 public merkleRootWhitelist;

  mapping(address => uint256) public elderListClaimed;
  mapping(address => uint256) public whitelistClaimed;
  mapping(address => uint256) public publicClaimed;

  string public uriPrefix;
  string public uriSuffix;

  uint256 public cost;
  uint256 public costElderList;
  uint256 public costWhitelist;
  uint256 public maxSupply;
  uint256 public maxMintAmountElderList;
  uint256 public maxMintAmountWhitelist;
  uint256 public maxMintAmountPublic;

  uint256 public presaleTokensAmount;

  bool public whitelistMintEnabled;
  bool public elderListMintEnabled;
  bool public publicMintEnabled;

  address[] public withdrawAddresses;
  uint256[] public withdrawShares;  // Amounts are in divided my 100000
  mapping(address => uint256) public pendingWithdrawals;
  uint256 lastWithdrawAmount;

  // Storage gap to allow for future upgrades
  uint256[48] private __gap;

  // Opensea-related Events
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /**
  * @dev Initializes the contract with the specified parameters.
  * @param _tokenName The name of the token.
  * @param _tokenSymbol The symbol of the token.
  * @param _cost The cost in wei for each token.
  * @param _costWhitelist The cost in wei for each token for addresses on the whitelist.
  * @param _costElderList The cost in wei for each token for addresses on the elder list.
  * @param _maxMintAmounts Array containing the maximum number of tokens that can be minted during each sale (4).
  * @param _maxSupply The maximum total supply of the token.
  * @param _hiddenMetadataUri The base URI for the token metadata that is hidden from the public.
  * @param _withdrawAddresses Array containing the addresses to which the contract's balance will be withdrawn.
  * @param _withdrawShares Array containing the shares of the contract's balance that will be withdrawn to each address.
  * Requirements:
  * - The _maxMintAmounts array must contain exactly 4 elements.
  * - The _withdrawAddresses and _withdrawShares arrays must have the same length.
  */
  function initialize(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _costWhitelist,
    uint256 _costElderList,
    uint256[] memory _maxMintAmounts,
    uint256 _maxSupply,
    uint256 _presaleTokensAmount,
    string memory _hiddenMetadataUri,
    address[] memory _withdrawAddresses,
    uint256[] memory _withdrawShares
) initializer initializerERC721A public {
    require(_maxMintAmounts.length == 3, "Invalid max mint amounts!");
    require(_withdrawAddresses.length == _withdrawShares.length, "Invalid withdraw shares array length!");
    require(_presaleTokensAmount <= _maxSupply, "Invalid presale tokens amount!");

    uint256 totalShares = 0;
    for (uint256 i = 0; i < _withdrawShares.length;) {
      totalShares += _withdrawShares[i];
      unchecked { i++; }
    }
    require(totalShares == 100000, "Invalid withdraw shares total!");

    __ERC721A_init(_tokenName, _tokenSymbol);
    __Ownable2Step_init();
    __ReentrancyGuard_init();
    __DefaultOperatorFilterer_init();

    maxMintAmountElderList = _maxMintAmounts[0];
    maxMintAmountWhitelist = _maxMintAmounts[1];
    maxMintAmountPublic = _maxMintAmounts[2];

    presaleTokensAmount = _presaleTokensAmount;

    costElderList = _costElderList;
    costWhitelist = _costWhitelist;
    cost = _cost;
    maxSupply = _maxSupply;

    uriPrefix = _hiddenMetadataUri;
    uriSuffix = ".json";

    withdrawAddresses = _withdrawAddresses;
    withdrawShares = _withdrawShares;
  }

  /**
  * @dev Allows addresses that are on the elder list to mint tokens with an additional bonus amount.
  * @param _mintAmount The number of tokens to mint.
  * @param _merkleProof The merkle proof of the caller's address against the merkle root of the elder list.
  * Requirements:
  * - The elder list sale must be enabled.
  * - The caller must provide sufficient funds to cover the cost of minting.
  * - The caller's address must not have already claimed the maximum number of tokens allowed.
  * - The caller's address must be included in the merkle root of the elder list.
  * - The total number of tokens to mint, including the bonus amount, must not exceed the maximum supply.
  */
  function elderListMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
    // Verify elderList requirements
    require(elderListMintEnabled, "The elder list sale is not enabled!");
    require(msg.value >= costElderList * _mintAmount, "Insufficient funds!");
    require((elderListClaimed[_msgSender()] + _mintAmount) <= maxMintAmountElderList, "Address already claimed!");
    require(merkleRootElderList != bytes32(0), "Merkle root not set! Please contact the contract owner.");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProofUpgradeable.verify(_merkleProof, merkleRootElderList, leaf), "Invalid proof!");

    uint256 totalToMint = _mintAmount + _mintAmount / 2;
    require(totalSupply() + totalToMint + presaleTokensAmount <= maxSupply, "Max supply exceeded!");
    elderListClaimed[_msgSender()] = elderListClaimed[_msgSender()] + _mintAmount;
    _mint(_msgSender(), totalToMint);
  }

  /**
  * @dev Mints a given amount of tokens and assigns them to the sender's address if the sender is whitelisted.
  * @param _mintAmount The amount of tokens to mint.
  * @param _merkleProof The Merkle tree proof that verifies the sender's address is whitelisted.
  * Requirements:
  * - Whitelist minting must be enabled.
  * - The caller must send enough ether to cover the cost of the minted tokens, minus any applicable sale discount.
  * - The caller's address must not have already claimed the maximum amount of tokens.
  * - The Merkle tree proof must verify that the sender's address is whitelisted.
  * - The total supply of tokens must not exceed the maximum supply.
  */
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(msg.value >= costWhitelist * _mintAmount, "Insufficient funds!");
    require((whitelistClaimed[_msgSender()] + _mintAmount) <= maxMintAmountWhitelist, "Address already claimed!");
    require(merkleRootWhitelist != bytes32(0), "Merkle root not set! Please contact the contract owner.");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProofUpgradeable.verify(_merkleProof, merkleRootWhitelist, leaf), "Invalid proof!");
    require(totalSupply() + _mintAmount + presaleTokensAmount <= maxSupply, "Max supply exceeded!");

    whitelistClaimed[_msgSender()] = whitelistClaimed[_msgSender()] + _mintAmount;
    _mint(_msgSender(), _mintAmount);
  }

  /**
  * @dev Mints a given amount of tokens and assigns them to the sender's address.
  * @param _mintAmount The amount of tokens to mint.
  * Requirements:
  * - Public minting must be enabled.
  * - The caller must send enough ether to cover the cost of the minted tokens.
  * - The caller's address must not have already claimed the maximum amount of tokens.
  * - The total supply of tokens must not exceed the maximum supply.
  */
  function mint(uint256 _mintAmount) external payable {
    require(publicMintEnabled, "The public sale is not enabled!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require((publicClaimed[_msgSender()] + _mintAmount) <= maxMintAmountPublic, "Address already claimed!");
    require(totalSupply() + _mintAmount + presaleTokensAmount <= maxSupply, "Max supply exceeded!");

    publicClaimed[_msgSender()] = publicClaimed[_msgSender()] + _mintAmount;
    _mint(_msgSender(), _mintAmount);
  }

  /**
  * @dev Mints a given amount of tokens and assigns them to the specified receiver.
  * @param _mintAmount The amount of tokens to mint.
  * @param _receiver The address to assign the minted tokens to.
  * Requirements:
  * - The caller must be the contract owner.
  * - The total supply of tokens must not exceed the maximum supply.
  */
  function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
    require(totalSupply() + _mintAmount + presaleTokensAmount <= maxSupply, "Max supply exceeded!");
    _mint(_receiver, _mintAmount);
  }

  /**
  * @dev Mints a given amount of tokens and assigns them to the specified receivers.
  * @param isForPresale Whether the minting is for the presale.
  * @param _mintAmounts The amounts of tokens to mint.
  * @param _receivers The addresses to assign the minted tokens to.
  * Requirements:
  * - The caller must be the contract owner.
  * - The total minted nfts must not exceed the maximum supply.
  * - The array lengths of _mintAmounts and _receivers must match.
  */
  function mintForAddresses(bool isForPresale, uint256[] calldata _mintAmounts, address[] calldata _receivers) external onlyOwner {
    require(_mintAmounts.length == _receivers.length, "Array lengths must match!");
    uint256 mintAmountsLength = _mintAmounts.length;
    for(uint256 i = 0; i < mintAmountsLength;) {
      // We verify is the minting is for the presale and if so, we check if there are enough presale tokens left.
      // If the minting is not for the presale, we check if there are enough public tokens left.
      if (isForPresale) {
        require(totalSupply() + _mintAmounts[i] <= maxSupply, "Max supply exceeded!");
        require(presaleTokensAmount >= _mintAmounts[i], "Not enough presale tokens left!");
          presaleTokensAmount = presaleTokensAmount - _mintAmounts[i];
      } else {
        require(totalSupply() + _mintAmounts[i] + presaleTokensAmount <= maxSupply, "Max supply exceeded!");
      }
      _mint(_receivers[i], _mintAmounts[i]);
      unchecked { i++; }
    }
  }

  /**
  * @dev Returns an array of all token IDs owned by the given address.
  * @param _owner The address to query.
  * @return An array of token IDs owned by the given address.
  * The array is empty if the address does not own any tokens.
  */
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        unchecked { ownedTokenIndex++; }
      }

      unchecked { currentTokenId++; }
    }

    return ownedTokenIds;
  }

  /**
  * @dev Returns the URI of the token with the given ID.
  * Reverts if the token does not exist.
  * @param _tokenId The ID of the token to query.
  * @return A string representing the URI of the token.
  * If no base URI is set, returns an empty string.
  * Otherwise, concatenates the base URI with the token ID and suffix.
  */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : "";
  }

  /**
  * @dev Sets the maximum supply of tokens that can exist in the contract.
  * @param _maxSupply The new maximum supply value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The new maximum supply must be greater than the current supply plus the presale tokens.
  */
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply >= totalSupply() + presaleTokensAmount, "Max supply cannot be less than supply and presale tokens!");
    maxSupply = _maxSupply;
  }

  /**
  * @dev Sets the presale tokens amount.
  * @param _presaleTokensAmount The new presale tokens amount value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The new presale tokens amount must be less than the max supply.
  */
  function setPresaleTokensAmount(uint256 _presaleTokensAmount) external onlyOwner {
    require(_presaleTokensAmount + totalSupply() <= maxSupply, "Presale tokens cannot be more than max supply!");
    presaleTokensAmount = _presaleTokensAmount;
  }

  /**
  * @dev Set the cost of each token for the elder list.
  * @param _costElderList The new cost value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setCostElderList(uint256 _costElderList) external onlyOwner {
    costElderList = _costElderList;
  }

  /**
  * @dev Set the cost of each token for the whitelist.
  * @param _costWhitelist The new cost value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setCostWhitelist(uint256 _costWhitelist) external onlyOwner {
      costWhitelist = _costWhitelist;
  }

  /**
  * @dev Set the cost of each token.
  * @param _cost The new cost value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The cost must be higher than the discount.
  */
  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  /**
  * @dev Set the maximum amount of tokens that can be minted by a single address in the elder list.
  * @param _maxMintAmountElderList The new maximum mint amount value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The maximum mint amount must be lower than the max supply.
  */
  function setMaxMintAmountElderList(uint256 _maxMintAmountElderList) external onlyOwner {
    require(_maxMintAmountElderList <= maxSupply, "Max mint amount cannot be higher than max supply!");
    maxMintAmountElderList = _maxMintAmountElderList;
  }

  /**
  * @dev Set the maximum amount of tokens that can be minted by a single address in the whitelist.
  * @param _maxMintAmountWhitelist The new maximum mint amount value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The maximum mint amount must be lower than the max supply.
  */
  function setMaxMintAmountWhitelist(uint256 _maxMintAmountWhitelist) external onlyOwner {
    require(_maxMintAmountWhitelist <= maxSupply, "Max mint amount cannot be higher than max supply!");
    maxMintAmountWhitelist = _maxMintAmountWhitelist;
  }

  /**
  * @dev Set the maximum amount of tokens that can be minted by a single address in the public sale.
  * @param _maxMintAmountPublic The new maximum mint amount value to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The maximum mint amount must be lower than the max supply.
  */
  function setMaxMintAmountPublic(uint256 _maxMintAmountPublic) external onlyOwner {
    require(_maxMintAmountPublic <= maxSupply, "Max mint amount cannot be higher than max supply!");
    maxMintAmountPublic = _maxMintAmountPublic;
  }

  /**
  * @dev Set the uri prefix.
  * @param _uriPrefix The new uri prefix value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setUriPrefix(string calldata _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
    emit BatchMetadataUpdate(_startTokenId(), totalSupply());
  }

  /**
  * @dev Set the uri suffix.
  * @param _uriSuffix The new uri suffix value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  * @dev Set the Merkle root for the elder list.
  * @param _merkleRoot The new Merkle root value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setMerkleRootElderList(bytes32 _merkleRoot) external onlyOwner {
    require(_merkleRoot != bytes32(0), "Merkle root must not be empty!");
    merkleRootElderList = _merkleRoot;
  }

  /**
  * @dev Set the Merkle root for the whitelist.
  * @param _merkleRoot The new Merkle root value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setMerkleRootWhitelist(bytes32 _merkleRoot) external onlyOwner {
    require(_merkleRoot != bytes32(0), "Merkle root must not be empty!");
    merkleRootWhitelist = _merkleRoot;
  }

  /**
  * @dev Set the ElderList minting state.
  * @param _state The new state value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setElderListMintEnabled(bool _state) external onlyOwner {
    elderListMintEnabled = _state;
  }

  /**
  * @dev Set the WhiteList minting state.
  * @param _state The new state value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setWhitelistMintEnabled(bool _state) external onlyOwner {
    whitelistMintEnabled = _state;
  }

  /**
  * @dev Set the Public minting state.
  * @param _state The new state value to set.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function setPublicMintEnabled(bool _state) external onlyOwner {
    publicMintEnabled = _state;
  }

  /**
  * @dev Set the withdraw addresses and shares.
  * @param _withdrawAddresses The new withdraw addresses array to set.
  * @param _withdrawShares The new withdraw shares array to set.
  * Requirements:
  * - The caller must be the contract owner.
  * - The withdraw addresses and shares arrays must have the same length.
  * - The withdraw shares total must be 100000.
  */
  function setWithdrawShares(address[] calldata _withdrawAddresses, uint256[] calldata _withdrawShares) external onlyOwner {
    require(_withdrawAddresses.length == _withdrawShares.length, "Invalid withdraw shares array length!");

    uint256 totalShares = 0;
    for (uint256 i = 0; i < _withdrawShares.length;) {
      totalShares += _withdrawShares[i];
      unchecked { i++; }
    }
    require(totalShares == 100000, "Invalid withdraw shares total!");

    withdrawAddresses = _withdrawAddresses;
    withdrawShares = _withdrawShares;
  }

  /**
  * @dev Split the funds in the contract.
  * Requirements:
  * - The caller must be the contract owner.
  */
  function splitFunds() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    uint256 balanceToSplit = contractBalance - lastWithdrawAmount;
    require(balanceToSplit > 0, "Error, cannot split funds until more NFTs are bought.");

    // Split the funds between the withdraw addresses based on their shares.
    for(uint256 i = 0; i < withdrawAddresses.length;) {
      // The shares are multiplied by 100000 to allow for 2 decimal places + %.
      pendingWithdrawals[withdrawAddresses[i]] += balanceToSplit * withdrawShares[i] / 100000;
      unchecked { i++; }
    }

    lastWithdrawAmount = lastWithdrawAmount + balanceToSplit;
  }

  /**
  * @dev Withdraws the contract's balance to the specified addresses.
  * Requirements:
  * - The caller must be the contract owner.
  * - The call must not be reentrant.
  */
  function withdraw() external nonReentrant {
    uint256 amount = pendingWithdrawals[_msgSender()];

    require(amount != 0);
    require(address(this).balance >= amount);

    pendingWithdrawals[_msgSender()] = 0;
    // The last withdraw amount is decreased by the amount withdrawn.
    lastWithdrawAmount = lastWithdrawAmount - amount;

    (bool sent,) = payable(_msgSender()).call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }


  // ------------------------------------------------------------------------
  // OpenSea Operator Filterer Functions
  // ------------------------------------------------------------------------

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}