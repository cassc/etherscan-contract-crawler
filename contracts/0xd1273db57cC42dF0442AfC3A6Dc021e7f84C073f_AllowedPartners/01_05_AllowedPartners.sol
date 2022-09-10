// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/IAllowedPartners.sol";

import "../utils/Ownable.sol";

contract AllowedPartners is Ownable, IAllowedPartners {
    uint256 public constant HUNDRED_PERCENT = 10000;

    mapping(address => uint16) private partnerRevenueShare;

    mapping(address => bool) private isDelegated;

    event PartnerRevenueShare(address indexed partner, uint16 revenueShareInBasisPoints);

    constructor(address _admin) Ownable(_admin) {
        // solhint-disable-previous-line no-empty-blocks
    }

    modifier onlyOwnerOrDelegated {
      require((owner() == _msgSender()) || (isDelegated[_msgSender()] == true), "caller is not owner nor delegated");
      _;
    }

    function setDelegated(address delegate, bool enabled) external onlyOwner {
        _setDelegated(delegate, enabled);
    }

    function getDelegated(address delegate) external view returns (bool){
        return isDelegated[delegate];
    }

    function setPartnerRevenueShare(address _partner, uint16 _revenueShareInBasisPoints) external onlyOwnerOrDelegated {
        require(_partner != address(0), "Partner is address zero");
        require(_revenueShareInBasisPoints <= HUNDRED_PERCENT, "Revenue share too big");
        partnerRevenueShare[_partner] = _revenueShareInBasisPoints;
        emit PartnerRevenueShare(_partner, _revenueShareInBasisPoints);
    }

    function getPartnerPermit(address _partner) external view override returns (uint16) {
        return partnerRevenueShare[_partner];
    }

    function _setDelegated(address _delegate, bool _enabled) internal {
        require(_delegate != address(0), "delegate is zero address");
        isDelegated[_delegate] = _enabled;
    }
}