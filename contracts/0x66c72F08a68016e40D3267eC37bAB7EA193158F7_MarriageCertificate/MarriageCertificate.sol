/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface Kitties {
    function transferFrom(address _from,address _to,uint256 _tokenId) external;
}

contract MarriageCertificate {
    bool private dlf = false;
    bool private mm = false;
    address private dlf_addr = 0xD1f20230310f45A4137De550A3B11D27c1FB0A29;
    address private mm_addr = 0x8120230310Fd3B7042Af093816324fa1f41f6C5E;
    event Announce(string text);

    function sign() public {
        if (dlf && mm) {
            // only once
            return;
        }
        if (msg.sender == dlf_addr) {
            dlf = true;
        } else if (msg.sender == mm_addr) {
            mm = true;
        }
        if (dlf && mm) {
            Kitties ck = Kitties(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
            ck.transferFrom(0xafeB282Fed4F82463A00C4d19A53B68e87b8C1a4, dlf_addr, 622818);
            ck.transferFrom(0xafeB282Fed4F82463A00C4d19A53B68e87b8C1a4, mm_addr, 544883);
            emit Announce("We are married! 2023/03/10 -- dlf & miaomiao");
        }
    }

    function status() public view returns (bool) {
        return dlf && mm;
    }
}