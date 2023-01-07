// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBasePunkTLD is IERC721 {

  struct Domain {
    string name; // domain name that goes before the TLD name; example: "tempetechie" in "tempetechie.web3"
    uint256 tokenId;
    address holder;
    string data; // stringified JSON object, example: {"description": "Some text", "twitter": "@techie1239", "friends": ["0x123..."], "url": "https://punk.domains"}
  }

  event DomainCreated(address indexed user, address indexed owner, string fullDomainName);
  event DomainBurned(address indexed user, string fullDomainName);
  event DefaultDomainChanged(address indexed user, string defaultDomain);
  event DataChanged(address indexed user);
  event TldPriceChanged(address indexed user, uint256 tldPrice);
  event ReferralFeeChanged(address indexed user, uint256 referralFee);
  event TldRoyaltyChanged(address indexed user, uint256 tldRoyalty);
  event DomainBuyingToggle(address indexed user, bool domainBuyingToggle);

  function domains(string calldata _domainName) external view returns(string memory, uint256, address, string memory);

  function defaultNames(address) external view returns(string memory);

  function getDomainData(string calldata _domainName) external view returns(string memory);

  function getDomainHolder(string calldata _domainName) external view returns(address);

  function price() external view returns (uint256);
  function referral() external view returns (uint256);

  function changeNameMaxLength(uint256 _maxLength) external;

  function changePrice(uint256 _price) external;

  function changeReferralFee(uint256 _referral) external;

  function mint(
    string memory _domainName,
    address _domainHolder,
    address _referrer
  ) external payable returns(uint256);

}