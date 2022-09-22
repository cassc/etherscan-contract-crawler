// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Royalties is IERC2981{

  struct Fraction{
    uint16 numerator;
    uint16 denominator;
  }

  struct Royalty{
    address receiver;
    Fraction fraction;
  }

  Royalty public defaultRoyalty;

  constructor( address receiver, uint16 royaltyNum, uint16 royaltyDenom ){
    _setDefaultRoyalty( receiver, royaltyNum, royaltyDenom );
  }

  //view: IERC2981
  /**
   * @dev See {IERC2981-royaltyInfo}.
   **/
  function royaltyInfo(uint256, uint256 _salePrice) external view virtual returns (address, uint256) {
    /*
    Royalty memory royalty = _tokenRoyaltyInfo[_tokenId];
    if (royalty.receiver == address(0)) {
        royalty = _defaultRoyaltyInfo;
    }
    */

    uint256 royaltyAmount = (_salePrice * defaultRoyalty.fraction.numerator) / defaultRoyalty.fraction.denominator;
    return (defaultRoyalty.receiver, royaltyAmount);
  }

  //view: IERC165
  /**
   * @dev See {IERC165-supportsInterface}.
   **/
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC2981).interfaceId;
  }


  function _setDefaultRoyalty( address receiver, uint16 royaltyNum, uint16 royaltyDenom ) internal {
    defaultRoyalty.receiver = receiver;
    defaultRoyalty.fraction = Fraction(royaltyNum, royaltyDenom);
  }
}