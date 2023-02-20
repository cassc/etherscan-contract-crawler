// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";

contract Bing is ERC20Capped {

  error InactiveClaim();
  error NothingToClaim();
  error SecretCodeUsed();
  error NoBingChilling();
  error NoMao();

  uint256 private immutable mintStart;
  uint256 private immutable mintEnd;

  uint256 private constant DEFAULT_AMT = 10_000 ether;
  uint256 private constant MAO_CLAIMABLE_AMT = 100_000 ether;
  uint256 private constant BING_CHILLING_AMT = 10_000 ether;
  uint256 private constant SECRET_AMT = 1_000_000 ether;

  mapping (uint256 => bool) private _maosClaimed;
  mapping (address => bool) private _defaultClaimed;
  mapping (address => uint256) private _bcClaimedCounts;
  mapping (bytes32 => bool) _secretCodeAvailable;

  // https://app.manifold.xyz/c/bing-chilling
  IERC1155 private constant _BING_CHILLING = IERC1155(0xfC3a79B5eBcE162cc469E6A8C0d34fd9a7689d88); // DUMMY

  // https://getmao.art
  IERC721 private constant _MAO = IERC721(0x3A062FC7eE9F28D19a4BC039D8C3D1fd2055035c);

  constructor() 
    ERC20("Bing Chilling", "BING CHILLING")
    ERC20Capped(1_000_000_000 ether) {
      mintStart = 1676764800; // Feb 19 0000
      mintEnd = 1680307200; // Apr 01 0000

      // Secrets will be released on https://twitter.com/mao_nft
      _secretCodeAvailable[0xcfd7ead781eeacc358449284d5ef5d978b19415a1d0e6254cae44c0cb74a4167] = true;
      _secretCodeAvailable[0x0e6142e41927defbd404d5f378a0d8ba0cb5bbe55e87801691642eff81a9f4af] = true;
      _secretCodeAvailable[0x0da9d3a6c2530853d4d209964c6065c364910be17a247acb68a9bded8ea57b28] = true;
      _secretCodeAvailable[0xd475a81d3fb5d4fe1d78acff88f6644181206c44074ae89aa3930a63e2748196] = true;
      _secretCodeAvailable[0xb808e9ca89231c29b22e65f5465c7d054c3d121510204f3af8e2fbdb1ff28975] = true;
  }

  modifier claimWhenActive {
    if ((block.timestamp < mintStart) || (block.timestamp > mintEnd)) {
      revert InactiveClaim();
    }
    _;
  }

  function claim() external claimWhenActive {
    if (_defaultClaimed[_msgSender()]) {
      revert NothingToClaim();
    }
    _defaultClaimed[_msgSender()] = true;
    _mint(_msgSender(), DEFAULT_AMT);
  }

  function maoClaim(uint256[] calldata maoIds) external claimWhenActive {
    if (_MAO.balanceOf(_msgSender()) == 0) {
      revert NoMao();
    }

    _batchMaoMint(maoIds);
  }

  function _batchMaoMint(uint256[] calldata maoIds) private {
    uint256 totalClaimableAmount;
    for (uint256 i = 0; i < maoIds.length; i++) {
      if (!_maosClaimed[maoIds[i]]) {
        _maosClaimed[maoIds[i]] = true;
        totalClaimableAmount += MAO_CLAIMABLE_AMT;
      }
    }

    if (totalClaimableAmount == 0) {
      revert NothingToClaim();
    }

    _mint(_msgSender(), totalClaimableAmount);
  }

  function bingChillingClaim() external claimWhenActive {
    uint256 bingChillingCount = _BING_CHILLING.balanceOf(_msgSender(), 2);
    if (bingChillingCount == 0) {
      revert NoBingChilling();
    }

    uint256 lastClaimedCnt = _bcClaimedCounts[_msgSender()];
    uint256 effectiveCnt = (bingChillingCount > lastClaimedCnt) 
      ? (bingChillingCount - lastClaimedCnt)
      : 0;

    if (effectiveCnt == 0) {
      revert NothingToClaim();
    }

    _bcClaimedCounts[_msgSender()] = bingChillingCount;
    _mint(_msgSender(), effectiveCnt * BING_CHILLING_AMT);
  }

  function secretClaim(string memory secret) external claimWhenActive {
    bytes32 _secret = keccak256(bytes(secret));
    if (!_secretCodeAvailable[_secret]) {
      revert SecretCodeUsed();
    }

    _secretCodeAvailable[_secret] = false;
    _mint(_msgSender(), SECRET_AMT);
  }
}