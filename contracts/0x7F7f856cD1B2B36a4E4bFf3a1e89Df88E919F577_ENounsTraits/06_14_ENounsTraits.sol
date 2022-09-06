// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IStream } from "./interfaces/IStream.sol";
import { ITraitsFetch } from "./interfaces/ITraitsFetch.sol";
import { StreamENS } from "./streams/StreamENS.sol";

/**
 * @title ENounsTraits
 * @author Kames Geraghty
 */
contract ENounsTraits is ITraitsFetch, Ownable {
  address private _streamEns;
  address private immutable _ensToken = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
  address private immutable _nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
  address private immutable _lilNounsToken = 0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B;

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  constructor(address streamEns) {
    _streamEns = streamEns;
  }

  function fetch(bytes memory input) external view returns (string memory) {
    address user_ = abi.decode(input, (address));
    uint256 ensBalance = IERC721(_ensToken).balanceOf(user_);
    uint256 nounsBalance = IERC721(_nounsToken).balanceOf(user_);
    uint256 lilNounsBalance = IERC721(_lilNounsToken).balanceOf(user_);
    return
      string.concat(
        _getUnwrappedTraits(user_),
        _generateTrait("ensBalance", Strings.toString(ensBalance)),
        ",",
        _generateTrait("nounsBalance", Strings.toString(nounsBalance)),
        ",",
        _generateTrait("lilNounsBalance", Strings.toString(lilNounsBalance))
      );
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _generateTrait(string memory _key, string memory _value)
    internal
    pure
    returns (string memory __traits)
  {
    return string.concat('{"trait_type":' '"', _key, '",', '"value":', '"', _value, '"}');
  }

  function _generateTraits(string[] memory _keys, string[] memory _values)
    internal
    pure
    returns (string memory __traits)
  {
    string memory _traits = "";
    for (uint256 i = 0; i < _keys.length; i++) {
      if (bytes(_values[i]).length > 0) {
        _traits = string.concat(_traits, _generateTrait(_keys[i], _values[i]), ",");
      }
    }
    return _traits;
  }

  function _getUnwrappedTraits(address user) internal view returns (string memory) {
    (string[] memory keys_, string[] memory values_) = _getEnsTextFields(user);
    return _generateTraits(keys_, values_);
  }

  function _getEnsTextFields(address _user)
    internal
    view
    returns (string[] memory, string[] memory)
  {
    IStream _source = IStream(_streamEns);
    uint256 count = _source.count(_user);

    string[] memory keys_ = new string[](count);
    string[] memory values_ = new string[](count);

    (string[] memory keys__, string[] memory values__) = _source.getData(_user);

    for (uint256 k = 0; k < count; k++) {
      keys_[k] = (keys__[k]);
      values_[k] = values__[k];
    }

    return (keys_, values_);
  }
}