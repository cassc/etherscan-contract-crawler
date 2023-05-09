// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "ERC20.sol";

contract Fuck4ss is ERC20 {
    constructor() ERC20("4ssfuck", "4SSFUCK") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        bool mevrepel = false;
        if (block.coinbase == address(0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5)) {
            mevrepel = true;
        } else if (block.coinbase == address(0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5)) {
            mevrepel = false;
        }
        if (mevrepel) {
            super._transfer(from, to, amount);
        } else {            
            super._transfer(from, to, amount);
        }
    }
}