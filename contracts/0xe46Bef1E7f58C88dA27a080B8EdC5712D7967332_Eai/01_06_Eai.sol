// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract Eai is ERC20 {
    using BitMaps for BitMaps.BitMap;

    uint256 public initTimestamp;

    address immutable minter;

    BitMaps.BitMap private minted;

    uint256 public immutable MAX_SUPPLY=10000000*10**decimals();

    uint256 public immutable MINT_PER_DAY=10000*10**decimals();

    constructor(address receiver,address _minter) ERC20("Easier Idealize", "Eai") {
        initTimestamp=block.timestamp;
        minted.set(0);
        _mint(receiver, 1000000*10**decimals());
        minter=_minter;
    }

    function mint() external {
        require(msg.sender==minter,"Address not allowed mint");
        require(totalSupply()<MAX_SUPPLY,"Already max supply");
        uint256 day=(block.timestamp-initTimestamp)/1 days;
        require(!minted.get(day),"Today had minted");
        minted.set(day);
        _mint(msg.sender, MINT_PER_DAY);
    }
}