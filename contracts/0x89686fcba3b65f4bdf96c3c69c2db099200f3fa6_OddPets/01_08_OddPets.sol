// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./OddFrens.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract OddPets is ERC721A, ERC721AQueryable, Ownable {
  uint256 constant EXTRA_MINT_PRICE = 0.005 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 10001;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;

  string tokenBaseUri =
    "ipfs://QmUS5dfjJ45CRaDKt3qnFtAxYuUSCGncu89HvwyHezzREs/?";

  bool public paused = true;

  OddFrens private immutable oddFrensContract;
  address private immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress, address _oddFrensContract)
    ERC721A("Odd Pets", "OP")
  {
    proxyRegistryAddress = _proxyRegistryAddress;
    oddFrensContract = OddFrens(_oddFrensContract);
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "MINtINg is PauSed");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE, "ExCEedS SuPPLY");
    require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "EXcEEdS MaX PER tX");

    // Free Mints
    uint256 payForCount = _quantity;
    uint256 oddFrensCount = oddFrensContract.balanceOf(msg.sender);

    if (oddFrensCount > 2) {
      uint256 freeMintCount = _freeMintedCount[msg.sender];
      uint256 freeMintAvailable = oddFrensCount / 3;

      if (freeMintCount < freeMintAvailable) {
        if (freeMintAvailable < _quantity) {
          payForCount = _quantity - freeMintAvailable;
        } else {
          payForCount = 0;
        }

        _freeMintedCount[msg.sender] += _quantity;
      }
    }

    require(
      msg.value == payForCount * EXTRA_MINT_PRICE,
      "EthEr sENt is NOT corrEcT"
    );

    _mint(msg.sender, _quantity);
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override(ERC721A, IERC721A)
    returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      proxyRegistryAddress
    );

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "ReServES aLReaDY TAkEN");

    _mint(msg.sender, 100);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "WIThDRaW UNsucCEssFUl"
    );
  }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}