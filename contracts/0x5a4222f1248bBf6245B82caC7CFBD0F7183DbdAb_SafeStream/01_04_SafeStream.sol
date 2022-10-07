// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                          SafeStream by buildship.xyz                             //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//  ██████  ██    ██ ██ ██      ██████  ███████ ██   ██ ██ ██████                   //
//  ██   ██ ██    ██ ██ ██      ██   ██ ██      ██   ██ ██ ██   ██                  //
//  ██████  ██    ██ ██ ██      ██   ██ ███████ ███████ ██ ██████                   //
//  ██   ██ ██    ██ ██ ██      ██   ██      ██ ██   ██ ██ ██                       //
//  ██████   ██████  ██ ███████ ██████  ███████ ██   ██ ██ ██                       //
//                                                                                  //
//  contract based on                                                               //
//                                                                                  //
//  ███    ███  ██████  ███    ██ ███████ ██    ██ ██████  ██ ██████  ███████       //
//  ████  ████ ██    ██ ████   ██ ██       ██  ██  ██   ██ ██ ██   ██ ██            //
//  ██ ████ ██ ██    ██ ██ ██  ██ █████     ████   ██████  ██ ██████  █████         //
//  ██  ██  ██ ██    ██ ██  ██ ██ ██         ██    ██      ██ ██      ██            //
//  ██      ██  ██████  ██   ████ ███████    ██    ██      ██ ██      ███████       //
//                                                                                  //
//  https://moneypipe.xyz                                                           //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract SafeStream is Initializable {
    Member[] private _members;
    address private _fallback;
    uint private _cap;

    struct Member {
        address account;
        uint32 value;
        uint32 total;
    }

    function initialize(Member[] calldata m, address f) public initializer {
        for (uint i = 0; i < m.length; i++) {
            _members.push(m[i]);
        }

        // check that each member.total equals to sum of member.value
        uint32 total = 0;
        for (uint i = 0; i < _members.length; i++) {
            total += _members[i].value;
        }

        // check that total is not zero
        require(total > 0, "total is zero");

        for (uint i = 0; i < _members.length; i++) {
            require(_members[i].total == total, "total is not equal");
        }

        _fallback = f;
    }

    receive() external payable {
        require(_members.length > 0, "1");

        for (uint i = 0; i < _members.length; i++) {
            Member memory member = _members[i];

            // IMPORTANT: ignores failed transfers, collects in fallback
            _transfer(
                member.account,
                (msg.value * member.value) / member.total
            );
        }

        // failed transfers are accumulated and sent to fallback
        _transfer(_fallback, address(this).balance);
    }

    function members() external view returns (Member[] memory) {
        return _members;
    }

    function membersList() external view returns (string[] memory member_info) {
        // read all members and return as string array
        member_info = new string[](_members.length);

        for (uint i = 0; i < _members.length; i++) {
            Member memory member = _members[i];

            member_info[i] = string(
                abi.encodePacked(
                    Strings.toHexString(uint160(member.account), 20),
                    ": ",
                    Strings.toString(member.value),
                    "/",
                    Strings.toString(member.total)
                )
            );
        }

        return member_info;
    }

    function _calculateGasCap() internal view returns (uint) {
        if (_cap != 0) {
            return _cap;
        } else {
            return gasleft();
        }
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();

    function _transfer(address to, uint256 amount) internal returns (bool) {
        bool callStatus;
        uint256 c = _calculateGasCap();
        assembly {
            callStatus := call(c, to, amount, 0, 0, 0, 0)
        }
        console.log("transfer", to, amount, callStatus ? "success" : "fail");
        return callStatus;
    }

    function setHardGasCap(uint c) external {
        require(
            msg.sender == _fallback,
            "only fallback receiver can set hard cap"
        );
        require(c > 50_000, "hard cap must be greater than 50k");
        _cap = c;
    }

    function changeFallback(address f) external {
        require(
            msg.sender == f,
            "only the fallback receiver can change the fallback receiver"
        );
        _fallback = f;
    }
}