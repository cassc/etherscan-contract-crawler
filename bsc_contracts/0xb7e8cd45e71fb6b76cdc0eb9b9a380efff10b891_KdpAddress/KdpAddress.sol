/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface KdpSwap {
    function whiteMap(address _user) external view returns (bool);
    function blackMap(address _user) external view returns (bool);
}
interface BindParent {
    function getParent(address _user) external view returns (address);
}
contract KdpAddress {
    BindParent public bindParent = BindParent(0x4346497C901aB8dd7ebc7F85e281e988A0ECc8B4);
    KdpSwap public kdpSwap = KdpSwap(0x15459aafc540D44ebBa7AF61e04926D99516858c);
    struct UserData {
        address user;
        address parent;
        uint256 balance;
        bool white;
        bool black;
    }
    function getInfoList(address[] memory _list) public view returns (UserData[] memory) {
        UserData[] memory result = new UserData[](_list.length);
        for (uint256 i=0; i < _list.length; i++) {
            result[i] = UserData({
                user:_list[i],
                parent:bindParent.getParent(_list[i]),
                balance:address(_list[i]).balance,
                white:kdpSwap.whiteMap(_list[i]),
                black:kdpSwap.blackMap(_list[i])});
        }
        return result;
    }
}