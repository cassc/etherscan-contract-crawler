// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ApeInvaders is ERC721Enumerable, Ownable {
  string public baseURI;

  address public proxyRegistryAddress;
  address public verifier;

  uint256 public constant MAX_SUPPLY_PLUS_ONE = 5501;
  uint256 public constant MAX_PER_TX_PLUS_ONE = 6;
  uint256 public constant RESERVES = 100;
  uint256 public constant PRICE_IN_WEI = 0.055 ether;

  mapping(address => bool) public projectProxy;
  mapping(address => uint256) public walletCount;

  bool public paused = true;

  constructor(string memory _baseURI, address _proxyRegistryAddress)
    ERC721("Ape Invaders", "AI")
  {
    baseURI = _baseURI;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function _recoverWallet(address _wallet, bytes memory _signature)
    internal
    pure
    returns (address)
  {
    return
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_wallet))),
        _signature
      );
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "Token does not exist");

    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress)
    external
    onlyOwner
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function flipProxyState(address _proxyAddress) public onlyOwner {
    projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
  }

  function collectReserves() external onlyOwner {
    require(_owners.length == 0, "Reserves already taken");

    for (uint256 i; i < RESERVES; i++) {
      _mint(_msgSender(), i);
    }
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function mint(uint256 _count) external payable {
    uint256 totalSupply = _owners.length;

    require(!paused, "Minting paused");
    require(totalSupply + _count < 4001, "Excedes max supply");
    require(_count < MAX_PER_TX_PLUS_ONE, "Excedes max per transaction");
    require(_count * PRICE_IN_WEI == msg.value, "Ether sent is not correct");

    for (uint256 i; i < _count; i++) {
      _mint(_msgSender(), totalSupply + i);
    }
  }

  function whitelistMint(uint256 _count, bytes calldata _signature)
    external
    payable
  {
    address signer = _recoverWallet(_msgSender(), _signature);

    require(signer == verifier, "Unverified transaction");

    uint256 totalSupply = _owners.length;

    require(!paused, "Minting paused");
    require(totalSupply + _count < MAX_SUPPLY_PLUS_ONE, "Excedes max supply");
    require(_count < MAX_PER_TX_PLUS_ONE, "Excedes max per transaction");
    require(_count * PRICE_IN_WEI == msg.value, "Ether sent is not correct");

    if (totalSupply + _count < 4001) {
      require(
        walletCount[_msgSender()] + _count < 6,
        "Max mint per address is 5"
      );

      walletCount[_msgSender()] += _count;
    }

    for (uint256 i; i < _count; i++) {
      _mint(_msgSender(), totalSupply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    }

    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) public {
    for (uint256 i; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

  function batchSafeTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    bytes memory _data
  ) public {
    for (uint256 i; i < _tokenIds.length; i++) {
      safeTransferFrom(_from, _to, _tokenIds[i], _data);
    }
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      proxyRegistryAddress
    );

    if (
      address(proxyRegistry.proxies(_owner)) == _operator ||
      projectProxy[_operator]
    ) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function _mint(address _to, uint256 _tokenId) internal virtual override {
    _owners.push(_to);

    emit Transfer(address(0), _to, _tokenId);
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}

// solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}