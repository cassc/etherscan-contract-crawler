// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../RoyaltiesV2.sol";

//  https://github.com/rarible/protocol-contracts/blob/master/royalties/contracts/impl/RoyaltiesV2Impl.sol

contract RoyaltiesV2Impl is RoyaltiesV2 {
    address public royaltyReceiver;
    uint96 public royaltiesPercentageBasisPoints;
    uint96 public originalTokenOwnersPercentageBasisPoints = 300;

    mapping(uint256 => address) internal _originalTokenOwners;

    event UpdateRoyaltyReceiver(address newRoyaltyReceiver);
    event UpdateRoyaltyShare(uint256 newRoyaltyPercentage);

    function _updateRoyaltyReceiver(address newRoyaltyReceiver) internal {
        royaltyReceiver = newRoyaltyReceiver;
        emit UpdateRoyaltyReceiver(newRoyaltyReceiver);
    } 

    function _updateRoyaltyShare(uint96 percentageBasisPoints) internal {
        royaltiesPercentageBasisPoints = percentageBasisPoints;
        emit UpdateRoyaltyShare(percentageBasisPoints);
    } 

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](2);
        
        _royalties[0].value = originalTokenOwnersPercentageBasisPoints;
        _royalties[0].account = payable(_originalTokenOwners[id]);

        _royalties[1].value = royaltiesPercentageBasisPoints;
        _royalties[1].account = payable(royaltyReceiver);

        return _royalties;
    }

}