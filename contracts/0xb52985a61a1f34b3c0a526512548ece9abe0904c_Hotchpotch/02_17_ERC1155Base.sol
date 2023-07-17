// SPDX-License-Identifier: MIT

// m1nm1n & Co.
// https://m1nm1n.com/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";

contract ERC1155Base is ERC1155, Ownable, RoyaltiesV2 {
  using SafeMath for uint256;
  using Strings for uint256;

  mapping(address => bool) public minters;

  string public name;
  string public symbol;
  string public baseMetadataURI;
  mapping(uint256 => uint256) public tokenSupply;

  uint96 public defaultPercentageBasisPoints = 1000;
  address public defaultRoyaltiesReceipientAddress;

  event SetMinter(address indexed minter, bool value);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseMetadataURI
  ) ERC1155(_baseMetadataURI) {
    name = _name;
    symbol = _symbol;
    baseMetadataURI = _baseMetadataURI;
    defaultRoyaltiesReceipientAddress = _msgSender();
    _setMinter(_msgSender(), true);
  }

  modifier onlyMinter() {
    _checkMinter();
    _;
  }

  function _checkMinter() internal view {
    require(minters[_msgSender()], "caller is not the minter");
  }

  function _setMinter(address _minter, bool _value) internal {
    minters[_minter] = _value;
    emit SetMinter(_minter, _value);
  }

  function setMinter(address _minter, bool _value) external onlyOwner {
    _setMinter(_minter, _value);
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external onlyMinter {
    _mint(to, id, amount, data);
    tokenSupply[id] = tokenSupply[id].add(amount);
  }

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "caller is not token owner nor approved");
    _burn(account, id, amount);
    tokenSupply[id] = tokenSupply[id].sub(amount);
  }

  function totalSupply(uint256 _id) external view returns (uint256) {
    return tokenSupply[_id];
  }

  function setBaseMetadataURI(string calldata _baseMetadataURI) external onlyOwner {
    baseMetadataURI = _baseMetadataURI;
  }

  function uri(uint256 _id) public view override returns (string memory) {
    require(_exists(_id), "token not found");
    return string(abi.encodePacked(baseMetadataURI, _id.toString()));
  }

  function _exists(uint256 _id) internal view returns (bool) {
    return tokenSupply[_id] > 0;
  }

  function setDefaultPercentageBasisPoints(uint96 _defaultPercentageBasisPoints) external onlyOwner {
    defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
  }

  function setDefaultRoyaltiesReceipientAddress(address _defaultRoyaltiesReceipientAddress) external onlyOwner {
    defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
  }

  function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = defaultPercentageBasisPoints;
    _royalties[0].account = payable(defaultRoyaltiesReceipientAddress);
    return _royalties;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == type(IERC2981).interfaceId) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}