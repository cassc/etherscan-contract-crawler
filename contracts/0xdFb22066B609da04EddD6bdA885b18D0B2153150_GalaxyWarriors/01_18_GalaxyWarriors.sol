// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GalaxyWarriors is ERC721Enumerable, Ownable, AccessControl {
  using Strings for uint256;

  bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
  uint256 public constant PRICE = 0.18 ether;
  uint256 public constant PRESALE_PRICE = 0.07 ether;
  uint256 public constant TOTAL_NUMBER_OF_GALAXY_WARRIORS = 9999;
  uint256 public constant GALAXY_AIRDROP_ID = 0;

  uint256 public constant PUBLIC_SALE_MAX_MINT_AMOUNT_PER_CALL = 5;
  uint256 public constant PUBLIC_SALE_MAX_MINT_AMOUNT_PER_WALLET = 5;

  uint256 public totalGiveawayReserved = 130;
  bool public isMintActive = false;
  bool public isPreMintActive = false;
  string private _baseTokenURI = "";

  address mb = 0xDfa857c95608000B46315cdf54Fe1efcF842ab89;

  mapping(address => uint32) public mints;

  // withdraw addresses
  PaymentSplitter splitter;

  // Airdrop token address
  address galaxyAirdropAddress = address(0);

  modifier whenMintActive() {
    require(isMintActive, "GalaxyWarriors: mint is not active");
    _;
  }

  modifier whenPreMintActive() {
    require(isPreMintActive, "GalaxyWarriors: pre mint is not active");
    _;
  }

  event MintActivation(bool isActive);

  event PremintActivation(bool isActive);

  constructor(
    string memory _name,
    string memory _symbol,
    address payable _splitter
  ) ERC721(_name, _symbol) {
    splitter = PaymentSplitter(_splitter);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, mb);

    _setupRole(WHITE_LIST_ROLE, msg.sender);
    _setupRole(WHITE_LIST_ROLE, mb);
  }

  fallback() external payable {}

  receive() external payable {}

  function mint(uint32 numberToMint) external payable whenMintActive {
    uint256 supply = totalSupply();
    require(
      numberToMint <= PUBLIC_SALE_MAX_MINT_AMOUNT_PER_CALL,
      "GalaxyWarriors: Cannot exceed maximum amount of mints per mint call"
    );
    require(
      mints[msg.sender] + numberToMint <=
        PUBLIC_SALE_MAX_MINT_AMOUNT_PER_WALLET,
      "GalaxyWarriors: Cannot exceed maximum amount of mints per wallet"
    );
    require(
      supply + numberToMint <=
        TOTAL_NUMBER_OF_GALAXY_WARRIORS - totalGiveawayReserved,
      "GalaxyWarriors: Exceeds maximum Galaxy Warriors supply"
    );
    require(
      msg.value >= PRICE * numberToMint,
      "GalaxyWarriors: Ether sent is less than PRICE * numberToMint"
    );
    mints[msg.sender] += numberToMint;
    for (uint32 i; i < numberToMint; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function preMint(uint256 numberToMint) external payable whenPreMintActive {
    require(
      galaxyAirdropAddress != address(0),
      "GalaxyWarriors: airdrop address is not set"
    );
    require(
      totalSupply() + numberToMint <= TOTAL_NUMBER_OF_GALAXY_WARRIORS,
      "GalaxyWarriors: Trying to premint more than total supply"
    );
    require(
      IGalaxyAirdrop(galaxyAirdropAddress).balanceOf(msg.sender, 0) >=
        numberToMint,
      "GalaxyWarriors: Invalid amount of Galaxy Airdrop tokens to preMint this amount"
    );
    require(
      msg.value >= PRESALE_PRICE * numberToMint,
      "GalaxyWarriors: Ether sent is less than PRESALE_PRICE * numberToMint"
    );
    uint256 supply = totalSupply();
    for (uint256 i; i < numberToMint; i++) {
      IGalaxyAirdrop(galaxyAirdropAddress).burn(msg.sender, GALAXY_AIRDROP_ID, 1);
      _safeMint(msg.sender, supply + i);
    }
  }

  function giveAway(address _to, uint256 numberToMint) external onlyRole(WHITE_LIST_ROLE) {
    uint256 supply = totalSupply();
    require(
      supply + numberToMint <= TOTAL_NUMBER_OF_GALAXY_WARRIORS,
      "GalaxyWarriors: No items left to give away"
    );
    require(
      numberToMint <= totalGiveawayReserved,
      "GalaxyWarriors: No items left to give away"
    );
    totalGiveawayReserved -= numberToMint;
    for (uint32 i; i < numberToMint; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function toggleMint() public onlyRole(WHITE_LIST_ROLE) {
    isMintActive = !isMintActive;
    emit MintActivation(isMintActive);
  }

  function togglePreMint() public onlyRole(WHITE_LIST_ROLE) {
    isPreMintActive = !isPreMintActive;
    emit PremintActivation(isPreMintActive);
  }

  function updateSplitterAddress(address payable _splitter)
    public
    onlyRole(WHITE_LIST_ROLE)
  {
    splitter = PaymentSplitter(_splitter);
  }

  function setBaseURI(string memory baseURI) public onlyRole(WHITE_LIST_ROLE) {
    _baseTokenURI = baseURI;
  }

  function setGalaxyAirdropAddress(address _galaxyAirdropAddress)
    external
    onlyRole(WHITE_LIST_ROLE)
  {
    galaxyAirdropAddress = _galaxyAirdropAddress;
  }

  function withdrawAmountToSplitter(uint256 amount)
    public
    onlyRole(WHITE_LIST_ROLE)
  {
    uint256 _balance = address(this).balance;
    require(
      _balance > 0,
      "GalaxyWarriors: withdraw amount call without balance"
    );
    require(
      _balance - amount >= 0,
      "GalaxyWarriors: withdraw amount call with more than the balance"
    );
    require(
      payable(splitter).send(amount),
      "GalaxyWarriors: FAILED withdraw amount call"
    );
  }

  function withdrawAllToSplitter() public onlyRole(WHITE_LIST_ROLE) {
    uint256 _balance = address(this).balance;
    require(_balance > 0, "GalaxyWarriors: withdraw all call without balance");
    require(
      payable(splitter).send(_balance),
      "GalaxyWarriors: FAILED withdraw all call"
    );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "GalaxyWarriors: URI query for nonexistent token"
    );

    string memory baseURI = getBaseURI();
    string memory json = ".json";
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : "";
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function getSplitter()
    public
    view
    onlyRole(WHITE_LIST_ROLE)
    returns (address)
  {
    return address(splitter);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getBaseURI() public view returns (string memory) {
    return _baseTokenURI;
  }
}

interface IGalaxyAirdrop {
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}