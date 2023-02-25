// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721/IERC721MetaBrands.sol";

import "./ERC721/ProxyRegister.sol";

contract MageCreator is Ownable, ReentrancyGuard {
  // NFT Tokens configuration
  mapping(string => NFT) public nftTokens;

  // MAGE ERC20 contract address
  address public mageERC20Addr;

  event NFTAdded(string name, address contractAddr, uint256 magePrice);
  event NFTRemoved(string name);

  mapping(address => OwnableDelegateProxy) public proxies;  

  event NFTUpgraded(
    address owner,
    string fromName,
    address fromContractAddr,
    string toName,
    address toContractAddr,
    uint256 upgradePrice
  );

  struct NFT {
    bool exists;
    address contractAddr;
    uint256 magePrice;
  }

  constructor() {}

  /**
   * @dev Set MAGE ERC20 contract address
   *
   * Requirements:
   * - only owner can call this function.
   */
  function setMageERC20Addr(address _mageERC20Addr) external onlyOwner {
    mageERC20Addr = _mageERC20Addr;
  }

  /**
   * @dev Add a NFT contract to mapping
   *
   * Emits:
   * `NFTAdded` MageCreator event.
   *
   * Requirements:
   * - only owner can call this function.
   */
  function addNFTokenAddr(
    string calldata _name,
    address _contractAddr,
    uint256 _magePrice
  ) external onlyOwner {
    nftTokens[_name] = NFT({
      exists: true,
      contractAddr: _contractAddr,
      magePrice: _magePrice
    });

    emit NFTAdded(_name, _contractAddr, _magePrice);
  }

  /**
   * @dev Removes a NFT contract from mapping
   *
   * Emits:
   * `NFTRemoved` MageCreator event.
   *
   * Requirements:
   * - only owner can call this function.
   */
  function removeNFTokenAddr(string calldata _name) external onlyOwner {
    delete nftTokens[_name];
    emit NFTRemoved(_name);
  }

  /**
   * @dev Sender gets a NFT burning ERC20 token
   *
   * Emits:
   * `Transfer` ERC20 event.
   * `Transfer` ERC721 mint event.
   *
   * Requirements:
   * - success on transfer of ERC20 tokens value to burner address.
   */
  function mintNFT(string calldata _name) external nonReentrant {
    // Checks if the token exists
    require(nftTokens[_name].exists, "MageCreator: token does not exist");

    // Check the MAGE balance of the sender
    require(
      IERC20(mageERC20Addr).balanceOf(_msgSender()) >=
        nftTokens[_name].magePrice,
      "MageCreator: not enough MAGE tokens"
    );

    // Burn ERC20 tokens
    ERC20Burnable(mageERC20Addr).burnFrom(
      _msgSender(),
      nftTokens[_name].magePrice
    );

    // Mints the NFT and returns tokenId
    IERC721MetaBrands(nftTokens[_name].contractAddr).mint(_msgSender());
  }

  /**
   * @dev Upgrades a sender current token sending the ERC20 token difference
   *  to the burner wallet.
   *
   * Emits:
   * `Transfer` ERC20 event.
   * `Transfer` ERC721 burn event.
   * `Transfer` ERC721 mint event.
   * `NFTUpgraded` MageCreator event.
   *
   * Requirements:
   * - sender have tokens on `_fromName` NFT contract.
   * - the price of `_fromName` must be lower than other `_toName` NFT.
   * - success on transfer of ERC20 tokens difference value to burner address.
   */
  function upgradeNFT(string memory _fromName, string memory _toName)
    external
    nonReentrant
  {
    // Checks if the token exists
    require(
      nftTokens[_fromName].exists,
      "MageCreator: _from token does not exist"
    );
    require(nftTokens[_toName].exists, "MageCreator: _to token does not exist");

    // Sender must have NFT to upgrade
    require(
      IERC721(nftTokens[_fromName].contractAddr).balanceOf(_msgSender()) > 0,
      "MageCreator: no token to upgrade"
    );

    // Target NFT price must be higher than current NFT price
    require(
      nftTokens[_fromName].magePrice < nftTokens[_toName].magePrice,
      "MageCreator: not upgradeable"
    );

    // Calculte the difference between NFT prices
    uint256 upgradePrice = nftTokens[_toName].magePrice -
      nftTokens[_fromName].magePrice;

    // Check the MAGE balance of the sender
    require(
      IERC20(mageERC20Addr).balanceOf(_msgSender()) >= upgradePrice,
      "MageCreator: not enough MAGE tokens"
    );

    // Burn ERC20 tokens
    ERC20Burnable(mageERC20Addr).burnFrom(_msgSender(), upgradePrice);

    // Gets the sender's first original NFT
    uint256 firstToken = IERC721Enumerable(nftTokens[_fromName].contractAddr)
      .tokenOfOwnerByIndex(_msgSender(), 0);

    // Burns sender's first original NFT
    IERC721MetaBrands(nftTokens[_fromName].contractAddr).burn(firstToken);

    // Mints the new NFT and returns tokenId
    IERC721MetaBrands(nftTokens[_toName].contractAddr).mint(_msgSender());

    // Emits NFTUpgraded event
    emit NFTUpgraded(
      _msgSender(),
      _fromName,
      nftTokens[_fromName].contractAddr,
      _toName,
      nftTokens[_toName].contractAddr,
      upgradePrice
    );
  }
}