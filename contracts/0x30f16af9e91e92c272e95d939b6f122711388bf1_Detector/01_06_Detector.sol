// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../interfaces/IMarket.sol';
import '../ERC4907/IERC4907.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

library Detector {
  function is721(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC721).interfaceId);
  }

  function is1155(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC1155).interfaceId);
  }

  function is4907(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC4907).interfaceId);
  }

  function availability(
    address _originalNftAddress,
    IMarket.Rent[] calldata _rents,
    IMarket.Lend calldata _lend,
    uint256 _rentalStartTime,
    uint256 _rentalExpireTime
  ) public view returns (uint256) {
    uint256 _rentaled;
    // ERC721 availability
    if (is721(_originalNftAddress)) {
      // Check for rental availability
      unchecked {
        for (uint256 i = 0; i < _rents.length; i++) {
          // Periods A-B and C-D overlap only if A<=D && C<=B
          if (
            _rents[i].rentalStartTime <= _rentalExpireTime &&
            _rentalStartTime <= _rents[i].rentalExpireTime
          ) _rentaled += _rents[i].amount;
        }
        // Check for rental availability
        return _lend.amount - _rentaled;
      }
    }

    // ERC1155 availability
    if (is1155(_originalNftAddress)) {
      // Confirmation of the number of tokens remaining available for rent
      unchecked {
        for (uint256 i = 0; i < _rents.length; i++) {
          // Counting rent amount with overlapping periods
          // Periods A-B and C-D overlap only if A<=D && C<=B
          if (
            _rents[i].rentalStartTime <= _rentalExpireTime &&
            _rentalStartTime <= _rents[i].rentalExpireTime
          ) _rentaled += _rents[i].amount;
        }
      }
      // Check for rental availability
      return _lend.amount - _rentaled;
    }

    return 0;
  }
}