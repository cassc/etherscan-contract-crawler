// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 *   @title Sneaks Of Nature
 *   @author Fr0ntier X <[email protected]>
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/IMetarelics.sol";
import "hardhat/console.sol";

contract SneaksOfNature is ERC721A, ERC2981, Pausable, Ownable, ReentrancyGuard {
  using Strings for string;
  using SafeCast for uint256;

  uint16 public constant MAX_TOKEN_SUPPLY = 3333;

  // Number of tokens that will be preminted to the contract owner
  uint16 public constant PREMINT_TOKEN_COUNT = 100;

  // Address of the Relic Pass smart contract
  address public immutable RELIC_PASS_CONTRACT_ADDRESS;

  // Timestamps for the different stages of the project
  uint256 public closedMintStartTimestamp = 1661950800; //  August 31, 2022, 6am PST
  uint256 public closedMintEndTimestamp = 1661979600; //    August 31, 2022, 2pm PST
  uint256 public ghostProtocolEndTimestamp = 1661983200; // August 31, 2022, 3pm PST

  // Is minting active
  bool public isMintActive = true;

  // Is the user required to be on the public waitlist to mint
  bool public isPublicWaitlistRequired = true;

  // The amount of tokens a user is allowed to mint during the public mint
  uint16 public maxTokensPerUser = 1;

  // Merkle roots of the Sneaks List, Guaranteed Allowlist and Public Waitlist
  bytes32 public sneaksListMerkleRoot;
  bytes32 public guaranteedListMerkleRoot;
  bytes32 public publicListMerkleRoot;

  // Base URL for the NFT metadata
  string public baseURI = "ipfs://QmQWbny9K3dQBWYjMRiMt46b8uvSPUvkbQf2KfEyGkaUyb/";

  // Provenance hash
  string public PROVENCANCE_HASH = "3a0587f4ed9f89511c111510bdc1c5f8cb137e6d43512f8a946cdd4560afb9ac";

  // Number of Sneak tokens minted for every Relic Pass
  mapping(uint16 => uint8) public relicPassTokenUsage;

  // Number of tokens a wallet can still mint from the Discounted Sneaks List
  mapping(address => uint8) public discountedSneaksListTokens;

  // Whether a wallet has already minted from the Sneaks List
  mapping(address => bool) public isSneaksListUsed;

  // Whether a wallet has already minted from the GuaranteedAllowlist
  mapping(address => bool) public isGuaranteedAllowlistUsed;

  // Number of tokens a wallet has minted from the Public Waitlist
  mapping(address => uint16) public publicWaitlistTokens;

  // Cold wallet used for minting
  mapping(address => address) public coldWallets;

  event TokenMint(address indexed receiver, string indexed mintType, uint256 tokenAmount);

  function RELIC_PASS_REDUCED_PRICE() public pure virtual returns (uint256) {
    return 0.33 ether;
  }

  function DISCOUNTED_SNEAKS_LIST_PRICE() public pure virtual returns (uint256) {
    return 0.33 ether;
  }

  function SNEAKS_LIST_PRICE() public pure virtual returns (uint256) {
    return 0.4 ether;
  }

  function FULL_PRICE() public pure virtual returns (uint256) {
    return 0.45 ether;
  }

  constructor(
    address _RELIC_PASS_CONTRACT_ADDRESS,
    address _owner,
    bytes32 _sneaksListMerkleRoot,
    bytes32 _guaranteedListMerkleRoot,
    bytes32 _publicListMerkleRoot
  ) ERC721A("Sneaks of Nature", "SNEAKS") {
    // Check for plausible input
    require(_RELIC_PASS_CONTRACT_ADDRESS != address(0), "Invlaid address for the Relic Pass contract");
    require(_owner != address(0), "Invlaid owner address");

    // Set the address of the Relic Pass token contract
    RELIC_PASS_CONTRACT_ADDRESS = _RELIC_PASS_CONTRACT_ADDRESS;

    // Set the royalties to the owner
    _setDefaultRoyalty(_owner, 750);

    // Premint the first tokens to the owner
    _safeMint(_owner, PREMINT_TOKEN_COUNT);

    // Set the Merkle tree roots
    sneaksListMerkleRoot = _sneaksListMerkleRoot;
    guaranteedListMerkleRoot = _guaranteedListMerkleRoot;
    publicListMerkleRoot = _publicListMerkleRoot;

    // Initialize the Discounted Sneaks List
    initDiscountedSneaksList();

    // Transfer the ownership to the specified owner
    transferOwnership(_owner);
  }

  function checkAndUseMints(address receiver, uint16 tokensToMint) internal returns (uint256) {
    uint256 price = 0;

    uint16[] memory receiverRelicPassIDs = IMetarelics(RELIC_PASS_CONTRACT_ADDRESS).walletOfOwner(receiver);
    uint16 relicPassesCount = uint16(receiverRelicPassIDs.length);

    // Check the free Relic Pass tokens
    for (uint16 i = 0; i < relicPassesCount; ++i) {
      uint16 relicPassID = receiverRelicPassIDs[i];

      if (relicPassTokenUsage[relicPassID] == 0) {
        relicPassTokenUsage[relicPassID] = 1;
        --tokensToMint;
      }

      if (tokensToMint == 0) return price;
    }

    // Check the discounted Sneaks List tokens
    uint16 discountedSneaksListMints = discountedSneaksListTokens[receiver];
    uint16 discountedSneaksListMintsToUse = discountedSneaksListMints > tokensToMint
      ? tokensToMint
      : discountedSneaksListMints;

    price += discountedSneaksListMintsToUse * DISCOUNTED_SNEAKS_LIST_PRICE();
    tokensToMint -= discountedSneaksListMintsToUse;
    discountedSneaksListTokens[receiver] -= uint8(discountedSneaksListMintsToUse);

    if (tokensToMint == 0) return price;

    // Check the discounted Relic Pass tokens
    for (uint16 i = 0; i < relicPassesCount; ++i) {
      uint16 relicPassID = receiverRelicPassIDs[i];

      if (relicPassTokenUsage[relicPassID] <= 1) {
        relicPassTokenUsage[relicPassID] = 2;
        price += RELIC_PASS_REDUCED_PRICE();
        --tokensToMint;
      }

      if (tokensToMint == 0) return price;
    }

    revert("Not enough allowance to mint all requested tokens");
  }

  /**
   * @notice Relic Pass holders can use this method to purchase token form the contract.
   * For each relic pass token a user have, the user get 1 free Nature token and 2 extra Nature token,
   * 1 at RELIC_PASS_REDUCED_PRICE and 1 at RELIC_PASS_FULL_PRICE
   * @dev Mint a new token and update the used state of each relic pass token
   * @param receiver The holder of the relic pass token and the receiver of the newly minted nature token
   * @param tokenAmount The amount of paid nature token the sender wants to purchase. This free token is not included in the variable
   */
  function closedMint(address receiver, uint16 tokenAmount) external payable whenNotPaused nonReentrant {
    // Check if the public mint is active
    require(isMintActive, "Minting is disabled");
    require(block.timestamp >= closedMintStartTimestamp, "Minting is not open yet");

    // Check for plausible input
    require(receiver != address(0), "Receiver not a valid token address");
    require(tokenAmount != 0, "Token amount can not be zero");

    // Check that user can mint the specified amount of tokens
    require((_totalMinted() + tokenAmount) <= MAX_TOKEN_SUPPLY, "Not enought tokens left to mint");

    // Check if all tokens can already be minted and accumulate the total required
    uint256 requiredEther = checkAndUseMints(receiver, tokenAmount);

    // Check that the correct price is paid
    require(msg.value == requiredEther, "Incorrect amount of ether payed");

    // Check if a user is using a cold wallet
    if (receiver != msg.sender) {
      coldWallets[msg.sender] = receiver;
    }

    // Mint
    _safeMint(receiver, tokenAmount);
    emit TokenMint(receiver, "RELIC_PASS_MINT", tokenAmount);
  }

  /**
   * @notice Waitlisted public users can use this method to purchase Nature token at SNEAKS_LIST_PRICE.
   * @param receiver Address of the receiver of the minted token
   * @param proof An array of merkle proof of the sender, which is can be an array of zero bytes when waitlisting is off
   */
  function sneaksListMint(address receiver, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
    // Check if the public mint is active
    require(isMintActive, "Minting is disabled");
    require(block.timestamp >= closedMintStartTimestamp, "Minting is not open yet");

    // Check that the correct price is paid
    require(msg.value == SNEAKS_LIST_PRICE(), "Incorrect amount of ether payed");

    // Check that user is on the Guaranteed Allowlist and hasn't minted yet
    require(_verify(_leaf(receiver), proof, sneaksListMerkleRoot), "This wallet is not on the Sneaks List");
    require(!isSneaksListUsed[receiver], "This wallet has already minted from the Sneaks List");

    // Check that user can mint one more token
    require((_totalMinted() + 1) <= MAX_TOKEN_SUPPLY, "Not enought tokens left to mint");

    // Check if a user is using a cold wallet
    if (receiver != msg.sender) {
      coldWallets[msg.sender] = receiver;
    }

    // Mint
    isSneaksListUsed[receiver] = true;
    _safeMint(receiver, 1);
    emit TokenMint(receiver, "SNEAKS_LIST", 1);
  }

  /**
   * @notice Waitlisted public users can use this method to purchase Nature token at GUARANTEED_ALLOWLIST_PRICE.
   * @param receiver Address of the receiver of the minted token
   * @param proof An array of merkle proof of the sender
   */
  function guaranteedListMint(address receiver, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
    // Check if the public mint is active
    require(isMintActive, "Minting is disabled");
    require(block.timestamp >= closedMintStartTimestamp, "Minting is not open yet");

    // Check that the correct price is paid
    require(msg.value == FULL_PRICE(), "Incorrect amount of ether payed");

    // Check that user is on the Guaranteed Allowlist and hasn't minted yet
    require(
      _verify(_leaf(receiver), proof, guaranteedListMerkleRoot),
      "This wallet is not on the Guaranteed Allowlist"
    );
    require(!isGuaranteedAllowlistUsed[receiver], "This wallet has already minted from the Guaranteed Allowlist");

    // Check that user can mint one more token
    require((_totalMinted() + 1) <= MAX_TOKEN_SUPPLY, "Not enought tokens left to mint");

    // Check if a user is using a cold wallet
    if (receiver != msg.sender) {
      coldWallets[msg.sender] = receiver;
    }

    // Mint
    isGuaranteedAllowlistUsed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
    emit TokenMint(_msgSender(), "GUARANTEED_ALLOWLIST", 1);
  }

  /**
   * @notice Waitlisted public users can use this method to purchase Nature token at RELIC_PASS_FULL_PRICE.
   * The waitlisting feature of this method can be turned on or off by an Admin to allowed non waitlisted users
   * @dev To mint token when the waitlisting is enabled, you will have to calculate the merkle proof on the dApp
   * or pass an array of zero bytes if the waitlisting is disabled
   * @param receiver Address of the receiver of the minted tokens
   * @param proof An array of merkle proof of the sender, which is can be an array of zero bytes when waitlisting is off
   * @param tokenAmount Number of token to mint
   */
  function publicMint(
    address receiver,
    bytes32[] calldata proof,
    uint16 tokenAmount
  ) external payable whenNotPaused nonReentrant {
    // Check if the public mint is active
    require(isMintActive, "Minting is disabled");
    require(block.timestamp >= closedMintEndTimestamp, "Public minting is not open yet");

    // Check that the correct price is paid
    require(msg.value == tokenAmount * FULL_PRICE(), "Incorrect amount of ether payed");

    // Check that user can mint the specified amount of tokens
    require((_totalMinted() + tokenAmount) <= MAX_TOKEN_SUPPLY, "Not enought tokens left to mint");
    require(
      publicWaitlistTokens[receiver] + tokenAmount <= maxTokensPerUser,
      "User is not allowed to mint that many tokens"
    );

    // Check that the user is on the Public Waitlist if this is required
    if (isPublicWaitlistRequired) {
      require(_verify(_leaf(receiver), proof, publicListMerkleRoot), "This wallet is not on the Public Waitlist");
    }

    // Check if a user is using a cold wallet
    if (receiver != msg.sender) {
      coldWallets[msg.sender] = receiver;
    }

    // Mint
    _safeMint(_msgSender(), tokenAmount);
    publicWaitlistTokens[receiver] += tokenAmount;
    emit TokenMint(_msgSender(), "PUBLIC_MINT", tokenAmount);
  }

  //////////////////////////SETTERS/////////////////////////////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Set the royalty receiver and fee
   * @dev The fee should be in base point, so 10% should 10 * 100 which is 1000
   * @param receiver The receiver of the fee.
   * @param fee The fee sent to receiver.
   */
  function setDefaultRoyalty(address receiver, uint96 fee) external onlyOwner {
    _setDefaultRoyalty(receiver, fee);
  }

  /**
   * @notice Update the merkle root of the public waitlist
   * @param newMerkleRoot The new merkle root.
   */
  function setPublicListMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    publicListMerkleRoot = newMerkleRoot;
  }

  /**
   * @notice Update the merkle root of the sneaks list
   * @param newMerkleRoot The new merkle root.
   */
  function setSneaksListMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    sneaksListMerkleRoot = newMerkleRoot;
  }

  /**
   * @notice Update the merkle root of the guaranteed sneaks list
   * @param newMerkleRoot The new merkle root.
   */
  function setGuaranteedListMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    guaranteedListMerkleRoot = newMerkleRoot;
  }

  /**
   * @notice Switch on or of the waitlisting feature for public mint
   * @param value The value of the waitlist.
   */
  function setPublicWaitlistRequired(bool value) external onlyOwner {
    isPublicWaitlistRequired = value;
  }

  function setDiscountedSneaksListTokens(address _address, uint8 _tokenCount) external onlyOwner {
    discountedSneaksListTokens[_address] = _tokenCount;
  }

  /**
   * @notice Set the ghost protocol period. This is for allowing listing on exchanges
   * @param endTimestamp The end time of the ghost protocol.
   */
  function setGhostProtocolEnd(uint256 endTimestamp) external onlyOwner {
    require(
      closedMintEndTimestamp < endTimestamp,
      "The end of the Ghost protocol must be after the end of the closed mint"
    );

    ghostProtocolEndTimestamp = endTimestamp;
  }

  /**
   * @notice Set closed mint start and end period
   * @param startTimestamp The start time of the closed mint.
   * @param endTimestamp The end time of the closed mint.
   */
  function setClosedMintPeriod(uint256 startTimestamp, uint256 endTimestamp) external onlyOwner {
    require(startTimestamp < endTimestamp, "Start time must be less than end time");

    closedMintStartTimestamp = startTimestamp;
    closedMintEndTimestamp = endTimestamp;
  }

  /**
   * @notice Update the max mint token per user on the public mint
   * @param _maxTokensPerUser The new max mint amount for an address.
   */
  function setMaxTokensPerUser(uint16 _maxTokensPerUser) external onlyOwner {
    maxTokensPerUser = _maxTokensPerUser;
  }

  /**
   * @notice Set the minting as active or not
   * @param isActive Wether the mint is active or not.
   */
  function setMintActive(bool isActive) external onlyOwner {
    isMintActive = isActive;
  }

  event WithdrawFunds(address indexed receiver, uint256 amount);

  /**
   * @notice Withdraw ethers from the contract, this can only be called by an admin
   * @param receiver The receiver of the ethers in the contract.
   */
  function withdrawFunds(address payable receiver) external onlyOwner nonReentrant {
    require(receiver != address(0), "Not a valid address");
    require(address(this).balance > 0, "Contract have zero balance");

    (bool sent, ) = receiver.call{value: address(this).balance}("");
    require(sent, "Failed to send ether");
    emit WithdrawFunds(receiver, address(this).balance);
  }

  /**
   * @notice Change the base URI for the metadata
   * @param uri new base URI
   */
  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  //////////////////////////GETTERS////////////////////////////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Get total tokens minted
   */
  function mintedTokens() external view returns (uint256) {
    return _totalMinted();
  }

  /**
   * @notice Check if contract is in a closed mint period
   */
  function isClosedMint() external view returns (bool) {
    return (block.timestamp >= closedMintStartTimestamp && block.timestamp <= closedMintEndTimestamp);
  }

  /**
   * @notice Check if contract is in a public period
   */
  function isPublicMint() external view returns (bool) {
    return (block.timestamp >= closedMintEndTimestamp && block.timestamp <= ghostProtocolEndTimestamp);
  }

  /**
   * @notice Check if contract is in a Ghost protocol period
   */
  function isGhostProtocol() external view returns (bool) {
    return (block.timestamp >= closedMintStartTimestamp && block.timestamp <= ghostProtocolEndTimestamp);
  }

  /**
   * @notice Get the 6 last letters from `addr`.
   * @param addr The where the 6 letters are taken
   */
  function generateCode(address addr) internal pure returns (string memory) {
    return substring(addr, 36, 42);
  }

  /**
   * @dev Get the substring of `addr`.
   */
  function substring(
    address addr,
    uint256 startIndex,
    uint256 endIndex
  ) internal pure returns (string memory) {
    string memory addrToStr = Strings.toHexString(uint256(uint160(addr)), 20);
    bytes memory strBytes = bytes(addrToStr);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }

  //////////////////////////OVERRIDES////////////////////////////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Block the transfer of the token to another wallet when listing is turned off
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override whenNotPaused {
    // Block transfers before the end of the Ghost Protocol
    require(
      from == address(0) || block.timestamp > ghostProtocolEndTimestamp,
      string.concat("Reboot Failed :) Head to sneaksofnature.xyz for Ghost Protocol")
    );

    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /**
   * @notice Block the listing of the token on exchanges when listing is turned off
   */
  function approve(address to, uint256 tokenId) public virtual override(ERC721A) whenNotPaused {
    // Block approvals before the end of the Ghost Protocol
    require(
      block.timestamp > ghostProtocolEndTimestamp,
      string.concat("Reboot Failed :) Head to sneaksofnature.xyz for Ghost Protocol")
    );

    super.approve(to, tokenId);
  }

  /**
   * @notice Block the listing of the token on exchanges when listing is turned off
   */
  function setApprovalForAll(address operator, bool approved) public override(ERC721A) whenNotPaused {
    // Block approvals before the end of the Ghost Protocol
    require(
      block.timestamp > ghostProtocolEndTimestamp,
      string.concat("Reboot Failed :) Head to sneaksofnature.xyz for Ghost Protocol")
    );

    super.setApprovalForAll(operator, approved);
  }

  /**
   * @dev Pause the contract
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Unpause the contract
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev Get the base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev Return `account` hash in byte32
   */
  function _leaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  /**
   * @dev Verify leaf with the proof provided
   */
  function _verify(
    bytes32 leaf,
    bytes32[] memory proof,
    bytes32 root
  ) internal pure returns (bool) {
    return MerkleProof.verify(proof, root, leaf);
  }

  /**
   * @dev Override support interface for ERC721A and ERC2981
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  /**
   * @notice This function has been copied from the ERC721AQueryable contract
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K collections should be fine).
   */
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }

  /**
   * @notice Prevent users from sending eth directly to the contract
   */
  receive() external payable {
    revert();
  }

  function initDiscountedSneaksList() internal {
    discountedSneaksListTokens[address(0x1057B6adB95680C811c256A393F5C523d94fd6a6)] = 1;
    discountedSneaksListTokens[address(0xc970d150e79Dfe672332d4AF0902ef23955A189b)] = 2;
    discountedSneaksListTokens[address(0xDF850eECEB3e8Ce60494a3C654251668a578cD37)] = 1;
    discountedSneaksListTokens[address(0xa0cd2AFB3c842Be462ed213122bb040cce109862)] = 5;
    discountedSneaksListTokens[address(0x93E2D4b254E1f65ca88319F3F898137C7477D81A)] = 1;
    discountedSneaksListTokens[address(0x9C724A8662c3FBd4bF7fef8ff61a3983AA4A1296)] = 1;
    discountedSneaksListTokens[address(0xCa1B0e66035Dd3030532D5BA701d4bFdb935175c)] = 1;
    discountedSneaksListTokens[address(0x8392128FFcFb7ba23E3635A16bae81F98BbE9864)] = 1;
    discountedSneaksListTokens[address(0x4338c78860DAA6d5c5a6DfC7Ef14E25D852c2Cab)] = 1;
    discountedSneaksListTokens[address(0xaA90bd23Cc2def907Ef0ae74dAdBd65CB5D1e76c)] = 1;
    discountedSneaksListTokens[address(0xb462b634B076bfDb220A27A44a6d52812477dC9E)] = 1;
    discountedSneaksListTokens[address(0x699a4Fbf7f094cff9e894a83b9a599B03b2723A1)] = 1;
    discountedSneaksListTokens[address(0x10A89Ce08cf2cC53f0235F6bE35E453B400B90e4)] = 1;
    discountedSneaksListTokens[address(0x7BF7154B389Ed660eb05250646B67eB18Ec625c2)] = 1;
    discountedSneaksListTokens[address(0xBd72051F0CdD975F803fdc4810Cee6b96757A313)] = 11;
    discountedSneaksListTokens[address(0x601F6837094adFff82F1A25b19CB4a88c5B58EAE)] = 2;
    discountedSneaksListTokens[address(0x5c4345942d1B4c412c135D2FF225e15efF59Cc19)] = 3;
    discountedSneaksListTokens[address(0x7b1319a57e7E8a6e682Ba3534A1047692F047F96)] = 1;
    discountedSneaksListTokens[address(0x4c0df90a1807F4AAabA4FD7055b3F3B0B0FC069a)] = 1;
    discountedSneaksListTokens[address(0x5e818AC9d91382dA94F673E5EECabf0c6141079A)] = 3;
    discountedSneaksListTokens[address(0x046133B7A2a3DaA1D70cA5a375efd642266eDDf4)] = 1;
    discountedSneaksListTokens[address(0x0fF39CD18c4B1D113dbbf2D67D483B419C736714)] = 1;
    discountedSneaksListTokens[address(0x717BB98c2DE5d080F248fB12a73B5011B808d7B1)] = 1;
    discountedSneaksListTokens[address(0xf508Fd9A90B76a44096626C78918033cbaF18c70)] = 1;
    discountedSneaksListTokens[address(0x14e1293dF867D8368eE77f941aF6caA391b00a17)] = 1;
    discountedSneaksListTokens[address(0x562708d384eb5D1D80aAc7Bb4C81877A91ac287E)] = 1;
    discountedSneaksListTokens[address(0xDaB1eD5bf932FE97778CD8f87eF2D537DEd265fF)] = 1;
    discountedSneaksListTokens[address(0x3913f15F8eEd950427649803d2C188ac0c0bE8EE)] = 1;
    discountedSneaksListTokens[address(0x3C4Bc558d2a6467D0BFBE85e44DB10275f1e376B)] = 1;
    discountedSneaksListTokens[address(0x2aa13a1F65f4e9Fbd9A0fAF9DFC556CFF0ef09cA)] = 1;
    discountedSneaksListTokens[address(0x97e36e9Bd419B19b1969cd877098a93BFf5F0525)] = 1;
    discountedSneaksListTokens[address(0x7C3652fD197e2e9806CcEf8b48C0502DAA9c28D8)] = 1;
    discountedSneaksListTokens[address(0x105b892d27c556F3F28AB1522F612457A3E626b5)] = 1;
    discountedSneaksListTokens[address(0xbE193c8D426E3c9359179C7c232b13a0FEe62E86)] = 1;
    discountedSneaksListTokens[address(0x67Fa44C002d1315d6BaBdB6Aea6532a4173Ef1cb)] = 1;
    discountedSneaksListTokens[address(0x7324E7Cf1e07C12Ef854Bb17B79bF7D2aA3775F5)] = 1;
    discountedSneaksListTokens[address(0xa2a9234dd5Db7be6c31372b51F2B1328cF28b407)] = 1;
    discountedSneaksListTokens[address(0x2eE5Cb572fF2d01BBa4263b72364756719682362)] = 1;
    discountedSneaksListTokens[address(0x11E03AAf494ae914716f401B4C7e6058c2735943)] = 1;
    discountedSneaksListTokens[address(0x81760A4e204A627DaC0c2FF964A3A8a179Dc0caF)] = 1;
    discountedSneaksListTokens[address(0x74b232d3A4E8CE1CC3345D1046c3dfE8581DB06e)] = 1;
    discountedSneaksListTokens[address(0x1F4c68bB9A4e35A10B994950E2783d788DB2C7E7)] = 1;
    discountedSneaksListTokens[address(0x77c2EA028Db3DC863B1FA3d237A4A2719ea1f6ED)] = 1;
    discountedSneaksListTokens[address(0x177BC0Ac7331d0ce69b919D44C2d345a3Ce76eC6)] = 1;
    discountedSneaksListTokens[address(0x060D76ae0de96734977f41506eeC5737aF9C1B45)] = 1;
    discountedSneaksListTokens[address(0x10d34d3cb24b38C11bbc30180Ec7153e3a69594b)] = 1;
    discountedSneaksListTokens[address(0xA7709793F19E618682cEf261002CB857086633a5)] = 1;
    discountedSneaksListTokens[address(0x803341e485565680E44c5f4275164EB0bB34552c)] = 1;
    discountedSneaksListTokens[address(0xc1c7Ccb3a45884274AcCc7ef7A528520C91e55d2)] = 1;
  }
}