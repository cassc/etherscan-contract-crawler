// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MembershipPoints {
    mapping(uint256 => uint256) internal MembershipPointsMap;

    event MembershipPointsChanged(uint256 indexed passId, int256 indexed amount, address operatorAddress, uint256 membershipPointsNow, address ownerNow);

    function _modifyMembershipPoints(uint256 _passId, int256 _amount, address _ownerNow) internal virtual {
        require(
            int256(MembershipPointsMap[_passId]) + _amount >= 0,
            "amount verify failed"
        );
        MembershipPointsMap[_passId] = uint256(int256(MembershipPointsMap[_passId]) + _amount);
        emit MembershipPointsChanged(_passId, _amount, msg.sender, MembershipPointsMap[_passId], _ownerNow);
    }

    function getMembershipPoints(uint256 passId) public view returns (uint256) {
        return MembershipPointsMap[passId];
    }
}