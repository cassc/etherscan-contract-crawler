// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// NOTE! - this is not an ERC20 token. transfer is not supported.
contract CropJoinAdapter {
    string constant public name = "B.AMM THUSD-COLLATERAL";
    string constant public symbol = "THUSDCOLL";
    uint256 constant public decimals = 18;
    
    uint256 internal total;                    // total gems      [wad]
    mapping (address => uint256) public stake; // gems per user   [wad]

    event Join(uint256 val);
    event Exit(uint256 val);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    function totalSupply() public view returns (uint256) {
        return total;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        balance = stake[owner];
    }

    function mint(address to, uint256 value) virtual internal {
        if (value > 0) {
            total += value;
            stake[to] += value;
        }
        emit Join(value);
        emit Transfer(address(0), to, value);
    }

    function burn(address owner, uint256 value) virtual internal {
        if (value > 0) {
            total -= value;
            stake[owner] -= value;
        }
        emit Exit(value);
        emit Transfer(owner, address(0), value);        
    }
}