// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "MerkleProof.sol";

// @author: NTX

contract MeowToTheMoon is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public MAX_MEOWS_SUPPLY = 7777;
  uint256 public MAX_PRE_MINT_RESERVED = 3885;
  uint256 public constant PRICE = 0.0777 ether;
  uint256 public constant MAX_MINT_PER_ADDRESS = 7;
  uint256 public constant MAX_MINT_PER_TX = 6;
  uint256 public constant LIMIT_PRE_MINT_EARLY_MEOW = 5;
  uint256 public constant LIMIT_PRE_MINT_MEOW_JUNIOR = 4;

  address private artistAddress = 0x2950100EA973a50B2226a77f51a617299B2BED3D;
  address private devAddress = 0x94841ea1ddD3202a9DF12802D8E74Be4DF6328a6;
  address private projectLeadAddress =
    0x06AC6f3e80822f8d2C7E2607c423f04223479CFE;

  uint256 public totalNumPreMint = 0;
  bool public pauseMint = true;
  bool public pausePreMint = true;
  bytes32 private rootEarlyMeow;
  bytes32 private rootMeowJunior;
  string public baseURI;
  string internal baseExtension = ".json";

  event PauseMintStatusEvent(bool pauseMint);
  event PausePreMintStatusEvent(bool pausePreMint);

  constructor(string memory _initBaseURI) ERC721("MeowToTheMoon", "MTTM") {
    setBaseURI(_initBaseURI);
  }

  modifier mintOpen() {
    require(!pauseMint, "Meows are not ready to be adopted");
    require(totalSupply() <= MAX_MEOWS_SUPPLY, "All meows got adopted!");
    _;
  }

  modifier preMintOpen() {
    require(!pausePreMint, "Pre-mint Meows are not ready to be adopted");
    require(
      totalNumPreMint < MAX_PRE_MINT_RESERVED,
      "All Pre-Mint meows got adopted!"
    );
    require(totalSupply() <= MAX_MEOWS_SUPPLY, "All meows got adopted!");
    _;
  }

  // internal function
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setRootEarlyMeow(bytes32 _rootEarlyMeow) public onlyOwner {
    rootEarlyMeow = _rootEarlyMeow;
  }

  function setRootMeowJunior(bytes32 _rootMeowJunior) public onlyOwner {
    rootMeowJunior = _rootMeowJunior;
  }

  function mintMeow(uint256 amountPurchase) public payable mintOpen {
    uint256 currentSupply = totalSupply();
    uint256 buyerTokenCount = balanceOf(msg.sender);
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Cant adopt more than 6 meows per tx!"
    );
    require(
      buyerTokenCount + amountPurchase <= MAX_MINT_PER_ADDRESS,
      "Cant have more than 7 meows!"
    );
    require(
      currentSupply + amountPurchase <= MAX_MEOWS_SUPPLY,
      "Max supply exceeded"
    );
    require(msg.value >= PRICE * amountPurchase, "Not enough money");

    for (uint256 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }

  function mintUnsoldMeow(uint256 amountMint) public onlyOwner {
    uint256 currentSupply = totalSupply();
    require(
      currentSupply + amountMint <= MAX_MEOWS_SUPPLY,
      "Max supply exceeded"
    );
    for (uint256 i; i < amountMint; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }

  function preMintMeow(
    uint256 amountPurchase,
    bytes32[] calldata proof,
    uint256 _number
  ) public payable preMintOpen {
    require(proof.length < 11, "Invalid proof");
    if (isEligibleEarlyMeow(proof, _number)) {
      uint256 currentSupply = totalSupply();
      uint256 buyerTokenCount = balanceOf(msg.sender);
      require(
        amountPurchase <= LIMIT_PRE_MINT_EARLY_MEOW,
        "earlyMeow max 5 meows per tx!"
      );
      require(
        buyerTokenCount + amountPurchase <= LIMIT_PRE_MINT_EARLY_MEOW,
        "earlyMeow max 5 meows! Come back public sale"
      );
      require(
        totalNumPreMint + amountPurchase <= MAX_PRE_MINT_RESERVED,
        "Premint supply exceeded"
      );
      require(
        currentSupply + amountPurchase <= MAX_MEOWS_SUPPLY,
        "Max supply exceeded"
      );
      require(msg.value >= PRICE * amountPurchase, "Not enough money");
      for (uint256 i; i < amountPurchase; i++) {
        _safeMint(msg.sender, currentSupply + i);
        totalNumPreMint++;
      }
    } else if (isEligibleMeowJunior(proof, _number)) {
      uint256 currentSupply = totalSupply();
      uint256 buyerTokenCount = balanceOf(msg.sender);
      require(
        amountPurchase <= LIMIT_PRE_MINT_MEOW_JUNIOR,
        "meowJunior max 4 meows per tx!"
      );
      require(
        buyerTokenCount + amountPurchase <= LIMIT_PRE_MINT_MEOW_JUNIOR,
        "meowJunior max 4 meows! Come back public sale"
      );
      require(
        totalNumPreMint + amountPurchase <= MAX_PRE_MINT_RESERVED,
        "PreMint supply exceeded"
      );
      require(
        currentSupply + amountPurchase <= MAX_MEOWS_SUPPLY,
        "Max supply exceeded"
      );
      require(msg.value >= PRICE * amountPurchase, "Not enough money");
      for (uint256 i; i < amountPurchase; i++) {
        _safeMint(msg.sender, currentSupply + i);
        totalNumPreMint++;
      }
    } else {
      revert("Not whitelist!");
    }
  }

  function isEligibleEarlyMeow(bytes32[] calldata proof, uint256 _number)
    public
    view
    returns (bool isEligible)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_number, msg.sender));
    return MerkleProof.verify(proof, rootEarlyMeow, leaf);
  }

  function isEligibleMeowJunior(bytes32[] calldata proof, uint256 _number)
    public
    view
    returns (bool isEligible)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_number, msg.sender));
    return MerkleProof.verify(proof, rootMeowJunior, leaf);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent meow");

    string memory currentBaseURI = _baseURI();

    return (
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : ""
    );
  }

  function setPauseMint(bool _setPauseMint) public onlyOwner {
    if (_setPauseMint == false) {
      require(pauseMint == true, "Mint already unpaused");
      pauseMint = _setPauseMint;
    } else if (_setPauseMint == true) {
      require(pauseMint == false, "Mint already paused");
      pauseMint = _setPauseMint;
    }
    emit PauseMintStatusEvent(pauseMint);
  }

  function setPausePreMint(bool _setPausePreMint) public onlyOwner {
    if (_setPausePreMint == false) {
      require(pausePreMint == true, "PreMint already unpaused");
      pausePreMint = _setPausePreMint;
    } else if (_setPausePreMint == true) {
      require(pausePreMint == false, "PreMint already paused");
      pausePreMint = _setPausePreMint;
    }
    emit PausePreMintStatusEvent(pausePreMint);
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money to withdraw");
    _withdraw(artistAddress, (balance * 2833) / 10000);
    _withdraw(devAddress, (balance * 2833) / 10000);
    _withdraw(projectLeadAddress, (balance * 2833) / 10000);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }

  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
}