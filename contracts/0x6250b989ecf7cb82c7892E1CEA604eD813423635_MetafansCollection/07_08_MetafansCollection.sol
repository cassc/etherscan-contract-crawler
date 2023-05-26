// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Authorized.sol";
import "./NFTCollectionV1.sol";

contract MetafansCollection is NFTCollectionV1, Authorized {
  /** @dev Immutable */
  uint256 private constant _launchLimit = 10;
  uint256 private constant _mintCooldown = 10 minutes;
  uint256 private constant _presaleLimit = 3;

  address private immutable _partnerA;
  address private immutable _partnerB;
  uint256 private immutable _promoQuantity;

  /** @dev Fields */

  uint256 private _launchAt;
  mapping(address => uint256) private _lastMintAt;
  uint256 private _partnerARevenue;
  uint256 private _partnerBRevenue;
  uint256 private _presaleAt;
  mapping(address => uint256) private _presaleClaimed;
  uint256 private _price;

  constructor(
    string memory baseURI_,
    uint256 launchAt_,
    address partnerA,
    address partnerB,
    uint256 presaleAt_,
    uint256 price,
    uint256 promoQuantity_,
    uint256 totalSupplyLimit_
  ) {
    _admin = msg.sender;
    _authority = msg.sender;
    _owner = msg.sender;

    _baseURI = baseURI_;
    _launchAt = launchAt_;
    _partnerA = partnerA;
    _partnerB = partnerB;
    _presaleAt = presaleAt_;
    _price = price;
    _promoQuantity = promoQuantity_;
    _totalSupplyLimit = totalSupplyLimit_;

    _totalSupply = _promoQuantity;
  }

  /** @dev IERC721Metadata Views */

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure override returns (string memory) {
    return "Metafans Collection";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure override returns (string memory) {
    return "MFC";
  }

  /** @dev General Views */

  function lastMintAt(address wallet) external view returns (uint256) {
    return _lastMintAt[wallet];
  }

  function launchAt() external view returns (uint256) {
    return _launchAt;
  }

  function presaleAt() external view returns (uint256) {
    return _presaleAt;
  }

  function presaleClaimed(address wallet) external view returns (uint256) {
    return _presaleClaimed[wallet];
  }

  /** @dev Admin Mutators */

  function changeLaunchAt(uint256 value) external onlyAdmin {
    _launchAt = value;
  }

  function changePresaleAt(uint256 value) external onlyAdmin {
    _presaleAt = value;
  }

  function changePrice(uint256 value) external onlyAdmin {
    _price = value;
  }

  /** @dev Mint Mutators */

  function launchMint(uint256 quantity) external payable {
    require(_launchAt < block.timestamp, "launch has not begun");
    require(msg.value == _price * quantity, "incorrect ETH");
    require(quantity <= _launchLimit, "over limit");
    require(block.timestamp - _lastMintAt[msg.sender] > _mintCooldown, "cooling down");

    _partnerShare();
    _mint(quantity);
  }

  function presaleMint(
    uint256 quantity,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable authorized(msg.sender, deadline, v, r, s) {
    require(_presaleAt < block.timestamp, "presale has not begun");
    require(block.timestamp < _launchAt, "presale has ended");
    require(block.timestamp < deadline, "past deadline");
    require(msg.value == _price * quantity, "incorrect ETH");
    require((_presaleClaimed[msg.sender] += quantity) <= _presaleLimit, "over limit");

    _partnerShare();
    _mint(quantity);
  }

  function promoMint(uint256 tokenId, address to) external onlyAdmin {
    require(tokenId < _promoQuantity, "over promo limit");
    require(_owners[tokenId] == address(0), "already minted");

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  /** @dev Partner Views */

  function partnerRevenue(address wallet) external view returns (uint256) {
    if (wallet == _partnerA) {
      return _partnerARevenue;
    }

    if (wallet == _partnerB) {
      return _partnerBRevenue;
    }

    return 0;
  }

  /** @dev Partner Mutators */

  function claimRevenue() external {
    uint256 amount;

    if (msg.sender == _partnerA) {
      amount = _partnerARevenue;
      _partnerARevenue = 0;
    } else if (msg.sender == _partnerB) {
      amount = _partnerBRevenue;
      _partnerBRevenue = 0;
    } else {
      revert("unauthorized");
    }

    (bool send, ) = msg.sender.call{value: amount}("");

    require(send, "failed to send partner funds");
  }

  /** @dev Helpers */

  function _mint(uint256 quantity) private {
    require(_totalSupply + quantity <= _totalSupplyLimit, "over total supply limit");

    for (uint256 i = 0; i < quantity; i++) {
      _owners[_totalSupply + i] = msg.sender;

      emit Transfer(address(0), msg.sender, _totalSupply + i);
    }

    _balances[msg.sender] += quantity;
    _totalSupply += quantity;
    _lastMintAt[msg.sender] = block.timestamp;
  }

  function _partnerShare() private {
    uint256 shareB = msg.value / 10;
    uint256 shareA = msg.value - shareB;

    _partnerARevenue += shareA;
    _partnerBRevenue += shareB;
  }
}