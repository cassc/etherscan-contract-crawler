// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AuthorizedV2.sol";
import "./NFTCollectionV2.sol";

contract FanEpackCollection is AuthorizedV2, NFTCollectionV2 {
  /** Fields */

  bytes32 private immutable _claimSeparator;

  mapping(address => uint256) private _claimed;

  constructor(address authority_, string memory baseURI_) {
    _admin = msg.sender;
    _owner = msg.sender;

    _authority = authority_;
    _baseURI = baseURI_;

    _claimSeparator = keccak256("Claim(address account,uint256 earned)");
  }

  /** @dev IERC721Metadata Views */

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure override returns (string memory) {
    return "FanEpack Collection";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure override returns (string memory) {
    return "FEC";
  }

  /** @dev Admin */

  function changeAuthority(address newAuthority) external onlyAdmin {
    _authority = newAuthority;
  }

  /** @dev Claim */

  function claimed(address wallet) external view returns (uint256) {
    return _claimed[wallet];
  }

  function claim(
    uint256 quantity,
    uint256 earned,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(verify(keccak256(abi.encode(_claimSeparator, msg.sender, earned)), v, r, s), "invalid message");
    require(quantity + _claimed[msg.sender] <= earned, "more than earned");

    for (uint256 i = 1; i <= quantity; i++) {
      _owners[_totalSupply + i] = msg.sender;

      emit Transfer(address(0), msg.sender, _totalSupply + i);
    }

    _balances[msg.sender] += quantity;
    _claimed[msg.sender] += quantity;
    _totalSupply += quantity;
  }
}