// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract WeApes is ERC721A, Ownable, VRFConsumerBase {
  uint256 public price = 0.042 ether;
  uint256 constant _maxSupply = 6970;
  bytes32 internal keyHash;
  uint256 internal fee;
  bool public isSaleActive;
  uint256 public saleTimestamp;

  struct Prize {
    bool active;
    uint16 prizeId;
    address tokenAddress;
    uint256 tokenId;
  }

  struct Burning {
    uint16 prizeId;
    address owner;
  }

  uint16 public ticketsPerBurn;

  address[] public tickets;
  Prize public currentPrize;

  address tokensHolder;

  event Raffle(address winner, uint256 ticketsCount);

  constructor(address _tokensHolder, address _vrf, address _link, bytes32 _keyHash, uint256 _fee) ERC721A("WeApes", "WAGMI") VRFConsumerBase(_vrf, _link) {
    tokensHolder = _tokensHolder;
    keyHash = _keyHash;
    fee = _fee;
  }

  function maxSupply() external pure returns (uint256) {
    return _maxSupply - 1;
  }

  function ticketsOfOwner(address user) public view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < tickets.length; i++) {
      if (tickets[i] == user) {
        count++;
      }
    }
    return count * ticketsPerBurn + balanceOf(user);
  }

  function allTokensOfOwner(address user) public view returns (uint256[] memory) {
    uint256[] memory allTokens = new uint256[](balanceOf(user));
    for (uint16 i = 0; i < allTokens.length; i++) {
      allTokens[i] = tokenOfOwnerByIndex(user, i);
    }
    return allTokens;
  }

  function totalTickets() public view returns (uint256) {
    return liveSupply() + tickets.length * ticketsPerBurn;
  }

  function liveSupply() public view returns (uint256) {
    return currentIndex - balanceOf(address(this));
  }

  function whitelistMint(bytes memory signature, uint16 whitelistId, uint256 amount, uint8 free) public payable {
    require(isSaleActive, "Sale is not active yet");
    address minter = _msgSender();
    require(tx.origin == minter, "Contracts not allowed");
    require(currentIndex + amount < _maxSupply, "Sold out");
    require(amount <= 10, "Maximum per tx exceeded");
    require(free == 0 || amount == 1, "Maximum per tx exceeded");
    require(free == 1 || price * amount == msg.value, "You must send enough eth");
    require(_numberMinted(minter) + amount < 11, "You can't mint that amount during presale");

    bytes32 messageHash = keccak256(abi.encodePacked("wagmi", msg.sender, whitelistId, free));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature");

    _safeMint(minter, amount);
  }

  function mint(uint256 amount) public payable {
    require(isSaleActive && saleTimestamp < block.timestamp, "Sale is not active yet");
    address minter = _msgSender();
    require(currentIndex + amount < _maxSupply, "Sold out");
    require(tx.origin == minter, "Contracts not allowed");
    require(price * amount <= msg.value, "You must send enough eth");
    require(amount <= 10, "Maximum per tx exceeded");

    _mint(minter, amount, '', false);
  }

  function burnForTickets(uint256 tokenId) public {
    require(currentPrize.active, "Raffle not in progress");
    burn(tokenId);

    tickets.push(msg.sender);
  }

  function setTokensHolder(address _t) public onlyOwner {
    tokensHolder = _t;
  }

  function startRaffle(uint16 _ticketsPerBurn, address tokenAddress, uint256 tokenId) public onlyOwner {
    require(!currentPrize.active, "Raffle in progress");
    IERC721 tokenContract = IERC721(tokenAddress);
    require(tokenContract.ownerOf(tokenId) == tokensHolder, "Must have token");
    require(tokenContract.isApprovedForAll(tokensHolder, address(this)), "Must have approval");

    ticketsPerBurn = _ticketsPerBurn;
    currentPrize = Prize(true, currentPrize.prizeId + 1, tokenAddress, tokenId);
    delete tickets;
  }

  function cancelRaffle() public onlyOwner {
    require(currentPrize.active, "Raffle in progress");
    currentPrize.active = false;
  }

  function pickAWinner() public onlyOwner {
    require(currentPrize.active, "No prize");
    IERC721 tokenContract = IERC721(currentPrize.tokenAddress);
    require(tokenContract.ownerOf(currentPrize.tokenId) == tokensHolder, "Must have token");
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    requestRandomness(keyHash, fee);
  }

  function toggleSaleStatus(uint256 m) public onlyOwner {
    isSaleActive = !isSaleActive;
    if (isSaleActive) {
      saleTimestamp = block.timestamp + m  * 1 minutes;
    }
  }

  function setPrice(uint256 _p) public onlyOwner {
    price = _p;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function mintAsOwner(address to, uint8 amount) public onlyOwner {
    require(currentIndex + amount < _maxSupply, "Sold out");
    _mint(to, amount, '', false);
  }

  function getTokenOwner(uint256 seed) public view returns (address) {
    while (true) {
      uint256 tokenId = seed;
      address o = ownerOf(tokenId);
      if (o != address(this)) {
        return o;
      }
      seed = (tokenId + 1) % currentIndex;
    }
    return address(0);
  }

  function getTicket(uint256 seed) public view returns (address) {
    return tickets[seed % tickets.length];
  }

  function burn(uint256 tokenId) internal {
    transferFrom(msg.sender, address(this), tokenId);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    IERC721 tokenContract = IERC721(currentPrize.tokenAddress);
    uint256 seed = randomness % totalTickets();
    uint256 supply = liveSupply();
    address recipient = seed < supply ? getTokenOwner(seed) : getTicket(seed - supply);
    tokenContract.transferFrom(tokensHolder, recipient, currentPrize.tokenId);
    currentPrize.active = false;
    emit Raffle(recipient, totalTickets());
  }

  function _baseURI() internal pure override returns (string memory) {
    return "ipfs://QmSSAjR6jGCBKwebGpGhye7gGMByWo1Pma6NFxst7GxEKo/";
  }
}