// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface SplitMain {
  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);
}

/*

 ________  ________  ________  ________  _______           ________ ___  ________  ___  ___  _________
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \         |\  _____\\  \|\   ____\|\  \|\  \|\___   ___\
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|        \ \  \__/\ \  \ \  \___|\ \  \\\  \|___ \  \_|
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/__       \ \   __\\ \  \ \  \  __\ \   __  \   \ \  \
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \       \ \  \_| \ \  \ \  \|\  \ \  \ \  \   \ \  \
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\       \ \__\   \ \__\ \_______\ \__\ \__\   \ \__\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|        \|__|    \|__|\|_______|\|__|\|__|    \|__|
   \|_________|


* @title ERC1155 contract for Space Fight Releases
*
* @author loltapes.eth
*/
contract SpaceFightRelease is ERC1155, ERC2981, Ownable, Pausable {
  using Strings for uint256;

  event RoyaltyConfigured(uint256 tokenId, address royaltyPayoutAddress, uint256 basisPoints);

  event CreatedSplit(address splitAddress, address[] receivers, uint32[] percentages);

  uint256 constant public RELEASE_DENOMINATOR = 10_000;

  SplitMain immutable public splitterFactory;

  // Token name
  string constant public name = "Space Fight Release";

  // Token symbol
  string constant public symbol = "SFR";

  // @notice configuration of a single release
  struct Release {
    uint96 mintPrice;
    uint64 maxSupply;
    uint64 teamReserve;
    uint8 walletMintLimit;
    uint8 txMintLimit;
    uint16 tracksAmount;
    string metadataUri;
  }

  // releaseId => Release
  mapping(uint256 => Release) public releases;

  // releaseId => mintedSupply
  mapping(uint256 => uint256) public mintedSupply;

  // releaseId => (wallet => amount minted)
  mapping(uint256 => mapping(address => uint256)) public minted;

  // @notice indicates which release is currently up for sale
  uint256 public releaseIdForSale;

  // @notice Current root for reserved sale proofs
  bytes32 public currentMerkleRoot;

  // @notice Address to withdraw contract funds (from minting; royalties are set up separately).
  //   Should be updated with each release to a payment splitter involving relevant parties.
  address public mintPayoutAddress;

  // @notice Payout address of the core team. Will be combined with artist addresses for token based royalty splits.
  address public coreTeamPayoutAddress;

  // @notice Keeps track of royalty splits created using {splitterFactory}.
  address[] public createdSplits;

  uint96 public defaultRoyaltyBasisPoints;

  uint256 public releaseCounter;

  constructor(
    address _mintPayoutAddress,
    address _teamPayoutAddress,
    address _splitterFactoryAddress
  ) ERC1155("") {
    // payment
    mintPayoutAddress = _mintPayoutAddress;
    coreTeamPayoutAddress = _teamPayoutAddress;

    splitterFactory = SplitMain(_splitterFactoryAddress);

    setDefaultRoyalty(coreTeamPayoutAddress, 1000);

    // start sales paused
    _pause();
  }

  // region Configuration

  function addRelease(
    uint96 mintPrice,
    uint64 maxSupply,
    uint64 teamReserve,
    uint8 walletMintLimit,
    uint8 txMintLimit,
    uint16 tracksAmount,
    address[] calldata artistAddresses,
    string calldata metadataUri
  )
  external
  onlyOwner
  {
    // start at id 1
    uint256 releaseId = ++releaseCounter;

    require(maxSupply > 0, "Supply must be > 0");
    require(maxSupply >= teamReserve, "Max supply must be >= team reserve");
    require(teamReserve > 0, "Must mint 1 by default");

    require(tracksAmount < RELEASE_DENOMINATOR, "Tracks amount over limit");
    require(artistAddresses.length == tracksAmount, "Specify one artist address per track");

    releases[releaseId] = Release(
      mintPrice,
      maxSupply,
      teamReserve - 1,
      walletMintLimit,
      txMintLimit,
      tracksAmount,
      metadataUri
    );

    // mint one release by default and set the remainder of team reserve to be mintable later
    mintInternal(msg.sender, releaseId, tracksAmount, 1);

    for (uint256 i = 0; i < tracksAmount;) {
      // required as per ERC1155 standard
      uint256 tokenId = toTokenId(releaseId, i + 1);
      emit URI(uri(tokenId), tokenId);

      // configure royalties
      setTokenRoyaltyForArtist(tokenId, artistAddresses[i], defaultRoyaltyBasisPoints);

      unchecked{++i;}
    }
  }

  function setMintPrice(uint256 releaseId, uint96 mintPrice) external onlyOwner whenReleaseExists(releaseId) {
    releases[releaseId].mintPrice = mintPrice;
  }

  function reduceMaxSupply(uint256 releaseId, uint64 maxSupply) external onlyOwner whenReleaseExists(releaseId) {
    uint256 currentSupply = totalReleaseSupply(releaseId);
    require(maxSupply >= currentSupply + releases[releaseId].teamReserve, "New supply below existing/reserved supply");
    require(maxSupply <= releases[releaseId].maxSupply, "Can only reduce supply");
    releases[releaseId].maxSupply = maxSupply;
  }

  // @notice Sets maximum mints per wallet. Setting to '0' removes any limitation.
  function setWalletMintLimit(uint256 releaseId, uint8 limit) external onlyOwner whenReleaseExists(releaseId) {
    releases[releaseId].walletMintLimit = limit;
  }

  // @notice Sets maximum mints per tx. Setting to '0' removes any limitation.
  function setTxMintLimit(uint256 releaseId, uint8 limit) external onlyOwner whenReleaseExists(releaseId) {
    releases[releaseId].txMintLimit = limit;
  }

  function setMetadataUri(uint256 releaseId, string calldata metadataUri) external onlyOwner whenReleaseExists(releaseId) {
    releases[releaseId].metadataUri = metadataUri;

    uint16 tracksAmount = releases[releaseId].tracksAmount;
    for (uint256 i = 0; i < tracksAmount;) {
      // required as per ERC1155 standard
      uint256 tokenId = toTokenId(releaseId, ++i);
      emit URI(uri(tokenId), tokenId);
    }
  }

  // @notice Mints {amount} tokens of remaining team reserve to address {to}
  function mintTeamReserve(uint256 releaseId, address to, uint64 amount) external onlyOwner whenReleaseExists(releaseId) {
    require(releases[releaseId].teamReserve >= amount, "Over team reserve");
    releases[releaseId].teamReserve -= amount;

    uint16 tracksAmount = releases[releaseId].tracksAmount;
    mintInternal(to, releaseId, tracksAmount, amount);
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    (uint256 releaseId, uint256 trackId) = toReleaseAndTrackIds(tokenId);
    require(mintedSupply[releaseId] > 0, "Invalid release");
    require(trackId <= releases[releaseId].tracksAmount, "Invalid track");

    string storage metadataUri = releases[releaseId].metadataUri;
    if (bytes(metadataUri).length > 0) {
      return string(abi.encodePacked(metadataUri, trackId.toString()));
    } else {
      return "";
    }
  }

  // endregion

  // region Sale

  // @notice Returns the current sale state. (0=paused/not for sale, 1=reserved, 2=public)
  function saleState() external view returns (uint256 state) {
    if (paused() || releaseIdForSale == 0) {
      // paused / nothing for sale
      return 0;
    } else if (currentMerkleRoot != 0) {
      // reserved
      return 1;
    } else {
      // public
      return 2;
    }
  }

  function startPublicSale(uint256 releaseId) external onlyOwner whenPaused whenReleaseExists(releaseId) {
    releaseIdForSale = releaseId;
    currentMerkleRoot = 0;
    _unpause();
  }

  function startReservedSale(uint256 releaseId, bytes32 merkleRoot) external onlyOwner whenPaused whenReleaseExists(releaseId) {
    releaseIdForSale = releaseId;
    currentMerkleRoot = merkleRoot;
    _unpause();
  }

  function pauseSale() external onlyOwner whenNotPaused {
    _pause();
  }

  function endSale() external onlyOwner {
    _endSale();
  }

  function _endSale() internal whenNotPaused {
    releaseIdForSale = 0;
    currentMerkleRoot = 0;
    _pause();
  }

  function mintSale(uint256 amount, bytes32[] calldata proof) external payable whenNotPaused whenReleaseExists(releaseIdForSale) {
    // Reserved sale validation
    if (currentMerkleRoot != 0) {
      require(
        MerkleProof.verify(proof, currentMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
        "Invalid merkle proof"
      );
    }

    // require to mint at least one
    require(amount > 0, "Must mint at least one");

    Release storage release = releases[releaseIdForSale];

    // tx limit (0 == no limit)
    if (release.txMintLimit > 0) {
      require(amount <= release.txMintLimit, "Over tx mint limit");
    }

    // require exact payment
    require(msg.value == amount * release.mintPrice, "Wrong ETH amount");

    // enforce per wallet mint limit (0 == no limit)
    if (release.walletMintLimit > 0) {
      require(minted[releaseIdForSale][msg.sender] + amount <= release.walletMintLimit, "Over wallet mint limit");
    }

    // require enough mintable supply
    uint256 newTotalSupply = totalReleaseSupply(releaseIdForSale) + amount;
    uint256 maxMintableSupply = release.maxSupply - release.teamReserve;
    require(newTotalSupply <= maxMintableSupply, "Over mintable supply");

    mintInternal(msg.sender, releaseIdForSale, release.tracksAmount, amount);

    // finish sale automatically
    if (newTotalSupply == maxMintableSupply) {
      _endSale();
    }
  }

  function mintSpecial(
    uint256 releaseId,
    address[] calldata to,
    uint256[] calldata amounts
  ) external onlyOwner {
    require(to.length == amounts.length, "Recipients and amounts must match");
    uint256 amount = to.length;
    uint256 tokenId = toTokenId(releaseId, 0);
    for (uint256 i = 0; i < amount;) {
      _mint(to[i], tokenId, amounts[i], "");
    unchecked {++i;}
    }
  }

  function mintInternal(address to, uint256 releaseId, uint256 tracksAmount, uint256 amount) internal {
    minted[releaseId][to] = minted[releaseId][to] + amount;
    mintedSupply[releaseId] = mintedSupply[releaseId] + amount;

    uint256[] memory ids = new uint256[](tracksAmount);
    uint256[] memory amounts = new uint256[](tracksAmount);

    for (uint256 i = 0; i < tracksAmount;) {
      // start with track id 1
      ids[i] = toTokenId(releaseId, i + 1);
      amounts[i] = amount;

    unchecked {++i;}
    }

    _mintBatch(to, ids, amounts, "");
  }

  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    currentMerkleRoot = merkleRoot;
  }

  // endregion

  // region Payment / Royalties

  receive() external payable {}

  function setMintPayoutAddress(address payoutAddress) external onlyOwner {
    mintPayoutAddress = payoutAddress;
  }

  function setTeamPayoutAddress(address payoutAddress) external onlyOwner {
    coreTeamPayoutAddress = payoutAddress;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(mintPayoutAddress), address(this).balance);
  }

  // @notice Set default token royalty
  // @param basis points (using 2 decimals - 10_000 = 100%, 100 = 1%)
  function setDefaultRoyalty(address receiver, uint96 basisPoints) public onlyOwner {
    defaultRoyaltyBasisPoints = basisPoints;
    _setDefaultRoyalty(receiver, basisPoints);
  }

  // @notice Set royalty for a single token by creating a split between the team and artist (using 0xSplits). The split
  //   is always created at a 50/50 rate between team and artist.
  //
  // @param tokenId The token id (see also {toTokenId}) to set the royalty for
  // @param artistAddress Address to receive part of the royalty split. Zero address resets the royalty for this token.
  // @param basisPoints Royalty in basis points (1pt = 0.01%). Pass 0 to use {defaultRoyaltyBasisPoints}.
  function setTokenRoyaltyForArtist(
    uint256 tokenId,
    address artistAddress,
    uint96 basisPoints
  ) public onlyOwner {
    if (artistAddress == address(0)) {
      _resetTokenRoyalty(tokenId);
      return;
    }

    address[] memory recipients = new address[](2);
    // needs to be ordered
    if (artistAddress > coreTeamPayoutAddress) {
      recipients[0] = coreTeamPayoutAddress;
      recipients[1] = artistAddress;
    } else {
      recipients[0] = artistAddress;
      recipients[1] = coreTeamPayoutAddress;
    }

    uint32[] memory percentages = new uint32[](2);
    percentages[0] = uint32(50_0000);
    percentages[1] = uint32(50_0000);

    address predictedRoyaltyPayoutAddress = splitterFactory.predictImmutableSplitAddress(recipients, percentages, 0);

    if (Address.isContract(predictedRoyaltyPayoutAddress)) {
      setTokenRoyalty(tokenId, predictedRoyaltyPayoutAddress, basisPoints);
    } else {
      address royaltyPayoutAddress = splitterFactory.createSplit(recipients, percentages, 0, address(0));
      emit CreatedSplit(royaltyPayoutAddress, recipients, percentages);
      createdSplits.push(royaltyPayoutAddress);
      setTokenRoyalty(tokenId, royaltyPayoutAddress, basisPoints);
    }
  }

  // @notice Set royalty for a single token. This can be used to give the artist a different share than 50%.
  //
  // @param tokenId The token id (see also {toTokenId}) to set the royalty for.
  // @param receiver Address to receive the royalty. Cannot pass the zero address.
  // @param basisPoints Royalty in basis points (1pt = 0.01%). Pass 0 to use {defaultRoyaltyBasisPoints}.
  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 basisPoints) public onlyOwner {
    uint96 royaltyAmount = basisPoints == 0 ? defaultRoyaltyBasisPoints : basisPoints;
    _setTokenRoyalty(tokenId, receiver, royaltyAmount);
    emit RoyaltyConfigured(tokenId, receiver, royaltyAmount);
  }

  // @dev allow to retrieve ERC20 tokens sent to the contract
  function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyOwner {
    token.transfer(toAddress, amount);
  }

  // @dev allow to retrieve ERC721 tokens sent to the contract
  function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyOwner {
    token.transferFrom(address(this), toAddress, tokenId);
  }

  // @dev allow to retrieve ERC1155 tokens sent to the contract
  function withdrawERC1155(IERC1155 token, address toAddress, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), toAddress, tokenId, token.balanceOf(address(this), tokenId), "");
  }

  // endregion

  // region Default Overrides

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC1155, ERC2981)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // endregion

  // region Utilities

  function totalReleaseSupply(uint256 releaseId) public view whenReleaseExists(releaseId) returns (uint256) {
    return mintedSupply[releaseId];
  }

  /**
   * @notice Decodes a token id into the release id and track id.
   *
   * Token Schema: RTTTT
   * - R: Release ID; multiple of 10_000
   * - T: Track ID; 0-9999
   */
  function toReleaseAndTrackIds(uint256 tokenId) public pure returns (uint256 releaseId, uint256 trackId) {
    return (tokenId / RELEASE_DENOMINATOR, tokenId % RELEASE_DENOMINATOR);
  }

  /**
   * @notice Encodes a release id and track id into a token id.
   *
   * Token Schema: RTTTT
   * - R: Release ID; multiple of 10_000
   * - T: Track ID; 0-9999
   */
  function toTokenId(uint256 releaseId, uint256 trackId) public pure returns (uint256 tokenId) {
    require(trackId < RELEASE_DENOMINATOR, "Track ID out of bounds");
    return releaseId * RELEASE_DENOMINATOR + trackId;
  }

  modifier whenReleaseExists(uint256 releaseId) {
    require(mintedSupply[releaseId] > 0, "Invalid release");
    _;
  }

  // endregion
}

/* Contract by loltapes.eth
          _       _ _
    ____ | |     | | |
   / __ \| | ___ | | |_ __ _ _ __   ___  ___
  / / _` | |/ _ \| | __/ _` | '_ \ / _ \/ __|
 | | (_| | | (_) | | || (_| | |_) |  __/\__ \
  \ \__,_|_|\___/|_|\__\__,_| .__/ \___||___/
   \____/                   | |
                            |_|
*/