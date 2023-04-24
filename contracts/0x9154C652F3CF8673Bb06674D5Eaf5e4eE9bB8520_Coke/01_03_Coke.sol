// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
           /`-._      _,
          /      `-._(  \
         /           \\  \
        /             \\  \`-._
       /           .   \\  \    `-._
      /           :).   \\  \        `-.
     /           ./;.    \\  \         /
    /           .;'       \\  \       /
   /   .        .          \\  \     /
  /  .; ):.   __________    \\  \   /
 /   . :" '  |~~_~__ _  |    \\(_) /
/       '    ) (_=__=_) (     \(.`/
`-._         |-_________|        /
     `-._                       /
          `-._                 /
               `-._           /
                    `-._     /
                         `-./
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀*/

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract Coke is ERC20, Ownable {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    mapping(address => bool) internal blacklist;
    uint256 internal timestampLaunch;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _initializeOwner(msg.sender);
        blacklist[address(0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13)] = true;
        blacklist[address(0x77ad3a15b78101883AF36aD4A875e17c86AC65d1)] = true;
        timestampLaunch = block.timestamp;
    }

    modifier notBlacklisted(address from, address to) {
        if (block.timestamp < timestampLaunch + 2 hours)
            require(!blacklist[to] && !blacklist[from], "Blacklisted");
        _;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 value) public virtual onlyOwner {
        _mint(_brutalized(to), value);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        return super.transfer(_brutalized(to), amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override notBlacklisted(from, to) returns (bool) {
        return super.transferFrom(_brutalized(from), _brutalized(to), amount);
    }

    function increaseAllowance(
        address spender,
        uint256 difference
    ) public virtual override returns (bool) {
        return super.increaseAllowance(_brutalized(spender), difference);
    }

    function decreaseAllowance(
        address spender,
        uint256 difference
    ) public virtual override returns (bool) {
        return super.decreaseAllowance(_brutalized(spender), difference);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }

    function isBased(address guy) public view returns (bool) {
        bool _isBased;
        balanceOf(guy) > 0 ? _isBased = true : _isBased = false;
        return _isBased;
    }
}