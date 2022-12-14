// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/IDescriptor.sol';
import './interfaces/ISoulz.sol';
import './interfaces/IShared.sol';
import './interfaces/ISponsorship.sol';
import './interfaces/IWorkshop.sol';
import './Soulbound.sol';

contract Soulz is Soulbound, ReentrancyGuard, IShared {
  /// Metapond ERC20 utility token address
  address public M;

  /// Eggz ERC20 utility token address
  address public EGGZ;

  /// Rage ERC20 utility token address
  address public RAGE;

  /// Trait descriptor
  IDescriptor public descriptor;

  /// Sponsorship manager
  ISponsorship public sponsorship;

  /// Artwork renderer
  IWorkshop public workshop;

  /// Base prices
  Price public prices =
    Price({ETH: 0.01 ether, M: 10000 ether, RAGE: 500 ether, EGGZ: 1000 ether});

  /// Mapping from token ID to token creation timestamp
  mapping(uint256 => uint256) public birthdates;

  /// Mapping from token ID to given name
  mapping(uint256 => string) public names;

  /// Mapping from token ID to token attributes
  mapping(uint256 => Attributes) public metadata;

  /// Check wallet doens't already own any
  modifier checkSoulless(address wallet) {
    if (balanceOf(wallet) > 0) {
      revert SoullessError();
    }
    _;
  }

  modifier checkValue() {
    if (msg.value < prices.ETH) {
      revert ValueError();
    }
    _;
  }

  modifier checkTokenValue(address token, uint256 price) {
    if (IERC20(token).balanceOf(msg.sender) < price) {
      revert TokenValueError();
    }
    _;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    if (ownerOf(tokenId) != msg.sender) {
      revert WrongOwner();
    }
    _;
  }

  modifier tokenExists(uint256 tokenId) {
    if (!_exists(tokenId)) {
      revert NonExistantToken();
    }
    _;
  }

  modifier validateAttributes(Attributes calldata attributes) {
    require(
      descriptor.accessoryExists(attributes.accessory),
      'Soulz: accessory does not exist'
    );
    require(
      descriptor.animationExists(attributes.animation),
      'Soulz: animation does not exist'
    );
    require(
      descriptor.backgroundExists(attributes.background),
      'Soulz: background does not exist'
    );
    require(
      descriptor.bodyExists(attributes.body),
      'Soulz: body does not exist'
    );
    require(
      descriptor.bottomExists(attributes.bottom),
      'Soulz: bottom does not exist'
    );
    require(
      descriptor.earExists(attributes.ears),
      'Soulz: ears does not exist'
    );
    require(
      descriptor.eyeExists(attributes.eyes),
      'Soulz: eyes does not exist'
    );
    require(
      descriptor.faceExists(attributes.face),
      'Soulz: face does not exist'
    );
    require(descriptor.fxExists(attributes.fx), 'Soulz: fx does not exist');
    require(
      descriptor.headExists(attributes.head),
      'Soulz: head does not exist'
    );
    require(
      descriptor.mouthExists(attributes.mouth),
      'Soulz: mouth does not exist'
    );
    require(
      descriptor.overlayExists(attributes.overlay),
      'Soulz: overlay does not exist'
    );
    require(
      descriptor.shoeExists(attributes.shoes),
      'Soulz: shoes does not exist'
    );
    require(descriptor.topExists(attributes.top), 'Soulz: top does not exist');
    _;
  }

  constructor(
    address metapondTokenAddress,
    address eggzTokenAddress,
    address rageTokenAddress,
    address descriptorAddress,
    address sponsorhipAddress,
    address workshopAddress
  ) Soulbound('Soulz', 'SOUL') Ownable() {
    M = metapondTokenAddress;
    EGGZ = eggzTokenAddress;
    RAGE = rageTokenAddress;
    descriptor = IDescriptor(descriptorAddress);
    sponsorship = ISponsorship(sponsorhipAddress);
    workshop = IWorkshop(workshopAddress);
  }

  /// Admin method to update the descriptor contract address
  function setDescriptor(
    address newDescriptorAddress
  ) public onlyOwner nonReentrant {
    descriptor = IDescriptor(newDescriptorAddress);
  }

  /// Admin method to update the sponsorship contract address
  function setSponsorship(
    address newSponsorhipAddress
  ) public onlyOwner nonReentrant {
    sponsorship = ISponsorship(newSponsorhipAddress);
  }

  /// Admin method to update the workshop contract address
  function setWorkshop(
    address newWorkshopAddress
  ) public onlyOwner nonReentrant {
    workshop = IWorkshop(newWorkshopAddress);
  }

  /// Admin method to update minting prices
  function setPrices(Price calldata newPrices) public onlyOwner nonReentrant {
    prices = newPrices;
  }

  /// Rename the Soulz
  function _rename(uint256 tokenId, string calldata name) internal {
    if (bytes(name).length == 0) {
      names[tokenId] = string(
        abi.encodePacked('Soulz #', Strings.toString(tokenId))
      );
    } else {
      names[tokenId] = name;
    }
  }

  /// Update Soulz attributes to your liking
  function _update(
    uint256 tokenId,
    Attributes calldata attributes
  ) internal validateAttributes(attributes) {
    metadata[tokenId] = attributes;
  }

  function mint(
    address wallet,
    string calldata name,
    Attributes calldata attributes
  ) public payable checkValue nonReentrant {
    _mint(wallet, name, attributes);
  }

  function _mint(
    address wallet,
    string calldata name,
    Attributes calldata attributes
  ) internal checkSoulless(wallet) {
    uint256 tokenId = totalSupply() + 1;

    birthdates[tokenId] = block.timestamp;

    _rename(tokenId, name);
    _update(tokenId, attributes);
    _safeMint(wallet, tokenId);

    // Minting on behalf of somebody means sponsoring
    if (wallet != msg.sender) {
      sponsorship.create(soulOf(msg.sender), tokenId);
    }
  }

  function mintWithMetapondToken(
    address wallet,
    string calldata name,
    Attributes calldata attributes
  ) external checkTokenValue(M, prices.M) nonReentrant {
    _pay(M, prices.M);
    _mint(wallet, name, attributes);
  }

  function mintWithEggzToken(
    address wallet,
    string calldata name,
    Attributes calldata attributes
  ) external checkTokenValue(EGGZ, prices.EGGZ) nonReentrant {
    _pay(EGGZ, prices.EGGZ);
    _mint(wallet, name, attributes);
  }

  function mintWithRageToken(
    address wallet,
    string calldata name,
    Attributes calldata attributes
  ) external checkTokenValue(RAGE, prices.RAGE) nonReentrant {
    _pay(RAGE, prices.RAGE);
    _mint(wallet, name, attributes);
  }

  function _pay(address token, uint256 amount) internal {
    require(IERC20(token).transferFrom(msg.sender, address(this), amount));
  }

  function customize(
    uint256 tokenId,
    string calldata name,
    Attributes calldata attributes
  ) public payable onlyTokenOwner(tokenId) nonReentrant {
    _rename(tokenId, name);
    _update(tokenId, attributes);
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override tokenExists(tokenId) returns (string memory) {
    return
      workshop.render({
        tokenId: tokenId,
        owner: ownerOf(tokenId),
        name: names[tokenId],
        birthdate: birthdates[tokenId],
        attributes: metadata[tokenId]
      });
  }

  function withdraw() external payable onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');

    require(success);
  }

  function withdrawTokens() external onlyOwner nonReentrant {
    require(_withdrawToken(M), 'Could not withdraw M tokens');
    require(_withdrawToken(EGGZ), 'Could not withdraw EGGZ tokens');
    require(_withdrawToken(RAGE), 'Could not withdraw RAGE tokens');
  }

  function _withdrawToken(address tokenAddress) internal returns (bool) {
    IERC20 token = IERC20(tokenAddress);

    return token.transfer(owner(), token.balanceOf(address(this)));
  }
}