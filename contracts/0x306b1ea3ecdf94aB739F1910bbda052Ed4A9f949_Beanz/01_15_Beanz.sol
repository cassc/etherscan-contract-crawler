// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './MultisigOwnable.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

error BeanCannotBeClaimed();
error ClaimWindowNotOpen();
error MismatchedTokenOwner();
error MaxSupplyReached();
error TokenAlreadyWon();
error AddressAlreadyWonOrOwner();
error RaffleWinnerIsContract();
error ChunkHasBeenAirdropped();
error AzukiNotOwnedLongEnough();
error InvalidChunk();

interface Azuki {
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory);
}

contract Beanz is ERC721A, MultisigOwnable, VRFConsumerBaseV2 {
  using Address for address;

  event RaffleWinner(
    uint256 winningTokenId,
    address winningAddress,
    uint256 newTokenId
  );

  uint256 public immutable maxSupply;
  uint256 public constant BATCH_SIZE = 6;
  uint256 public constant MIN_OWNERSHIP_TIME_FOR_CLAIM = 120;

  struct ClaimWindow {
    uint128 startTime;
    uint128 endTime;
  }

  ClaimWindow public claimWindow;
  Azuki public immutable azuki;

  // Keys are azuki token ids
  mapping(uint256 => bool) public azukiCanClaim;

  // Keys are this collection's ids
  mapping(uint256 => bool) public tokenHasWonRaffle;

  mapping(address => bool) public winningAddresses;
  mapping(uint256 => bool) processedChunksForAirdrop;

  string private _baseTokenURI;

  // Chainlink Settings
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  struct CLRequestConfig {
    bytes32 keyHash;
    uint64 subscriptionId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
  }
  CLRequestConfig public clRequestConfig;

  constructor(
    address _azukiAddress,
    uint256 _maxSupply,
    address _vrfCoordinator,
    address _linkToken,
    string memory initialName,
    string memory initialSymbol
  ) ERC721A('Beanz', 'BEANZ') VRFConsumerBaseV2(_vrfCoordinator) {
    azuki = Azuki(_azukiAddress);
    maxSupply = _maxSupply;
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(_linkToken);
    _nameOverride = initialName;
    _symbolOverride = initialSymbol;
  }

  function airdrop(
    address[] calldata receivers,
    uint256[] calldata numAzukiTokens,
    uint256 chunkNum
  ) external onlyRealOwner {
    if (processedChunksForAirdrop[chunkNum] || balanceOf(receivers[0]) > 0) {
      revert ChunkHasBeenAirdropped();
    }
    if (receivers.length != numAzukiTokens.length) {
      revert InvalidChunk();
    }
    for (uint256 i; i < receivers.length; ++i) {
      _mintWrapper(receivers[i], numAzukiTokens[i]);
    }
    processedChunksForAirdrop[chunkNum] = true;
  }

  // Used to claim unclaimed tokens after airdrop/claim phase
  function devClaim(uint256 numAzukiTokens) external onlyRealOwner {
    _mintWrapper(msg.sender, numAzukiTokens);
  }

  function claim(uint256[] calldata azukiTokenIds) external {
    ClaimWindow memory window = claimWindow;
    uint256 curTime = block.timestamp;
    if (
      curTime < uint256(window.startTime) || curTime > uint256(window.endTime)
    ) {
      revert ClaimWindowNotOpen();
    }

    for (uint256 i; i < azukiTokenIds.length; ++i) {
      uint256 azukiId = azukiTokenIds[i];

      Azuki.TokenOwnership memory tokenOwnership = azuki.getOwnershipData(
        azukiId
      );
      address tokenOwner = tokenOwnership.addr;
      if (tokenOwner != msg.sender) revert MismatchedTokenOwner();
      if (!azukiCanClaim[azukiId]) revert BeanCannotBeClaimed();
      uint256 ownershipStart = uint256(tokenOwnership.startTimestamp);
      // Prevent flash loans
      if (block.timestamp - ownershipStart < MIN_OWNERSHIP_TIME_FOR_CLAIM) {
        revert AzukiNotOwnedLongEnough();
      }
      azukiCanClaim[azukiId] = false;
    }
    _mintWrapper(msg.sender, azukiTokenIds.length);
  }

  function _mintWrapper(address to, uint256 numAzukiTokens) internal {
    uint256 numToMint = numAzukiTokens * 2;
    if (totalSupply() + numToMint > maxSupply) {
      revert MaxSupplyReached();
    }
    uint256 numBatches = numToMint / BATCH_SIZE;
    for (uint256 i; i < numBatches; ++i) {
      _mint(to, BATCH_SIZE, '', true);
    }
    if (numToMint % BATCH_SIZE > 0) {
      _mint(to, numToMint % BATCH_SIZE, '', true);
    }
  }

  function requestRaffleWinner() external onlyRealOwner returns (uint256) {
    if (totalSupply() + 1 > maxSupply) {
      revert MaxSupplyReached();
    }

    CLRequestConfig memory rc = clRequestConfig;
    uint256 requestId = COORDINATOR.requestRandomWords(
      rc.keyHash,
      rc.subscriptionId,
      rc.requestConfirmations,
      rc.callbackGasLimit,
      uint32(1)
    );
    return requestId;
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    // Use the random value from Chainlink
    uint256 winningTokenId = randomWords[0] % _totalMinted();

    if (tokenHasWonRaffle[winningTokenId]) {
      revert TokenAlreadyWon();
    }
    address winningAddress = ownerOf(winningTokenId);
    if (winningAddress == owner() || winningAddresses[winningAddress]) {
      revert AddressAlreadyWonOrOwner();
    } else if (winningAddress.isContract()) {
      revert RaffleWinnerIsContract();
    }
    tokenHasWonRaffle[winningTokenId] = true;
    winningAddresses[winningAddress] = true;

    // Send new token to winner and mark their token/address as won
    if (totalSupply() + 1 > maxSupply) {
      revert MaxSupplyReached();
    }
    _mint(winningAddress, 1, '', false);
    // The winner is the last index which needs to be marked as invalid for the raffle
    uint256 newTokenId = _totalMinted() - 1;
    tokenHasWonRaffle[newTokenId] = true;

    emit RaffleWinner(winningTokenId, winningAddress, newTokenId);
  }

  function setClRequestConfig(
    bytes32 _keyHash,
    uint64 _subscriptionId,
    uint16 _requestConfirmations,
    uint32 _callbackGasLimit
  ) external onlyRealOwner {
    clRequestConfig.keyHash = _keyHash;
    clRequestConfig.subscriptionId = _subscriptionId;
    clRequestConfig.requestConfirmations = _requestConfirmations;
    clRequestConfig.callbackGasLimit = _callbackGasLimit;
  }

  function setClaimWindow(uint128 _startTime, uint128 _endTime)
    external
    onlyRealOwner
  {
    claimWindow.startTime = _startTime;
    claimWindow.endTime = _endTime;
  }

  function setCanClaim(uint256[] calldata azukiIds) external onlyRealOwner {
    for (uint256 i; i < azukiIds.length; ++i) {
      azukiCanClaim[azukiIds[i]] = true;
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  string private _nameOverride;
  string private _symbolOverride;

  function name() public view override returns (string memory) {
    if (bytes(_nameOverride).length == 0) {
      return ERC721A.name();
    }
    return _nameOverride;
  }

  function symbol() public view override returns (string memory) {
    if (bytes(_symbolOverride).length == 0) {
      return ERC721A.symbol();
    }
    return _symbolOverride;
  }

  function setNameAndSymbol(
    string calldata _newName,
    string calldata _newSymbol
  ) external onlyRealOwner {
    _nameOverride = _newName;
    _symbolOverride = _newSymbol;
  }
}