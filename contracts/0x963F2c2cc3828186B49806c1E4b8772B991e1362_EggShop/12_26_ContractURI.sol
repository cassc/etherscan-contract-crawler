// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;
import './Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

abstract contract ContractURI is Base64 {
  using Strings for uint256;

  string _collectionName;
  string _collectionDescription;
  string _imageUri;
  string _externalLink;
  uint256 _sellerRoyaltyFee;
  address _recipient;

  /**
   * @notice Returns OpenSea contract URI interface. Generates a JSON metadata response
   * without referencing off-chain content (owner, royalties etc...)
   * @return a encoded base64 JSON contract level metadata
   */
  function contractURI() public view returns (string memory) {
    return
      string.concat(
        'data:application/json;base64,',
        Base64.base64(
          bytes(
            string.concat(
              '{"name": "',
              _collectionName,
              '", "description": "',
              _collectionDescription,
              '", "image": "',
              _imageUri,
              '", "external_link": "',
              _externalLink,
              '", "seller_fee_basis_points": ',
              _sellerRoyaltyFee.toString(),
              '", "fee_recipient": "',
              Strings.toHexString(_recipient),
              '"}'
            )
          )
        )
      );
  }
}