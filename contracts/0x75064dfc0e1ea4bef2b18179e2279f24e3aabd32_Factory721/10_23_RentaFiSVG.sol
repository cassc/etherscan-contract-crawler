// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

library RentaFiSVG {
  function weiToEther(uint256 num) public pure returns (string memory) {
    if (num == 0) return '0.0';
    bytes memory b = bytes(Strings.toString(num));
    uint256 n = b.length;
    if (n < 19) for (uint256 i = 0; i < 19 - n; i++) b = abi.encodePacked('0', b);
    n = b.length;
    uint256 k = 18;
    for (uint256 i = n - 1; i > n - 18; i--) {
      if (b[i] != '0') break;
      k--;
    }
    uint256 m = n - 18 + k + 1;
    bytes memory a = new bytes(m);
    for (uint256 i = 0; i < k; i++) a[m - 1 - i] = b[n - 19 + k - i];
    a[m - k - 1] = '.';
    for (uint256 i = 0; i < n - 18; i++) a[m - k - 2 - i] = b[n - 19 - i];
    return string(a);
  }

  function getYieldSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _benefit,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name,
    string memory _tokenSymbol
  ) public pure returns (bytes memory) {
    string memory parsed = weiToEther(_benefit);
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>Yield NFT - RentaFi</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400' text-anchor='end'><tspan x='465' y='150'>",
          _tokenSymbol,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>Claimable Funds</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900'><tspan x='440' y='150' text-anchor='end'>",
          parsed,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='270'>"
        ),
        abi.encodePacked(
          _name,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='283'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='270'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='283'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      abi.encodePacked(
        '{"name": "yieldNFT #',
        Strings.toString(_lockId),
        ' - RentaFi", "description": "YieldNFT represents Rental Fee deposited by Borrower in a RentaFi Escrow. The owner of this NFT can claim rental fee after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"'
      ),
      abi.encodePacked(
        Strings.toString(_lockStartTime),
        '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
        Strings.toString(_lockExpireTime),
        '"},{"trait_type":"FeeAmount", "value":"',
        parsed,
        '"},{"trait_type":"Collection", "value":"',
        _name,
        '"}]}'
      )
    );

    return json;
  }

  function getOwnershipSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name
  ) public pure returns (bytes memory) {
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>RentaFi Ownership NFT</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='280' y='270'>Until Unlock</tspan><tspan x='430' y='270'>Day</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>",
          _name,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900' text-anchor='end'><tspan x='425' y='270'>",
          Strings.toString((_lockExpireTime - _lockStartTime) / 1 days)
        ),
        abi.encodePacked(
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='170'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='185'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='200'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      '{"name": "OwnershipNFT #',
      Strings.toString(_lockId),
      ' - RentaFi", "description": "OwnershipNFT represents Original NFT locked in a RentaFi Escrow. The owner of this NFT can claim original NFT after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
      Strings.toString(_lockStartTime),
      '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
      Strings.toString(_lockExpireTime),
      '"},{"trait_type": "Collection", "value":"',
      _name,
      '"}]}'
    );

    return json;
  }
}