// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

// Truffle
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/v0.6/ChainlinkClient.sol";
// import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// Modified VRFConsumerBase to not conflict with ChainlinkClient.
import "./VRFConsumerBase.sol";

// Remix
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC721/ERC721.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Counters.sol";
//import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";
//import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract CryptoTrunks is ERC721, Ownable, ChainlinkClient, VRFConsumerBase {
  using Counters for Counters.Counter;

  // Pausable.
  bool private _paused;

  // Represents a minting user, for lookup from Chainlink fulfill.
  struct User {
    uint256 tokenId;
    address addr;
  }

  // Generative
  uint16 constant private generativeSupply = 19500;
  Counters.Counter private generativeMinted;

  // Genesis
  uint16 constant private genesisSupply = 1500;
  Counters.Counter private genesisMinted;

  uint256 constant private genesisPrime = 22801763477; // Prime chosen at random (10 millionth)

  // Chainlink internals.
  address private oracle;
  bytes32 private jobId;
  uint256 private fee;

  // Chainlink VRF constants.
  bytes32 internal keyHash;
  uint256 internal vrfFee;

  // Returned from VRF.
  uint256 private genesisRandomSeed;

  // Mapping from Chainlink `requestId` to the user who triggered it.
  mapping (bytes32 => User) private users;

  // Mapping from address to the fee the user will pay next.
  mapping (address => uint256) private nextFeeTiers;

  // Mapping from address to minted count.
  mapping (address => uint16) private mintedCount;

  // Events
  event RemoteMintFulfilled(bytes32 requestId, uint256 tokenId, uint256 resultId);
  event RemoteMintTwentyFulfilled(bytes32 requestId, uint256 firstTokenId, uint256 resultId);

  /**
   * Constructor
   */

  // TODO: Change VRFConsumerBase to mainnet .
  constructor() public
    ERC721("CryptoTrunks", "CT")
    VRFConsumerBase(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
      0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
  {

    // Metadata setup.
    _setBaseURI("https://service.cryptotrunks.co/token/");

    // Chainlink setup.
    setPublicChainlinkToken();

    // Our node
    // oracle = 0xDAca12D022D5fe11c857d6f583Bb43D01a8f5B73;
    // jobId = "d562d13f83a947d4bb720be4a2682978";
    // fee = 1 * 10 ** 18; // 1 * 10 ** 18 = 1 Link

    // Kovan
    // oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
    // jobId = "c7dd72ca14b44f0c9b6cfcd4b7ec0a2c";
    // fee = 0.1 * 10 ** 18; // 1 * 10 ** 18 = 1 Link

    // VRF setup.
    // Kovan network.
    // TODO: Change this to mainnet
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    vrfFee = 2 * 10 ** 18; // 1 * 10 ** 18 = 1 Link
  }


  /**
   * Payout
   */

  function withdraw() external onlyOwner {
    address payable payableOwner = payable(owner());
    payableOwner.transfer(address(this).balance);
  }

  function withdrawLink() external onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    address payable payableOwner = payable(owner());
    link.transfer(payableOwner, link.balanceOf(address(this)));
  }


  /**
   * Pausing
   */

  function paused() external view returns (bool) {
    return _paused;
  }

  function togglePaused() external onlyOwner {
    _paused = !_paused;
  }


  /**
   * Updating Oracle
   */

  function getOracle() external view returns (address, bytes32, uint256) {
    return (oracle, jobId, fee);
  }

  function updateOracle(address _oracle, bytes32 _jobId, uint256 _fee) external onlyOwner {
    oracle = _oracle;
    jobId = _jobId;
    fee = _fee;
  }


  /**
   * Methods for Web3
   */

  function getGenerativeMinted() external view returns (uint256) {
    return generativeMinted.current();
  }

  function getGenesisMinted() external view returns (uint256) {
    return genesisMinted.current();
  }

  function getGenesisRandomSeed() external view returns (uint256) {
    return genesisRandomSeed;
  }


  /**
   * Generative minting
   */

  function mintTrunk(uint256 randomSeed, bool isBasic) external payable returns (uint256 tokenId) {
    // Enforce tiered fees.
    require(msg.value >= getBaseFeeTier());
    require(msg.value >= getFeeTier());

    // In pause, prevent "free" mints.
    if (_paused) {
      require(msg.value >= (0.05 ether));
    }

    // Update minted count.
    mintedCount[msg.sender] = (mintedCount[msg.sender] + 1);

    // Limit supply.
    require(generativeMinted.current() < generativeSupply); // 0 ..< 19,500
    generativeMinted.increment(); // Start at 1 (tokens 1 ..< 19,501)

    // Get current token, starting after the last genesis trunk (i.e. 1,501).
    uint256 _tokenId = genesisSupply + generativeMinted.current(); // 1,501 ..< 21,001

    // Mint token itself.
    _safeMint(msg.sender, _tokenId);

    // In order to save Link for the most basic combination (Sapling + Noon),
    // we skip remoteMint, since no-one would fake the most basic level.
    if (isBasic) {
      // Skip oracle step for basic trunks.
      // Since we aren't storing this with the oracle, set the seed as the token URI.
      completeMint(0x00, _tokenId, randomSeed);
    } else {
      // Generate art on remote URL.
      bytes32 requestId = remoteMint(randomSeed, _tokenId);

      // Store token to mapping for when request completes.
      users[requestId] = User(_tokenId, msg.sender);
    }

    // Returned so web3 can filter on it.
    return _tokenId;
  }

  function mintTwentyTrunks() external payable returns (uint256 tokenId) {
    // Enforce tiered fees.
    require(msg.value >= 1 ether);

    // Limit supply.
    require(generativeMinted.current() + 20 <= generativeSupply);

    // First token ID, one more than current.
    uint256 firstTokenId = genesisSupply + generativeMinted.current() + 1;

    for (uint8 i = 0; i < 20; i++) {
      // Mint token itself.
      generativeMinted.increment();
      _safeMint(msg.sender, (genesisSupply + generativeMinted.current()));
    }

    // Generate art (x20) on remote URL.
    bytes32 requestId = remoteMintTwenty(firstTokenId);

    // Store token to mapping for when request completes.
    users[requestId] = User(firstTokenId, msg.sender);

    // Returned so web3 can filter on it.
    return firstTokenId;
  }

  function getFeeTier() public view returns (uint256 feeTier) {
    // Fee tier generated from value returned from our service.
    uint256 nextFeeTier = nextFeeTiers[msg.sender];
    if (nextFeeTier == 0) {
      return 0;
    } else {
      return nextFeeTier;
    }
  }

  function getBaseFeeTier() public view returns (uint256 baseFeeTier) {
    // Fallback check to guard the base price.
    uint16 minted = mintedCount[msg.sender];
    if (minted == 0) {
      return 0;
    } else {
      // Multiplier is divided by 10 at the end to avoid floating point.
      uint256 multiplier = 10;
      if (minted < 5) {
        multiplier = 10;
      } else if (minted < 20) {
        multiplier = 15;
      } else if (minted < 50) {
        multiplier = 20;
      } else if (minted < 100) {
        multiplier = 25;
      } else {
        multiplier = 30;
      }
      return ((0.05 ether) * multiplier) / 10;
    }
  }


  /**
   * Genesis minting
   */

  function mintGenesisTrunk(uint256 numberToMint) external payable returns (uint256[] memory tokenIds) {
    // Minting constraints.
    require(numberToMint >= 1);
    require(numberToMint <= 20);
    require(numberToMint <= (genesisSupply - genesisMinted.current()));

    // Ensure we collect enough eth!
    require(msg.value >= (0.5 ether) * numberToMint);

    // Loop minting.
    uint256[] memory _tokenIds = new uint256[](numberToMint);
    for (uint256 i = 0; i < numberToMint; i++) {
      uint256 tokenId = mintGenesisTrunk();
      _tokenIds[i] = tokenId;
    }

    return _tokenIds;
  }

  function mintGenesisTrunk() private returns (uint256 tokenId) {
    // Limit supply.
    require(genesisMinted.current() < genesisSupply); // 0 ..< 1,500
    genesisMinted.increment(); // Start at 1 (tokens 1 ..< 1,501)

    // Check we seeded the genesis random seed.
    require(genesisRandomSeed != 0);

    // Get current token.
    // Turns 1 ..< 1,501 into a random (but unminted) number in that range.
    uint256 _tokenId = getRandomGenesisTrunk(genesisMinted.current());

    // Mint token itself.
    _safeMint(msg.sender, _tokenId);

    // Returned so web3 can filter on it.
    return _tokenId;
  }

  // Required to be called before first mint to populate genesisRandomSeed.
  function fetchGenesisSeedFromVRF() external onlyOwner {
    getRandomNumber();
  }

  // "Shuffles" our list, from random seed, without using much storage, starting at 1.
  // This works because (a x + b) modulo n visits all integers in 0..<n exactly once
  // as x iterates through the integers in 0..<n, so long as a is coprime with n.
  function getRandomGenesisTrunk(uint256 index) private view returns (uint256) {
    return (((index * genesisPrime) + genesisRandomSeed) % genesisSupply) + 1;
  }

  // Updates
  function setBaseURI(string calldata baseURI_) external onlyOwner {
    // Allows us to update the baseURI after deploy, so we can move to IPFS if we choose to.
    _setBaseURI(baseURI_);
  }


  /**
   * Chainlink fetch
   */

  // Regular

  function remoteMint(uint256 randomSeed, uint256 tokenId) private returns (bytes32 requestId) {
    // Make the Chainlink request.
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    string memory url = string(
      abi.encodePacked(
        "https://service.cryptotrunks.co/mint?address=", toString(msg.sender),
        "&seed=", randomSeed.toString(),
        "&token=", tokenId.toString()
      )
    );
    request.add("get", url);
    request.add("path", "result"); // jsonpath.com
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  function fulfill(bytes32 _requestId, uint256 _resultId) public recordChainlinkFulfillment(_requestId) {
    require(_resultId > 0);

    // Retrieve user from mapping.
    User memory user = users[_requestId];
    require(user.addr != address(0));

    // _resultId is made up of returned token id + next minting fee.
    // e.g. if token = 1234 and fee = 0.15 ether, oracle returns 1234150.
    // Inlined below to save space.
    // uint256 returnedFeeTier = _resultId % 1000; // Get last digits.
    // uint256 returnedTokenId = _resultId / 1000; // Get other digits.

    // Store tree age for future mints.
    nextFeeTiers[user.addr] = ((_resultId % 1000) * 1 ether) / 1000;

    completeMint(_requestId, user.tokenId, (_resultId / 1000));
  }

  function completeMint(bytes32 _requestId, uint256 _tokenId, uint256 _returnedTokenId) private {
    // Update our token URI in case it changed.
    _setTokenURI(_tokenId, _returnedTokenId.toString());

    // Emit event for Web3.
    emit RemoteMintFulfilled(_requestId, _tokenId, _returnedTokenId);
  }

  // Minting 20 ("Gamble")

  function remoteMintTwenty(uint256 tokenId) private returns (bytes32 requestId) {
    // Make the Chainlink request.
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillTwenty.selector);
    string memory url = string(
      abi.encodePacked(
        "https://service.cryptotrunks.co/mint_twenty?address=", toString(msg.sender),
        "&token=", tokenId.toString()
      )
    );
    request.add("get", url);
    request.add("path", "result"); // jsonpath.com
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  function fulfillTwenty(bytes32 _requestId, uint256 _resultId) public recordChainlinkFulfillment(_requestId) {
    require(_resultId > 0);

    // Retrieve user from mapping.
    User memory user = users[_requestId];
    require(user.addr != address(0));

    // Gambling doesn't affect fee tier.

    // Since we can't afford the gas, the service will assume token ID is the baseURI,
    // i.e. we're not going make 20 _setTokenURI() calls here.

    // Emit event for Web3.
    emit RemoteMintTwentyFulfilled(_requestId, user.tokenId, _resultId);
  }


  /**
   * Chainlink VRF
   */

  function getRandomNumber() private returns (bytes32 requestId) {
    // Only permit if this has never been run.
    require(genesisRandomSeed == 0);

    return requestRandomness(keyHash, vrfFee, block.number);
  }

  function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
    genesisRandomSeed = randomness;
  }


  /**
   * Utils
   */

  function toString(address account) private pure returns (string memory) {
    return toString(abi.encodePacked(account));
  }

  // https://ethereum.stackexchange.com/a/58341/68257
  function toString(bytes memory data) private pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }
}