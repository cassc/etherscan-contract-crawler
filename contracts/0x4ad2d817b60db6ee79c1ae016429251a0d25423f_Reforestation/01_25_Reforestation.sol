// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

// Truffle
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/v0.6/ChainlinkClient.sol";

contract Reforestation is ERC721, Ownable, ChainlinkClient {
  using Counters for Counters.Counter;

  // Pausable.
  bool private _paused;

  // Represents a minting user, for lookup from Chainlink fulfill.
  struct User {
    uint256 tokenId;
    address addr;
  }

  // Generative
  uint16 constant private generativeSupply = 2500;
  Counters.Counter private generativeMinted;

  // Chainlink internals.
  address private oracle;
  bytes32 private jobId;
  uint256 private fee;

  // Mapping from Chainlink `requestId` to the user who triggered it.
  mapping (bytes32 => User) private users;

  // Mapping from address to the fee the user will pay next.
  mapping (address => uint256) private nextFeeTiers;

  // Mapping from address to minted count.
  mapping (address => uint16) private mintedCount;

  // Events
  event RemoteMintFulfilled(address sender, bytes32 requestId, uint256 tokenId, uint256 resultId);

  /**
   * Constructor
   */

  // TODO: Change VRFConsumerBase to mainnet .
  constructor() public ERC721("CryptoTrunks", "CT") {

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

    // LinkPool mainnet
    oracle = 0x5C034E3beDb7D06Bd102Fc483Cf017Bf9f90DA60;
    jobId = "5c592c7039314fc1b303c9f95f70612e";
    fee = 1; // Smallest unit.
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


  /**
   * Generative minting
   */

  function mintTrunk(uint256 randomSeed) external payable returns (uint256 tokenId) {
    // Enforce tiered fees.
    require(msg.value >= getBaseFeeTier());
    require(msg.value >= getFeeTier());

    // Pausing mints.
    require(!_paused);

    // Update minted count.
    mintedCount[msg.sender] = (mintedCount[msg.sender] + 1);

    // Limit supply.
    require(generativeMinted.current() < generativeSupply);
    generativeMinted.increment();

    // Get current token.
    uint256 _tokenId = generativeMinted.current();

    // Mint token itself.
    _safeMint(msg.sender, _tokenId);

    // Generate art on remote URL.
    bytes32 requestId = remoteMint(randomSeed, _tokenId);

    // Store token to mapping for when request completes.
    users[requestId] = User(_tokenId, msg.sender);

    // Returned so web3 can filter on it.
    return _tokenId;
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
        "https://service.cryptotrunks.co/reforest?address=", toString(msg.sender),
        "&seed=", randomSeed.toString(),
        "&token=", tokenId.toString(),
        "&fee=", msg.value.toString()
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
    emit RemoteMintFulfilled(msg.sender, _requestId, _tokenId, _returnedTokenId);
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