/***
 *    ███████╗██████╗  ██████╗██████╗  █████╗  █████╗  ██╗
 *    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔══██╗██╔══██╗███║
 *    █████╗  ██████╔╝██║      █████╔╝╚██████║╚█████╔╝╚██║
 *    ██╔══╝  ██╔══██╗██║     ██╔═══╝  ╚═══██║██╔══██╗ ██║
 *    ███████╗██║  ██║╚██████╗███████╗ █████╔╝╚█████╔╝ ██║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚════╝  ╚════╝  ╚═╝
 * Written by MaxflowO2
 * You can follow along at https://github.com/MaxflowO2/ERC2981
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./IERC2981.sol";

abstract contract ERC2981 is IERC2981, ERC165Storage {
  using SafeMath for uint256;

  // Bytes4 Code for EIP-2981
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // Mappings _tokenID -> values
  mapping(uint256 => address) receiver;
  mapping(uint256 => uint256) royaltyPercentage;

  constructor() {
    // Using ERC165Storage set EIP-2981
    _registerInterface(_INTERFACE_ID_ERC2981);
  }

  // Set to be internal function _setReceiver
  function _setReceiver(uint256 _tokenId, address _address) internal {
    receiver[_tokenId] = _address;
  }

  // Set to be internal function _setRoyaltyPercentage
  function _setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage)
    internal
  {
    royaltyPercentage[_tokenId] = _royaltyPercentage;
  }

  // Override for royaltyInfo(uint256, uint256)
  // uses SafeMath for uint256
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override(IERC2981)
    returns (address Receiver, uint256 royaltyAmount)
  {
    Receiver = receiver[_tokenId];
    royaltyAmount = _salePrice.div(100).mul(royaltyPercentage[_tokenId]);
  }
}