// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IReverseResolver {
  function claim(address owner) external returns (bytes32);
}

interface IVendingMachineFactory {
  function moonCatVendingMachineExists(uint256 tokenId) external view returns (bool);
  function vendingMachineCanMintStart(uint256 tokenId) external view returns (uint256);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title MoonCatPop cans
 * @dev ERC721 token of a virtual can of pop.
 */
contract MoonCatPopVendingMachine is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;

  string public baseURI;

  /* Financials */
  uint256 public constant primarySalesPercent = 80;
  uint256 public constant secondaryRoyaltiesPercent = 50;
  uint256 public constant moonCatOwnerDiscount = 0.01 ether;

  /* Vended Cans */
  uint256[256] public totalSupplyPerMachine;
  uint256 public maxCansPerMachine = 100;
  uint256 public vendingCost = 0.05 ether;

  /* External Contracts */
  address public moonCatPopVendingMachineFactory;
  address public constant moonCatAcclimatorContract = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;

  /* Events */
  event BaseURISet(string baseURI);

  /**
   * @dev Deploy contract.
   */
  constructor(address _factoryAddress) ERC721("MoonCatPop", "CAN") {
    moonCatPopVendingMachineFactory = _factoryAddress;
    _pause();

    // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
    IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148)
      .claim(msg.sender);
  }

  /**
   * @dev Pause the contract.
   * Prevent minting and transferring of tokens
   */
  function paws() public onlyOwner {
      _pause();
  }

  /**
   * @dev Unpause the contract.
   * Allow minting and transferring of tokens
   */
  function unpaws() public onlyOwner {
      _unpause();
  }

  /**
   * @dev Update the base URI for token metadata.
   */
  function setBaseURI(string memory _newbaseURI) public onlyFactoryOwner() {
    baseURI = _newbaseURI;
    emit BaseURISet(_newbaseURI);
  }

  /**
    * @dev Rescue ERC20 assets sent directly to this contract.
    */
  function withdrawForeignERC20(address tokenContract) public onlyOwner {
    IERC20 token = IERC20(tokenContract);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
    * @dev Rescue ERC721 assets sent directly to this contract.
    */
  function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
    IERC721(tokenContract).safeTransferFrom(address(this), owner(), tokenId);
  }

  /**
   * @dev Create a can of MoonCatPop
   */
  function mint(uint vendingMachineId)
    public
    payable
    returns(uint256)
  {
      uint256 cost = (IERC721(moonCatAcclimatorContract).balanceOf(_msgSender()) == 0)
          ? vendingCost
          : (vendingCost - moonCatOwnerDiscount);
      require(msg.value == cost, "Exact Change Required");
      return _mint(vendingMachineId, cost);
  }

  /**
   * @dev Create multiple cans of MoonCatPop
   */
  function batchMint(uint256[] memory vendingMachineIds)
    public
    payable
    returns(uint256[] memory)
  {
      uint256[] memory tokenIds = new uint256[](vendingMachineIds.length);
      uint256 cost = (IERC721(moonCatAcclimatorContract).balanceOf(_msgSender()) == 0)
          ? vendingCost
          : (vendingCost - moonCatOwnerDiscount);
      require(msg.value == cost * vendingMachineIds.length, "Exact Change Required");
      for (uint256 i; i < vendingMachineIds.length; i++) {
          tokenIds[i] = _mint(vendingMachineIds[i], cost);
      }
      return tokenIds;
  }

  /**
   * @dev Internal function to do shared minting actions.
   */
  function _mint(uint256 _vendingMachineId, uint256 _cost)
    internal
    whenNotPaused
    returns(uint256)
  {
    IVendingMachineFactory VMF = IVendingMachineFactory(moonCatPopVendingMachineFactory);
    require(VMF.moonCatVendingMachineExists(_vendingMachineId), "No Such Vending Machine");
    require(block.number >= VMF.vendingMachineCanMintStart(_vendingMachineId), "Can minting not open");
    require(totalSupplyPerMachine[_vendingMachineId] < maxCansPerMachine, "Can limit exceeded");
    uint256 tokenId = _vendingMachineId * maxCansPerMachine + totalSupplyPerMachine[_vendingMachineId];
    _safeMint(_msgSender(), tokenId);

    totalSupplyPerMachine[_vendingMachineId]++;

    address vendingMachineOwner = ERC721(moonCatPopVendingMachineFactory).ownerOf(_vendingMachineId);
    // Check if Owner is ERC998 contract
    // 0xed81cdda == rootOwnerOfChild(address,uint256)
    // 0xcd740db5 == ERC998 Magic Value
    (bool callSuccess, bytes memory data) = vendingMachineOwner.staticcall(abi.encodeWithSelector(0xed81cdda, moonCatPopVendingMachineFactory, _vendingMachineId));
    if (data.length != 0) {
      bytes32 dataBytes = abi.decode(data, (bytes32));
      if (callSuccess && dataBytes >> 224 == 0x00000000000000000000000000000000000000000000000000000000cd740db5) {
        // Token owner is a top-down composable
        vendingMachineOwner = address(uint160(uint256(dataBytes & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)));
      }
    }

    uint256 vendingMachineOwnerPayment = _cost * primarySalesPercent / 100;
    (bool success,) = vendingMachineOwner.call{value:vendingMachineOwnerPayment}('');
    require(success, "Failed to transfer VM Owner payment");
    (success,) = moonCatPopVendingMachineFactory.call{value:_cost - vendingMachineOwnerPayment}('');
    require(success, "Failed to transfer Owner payment");
    return tokenId;
  }

  /**
   * @dev See {ERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      uint256 vendingMachineId = _tokenId / maxCansPerMachine;
      uint256 canId = _tokenId % maxCansPerMachine;
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(
        baseURI,
        vendingMachineId.toString(), '/',
        canId.toString(), '.json'
      )) : "";
  }

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Throws if called by any account other than the factory owner.
   */
  modifier onlyFactoryOwner() {
    require(Ownable(moonCatPopVendingMachineFactory).owner() == _msgSender(), "Ownable: caller is not factory owner");
    _;
  }

  /**
   * @dev Default funds-receiving method.
   */
  receive() external payable {
    payable(owner()).transfer(msg.value * secondaryRoyaltiesPercent / 100);
    (bool success,) = payable(moonCatPopVendingMachineFactory).call{value: address(this).balance}("");
    require(success,"transfer failed");
  }
}