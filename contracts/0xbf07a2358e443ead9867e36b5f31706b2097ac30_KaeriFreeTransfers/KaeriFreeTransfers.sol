/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface KaeriToken is IERC20 {
    function setIsFeeExempt(address holder, bool exempt) external;
}

contract KaeriFreeTransfers {
    KaeriToken constant kaeri = KaeriToken(0x69Ed89ecd35082E031fE52b75123F801DB083306);

    constructor () {}
    
    function transferMulti(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Mismatch on input sizes");

        uint256 rl = recipients.length;

        kaeri.setIsFeeExempt(msg.sender, true);

        for(uint256 i = 0; i < rl; i++) {
            kaeri.transferFrom(msg.sender, recipients[i], amounts[i]);
        }

        kaeri.setIsFeeExempt(msg.sender, false);
    }

    function transferMultiSame(address[] memory recipients, uint256 amount) external {
        uint256 rl = recipients.length;

        kaeri.setIsFeeExempt(msg.sender, true);

        for(uint256 i = 0; i < rl; i++) {
            kaeri.transferFrom(msg.sender, recipients[i], amount);
        }

        kaeri.setIsFeeExempt(msg.sender, false);
    }

    function transferSingle(address recipient, uint256 amount) external {
        kaeri.setIsFeeExempt(msg.sender, true);

        kaeri.transferFrom(msg.sender, recipient, amount);

        kaeri.setIsFeeExempt(msg.sender, false);
    }


}