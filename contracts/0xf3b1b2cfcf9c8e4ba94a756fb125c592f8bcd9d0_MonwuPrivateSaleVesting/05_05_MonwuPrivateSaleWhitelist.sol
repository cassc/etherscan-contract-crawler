// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MonwuPrivateSaleWhitelist is Ownable {

  struct WhitelistedInvester {
    address investor; 
    uint256 allocation;
    uint256 etherAmountToPay;
  }

  address whitelistOwner = 0x76bAf177d89B124Fd331764d48faf5bc6849A442;

  mapping(address => WhitelistedInvester) public whitelist;

  constructor () {
    transferOwnership(whitelistOwner);
  }


  event AddressAddedToWhitelist(address investor, uint256 allocation, uint256 etherAmountToPay);
  event EditedWhitelistedAddress(address investor,  uint256 newAllocation, uint256 newEtherAmountToPay);
  event AddressRemovedFromWhitelist(address investor);


  // ====================================================================================
  //                                  OWNER INTERFACE
  // ====================================================================================

  function addToWhitelist(address investor, uint256 allocation, uint256 etherAmountToPay) 
    external onlyOwner nonZeroAddress(investor) uniqueInvestor(investor) {

    WhitelistedInvester memory whitelistedInvestor = WhitelistedInvester(
      investor,
      allocation,
      etherAmountToPay
    );

    whitelist[investor] = whitelistedInvestor;

    emit AddressAddedToWhitelist(investor, allocation, etherAmountToPay);
  }

  function editWhitelistedInvestor(address investorToEdit, uint256 editedAllocation, uint256 editedEtherAmountToPay)
    external onlyOwner nonZeroAddress(investorToEdit) {

    whitelist[investorToEdit].allocation = editedAllocation;
    whitelist[investorToEdit].etherAmountToPay = editedEtherAmountToPay;

    emit EditedWhitelistedAddress(investorToEdit, editedAllocation, editedEtherAmountToPay);
  }

  function removeFromWhitelist(address investor)
    external onlyOwner nonZeroAddress(investor) {

    whitelist[investor].investor = address(0);
    whitelist[investor].allocation = 0;
    whitelist[investor].etherAmountToPay = 0;

    emit AddressRemovedFromWhitelist(investor);
  }

  // ====================================================================================
  //                                 PUBLIC INTERFACE
  // ====================================================================================

  function getWhitelistedAddressData(address investor) external view returns(address, uint256, uint256) {
    return (whitelist[investor].investor, whitelist[investor].allocation, whitelist[investor].etherAmountToPay);
  }


  // ====================================================================================
  //                                     MODIFIERS
  // ====================================================================================

  modifier nonZeroAddress(address investor) {
    require(investor != address(0), "Address cannot be zero");
    _;
  }

  modifier uniqueInvestor(address investor) {
    require(whitelist[investor].investor == address(0), "Investor already whitelisted");
    _;
  }
}