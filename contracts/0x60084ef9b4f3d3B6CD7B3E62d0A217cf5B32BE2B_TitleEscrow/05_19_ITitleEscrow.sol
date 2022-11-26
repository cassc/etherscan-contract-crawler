// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Title Escrow for Transferable Records
interface ITitleEscrow is IERC721Receiver {
  event TokenReceived(
    address indexed beneficiary,
    address indexed holder,
    bool indexed isMinting,
    address registry,
    uint256 tokenId
  );
  event Nomination(address indexed prevNominee, address indexed nominee, address registry, uint256 tokenId);
  event BeneficiaryTransfer(
    address indexed fromBeneficiary,
    address indexed toBeneficiary,
    address registry,
    uint256 tokenId
  );
  event HolderTransfer(address indexed fromHolder, address indexed toHolder, address registry, uint256 tokenId);
  event Surrender(address indexed surrenderer, address registry, uint256 tokenId);
  event Shred(address registry, uint256 tokenId);

  function nominate(address nominee) external;

  function transferBeneficiary(address nominee) external;

  function transferHolder(address newHolder) external;

  function transferOwners(address nominee, address newHolder) external;

  function beneficiary() external view returns (address);

  function holder() external view returns (address);

  function active() external view returns (bool);

  function nominee() external view returns (address);

  function registry() external view returns (address);

  function tokenId() external view returns (uint256);

  function isHoldingToken() external returns (bool);

  function surrender() external;

  function shred() external;
}