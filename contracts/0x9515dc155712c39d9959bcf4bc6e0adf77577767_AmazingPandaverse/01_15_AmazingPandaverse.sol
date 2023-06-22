// SPDX-License-Identifier: None
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


contract AmazingPandaverse is Ownable, ERC721, VRFConsumerBaseV2 {

  using Address for address;
  using ECDSA for bytes32;

  event RandomIndexsCreated(uint64 subscriptionId, uint16 numWords);
  event BaseUriUpdated(string uri);
  event SaleInfoUpdated(bool presaleActive, uint256 publicPrice);
  event AdminMint(address minter, uint16 numberOfTokens);
  event BuyPresale(address buyer, uint16 numberOfTokens);
  event BuyPublic(address buyer, uint16 numberOfTokens);
  event Withdraw(address to, uint256 amount);

  uint256 public publicPrice;
  bool public presaleActive;

  uint16 constant PNDV_SUPPLY = 8888;
  uint16 constant PNDV_PRESALE_SUPPLY = 8100;

  uint16 public totalSupply = 0;

  uint16 presaleTotalSupply = 0;

  mapping(address => uint16) private adminMintSupplys;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  string public baseURI;

  address whitelistSigner = 0xDf174521DfF3677F8d19F1279F778a1F794c6B2c;

  VRFCoordinatorV2Interface COORDINATOR;
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  uint16 requestConfirmations = 3;

  uint16[] private randomIndexs;
  mapping(uint16 => uint16) private indexUpdated;

  mapping(address => uint256) public presaleMinted;

  bytes32 private constant TYPEHASH =
    keccak256("presale(address buyer,uint256 limit)");

  // CONSTRUCTOR **************************************************

  constructor()
    ERC721("Amazing Pandaverse", "PNDV")
    VRFConsumerBaseV2(vrfCoordinator) // VRF Coordinator
  {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

    adminMintSupplys[0xD0De30dE1f1C53551FE2A7dfEFE556B2e64b0b8f] = 2000;
    adminMintSupplys[0x9582f10E1a3C91f48FbB6540C1102d2A3fcCb78a] = 2000;
    adminMintSupplys[0x5396c3166346f2Ba6E94F0ADAF57A3E53D4bfDa5] = 1500;
    adminMintSupplys[0x8A101aFf9e28e6daa682ac3aC5CB122Beb367AA6] = 1500;
    adminMintSupplys[0x4E249f4A67a3336E342AA4E51BcF2444130CC622] = 1000;
  }

  // PUBLIC METHODS ****************************************************

  function createRandomIndexs(uint64 subscriptionId, uint32 callbackGasLimit, uint16 numWords) public onlyOwner {
    uint16 len = uint16(PNDV_SUPPLY - randomIndexs.length);
    require(len > 0, "createRandomIndexs error: randomIndexs is full.");

    COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      len % numWords
    );

    uint16 count = len / numWords;

    for (uint16 i = 0; i < count; i++) {
      COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
    }

    emit RandomIndexsCreated(subscriptionId, numWords);
  }

  /// @notice Allows users to buy during presale, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the cryptoPNDV website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  function buyPresale(
    bytes calldata signature,
    uint16 numberOfTokens,
    uint256 approvedLimit
  ) public payable {
    require(
      presaleActive,
      "Presale is not active"
    );
    require(whitelistSigner != address(0), "Whitelist signer has not been set");
    require(
      msg.value == (0.15 ether * numberOfTokens),
      "Insufficient payment"
    );
    require(
      (presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit,
      "Presale mint limit exceeded"
    );
    require(
      (presaleTotalSupply + numberOfTokens) <= PNDV_PRESALE_SUPPLY,
      "Not enough PNDV remaining in presale"
    );

    bytes32 digest = keccak256(abi.encodePacked(TYPEHASH, msg.sender, approvedLimit));
    address signer = digest.toEthSignedMessageHash().recover(signature);
    require(
      signer != address(0) && signer == whitelistSigner,
      "Invalid signature"
    );

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;

    presaleTotalSupply += numberOfTokens;

    mint(msg.sender, numberOfTokens);

    emit BuyPresale(msg.sender, numberOfTokens);
  }

  /// @notice Allows users to buy during public sale, pricing follows a dutch auction format
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  /// @param numberOfTokens the number of NFTs to buy
  function buyPublic(uint16 numberOfTokens) public payable {
    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    require(publicPrice > 0, "Public sale is not active");
    require(numberOfTokens <= 3, "Mint limit exceeded");

    uint256 mintPrice = publicPrice * numberOfTokens;
    require(msg.value == mintPrice, "Insufficient payment");

    mint(msg.sender, numberOfTokens);

    emit BuyPublic(msg.sender, numberOfTokens);
  }

  function adminMint(address to, uint16 numberOfTokens) public payable {
    require(
      (presaleTotalSupply + numberOfTokens) <= PNDV_PRESALE_SUPPLY,
      "Not enough PNDV remaining in presale"
    );


    if (msg.sender != owner()) {
      require(numberOfTokens <= adminMintSupplys[msg.sender], "Not Authorised or Admin Mint limit exceeded");
      require(
        msg.value == (0.15 ether * numberOfTokens),
        "Incorrect payment"
      );

      adminMintSupplys[msg.sender] = adminMintSupplys[msg.sender] - numberOfTokens;
    }

    mint(to, numberOfTokens);

    presaleTotalSupply += numberOfTokens;

    emit AdminMint(to, numberOfTokens);
  }

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallet
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // OWNER METHODS ********************************************************

  function setBaseURI(string calldata newBaseUri) public onlyOwner {
    baseURI = newBaseUri;

    emit BaseUriUpdated(newBaseUri);
  }

  function setSaleInfo(bool presaleActive_, uint256 publicPrice_) public onlyOwner {
    presaleActive = presaleActive_;
    publicPrice = publicPrice_;

    emit SaleInfoUpdated(presaleActive_, publicPrice_);
  }

  function withdraw(address payable to, uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "Insufficient balance.");
    uint256 perAmount = amount / 100;
    Address.sendValue(to, perAmount * 95);
    Address.sendValue(payable(0x61Fc286855Ee7BAeF8B8038bA769d350aA53D498), perAmount * 5);

    emit Withdraw(to, amount);
  }

  function withdrawOtherTokens(address tokenAddress, uint256 amount )external onlyOwner {
      require(address(this) != tokenAddress);
      IERC20 otherTokens = IERC20(tokenAddress);
      otherTokens.transfer(msg.sender, amount);
  }


  // PRIVATE/INTERNAL METHODS ****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
      for (uint16 i = 0; i < randomWords.length; i++) {
        uint16 index = uint16(randomWords[i] % (PNDV_SUPPLY - randomIndexs.length));
        randomIndexs.push(index);
      }
  }

  function mint(address to, uint16 numberOfTokens) private {

    uint16 remaining = PNDV_SUPPLY - totalSupply;

    require(remaining >= numberOfTokens, "Not enough PNDV remaining");

    // require(randomIndexs.length >= totalSupply + numberOfTokens, "Not enough randomIndexs remaining");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint16 index = randomIndexs[i + totalSupply];
      uint256 tokenId = indexUpdated[index] > 0 ? indexUpdated[index] : index + 1;
      indexUpdated[index] = indexUpdated[remaining - 1] > 0 ? indexUpdated[remaining - 1] : remaining;
      _safeMint(to, tokenId);
      remaining --;
    }

    totalSupply += numberOfTokens;
  }

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address repres enting the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}