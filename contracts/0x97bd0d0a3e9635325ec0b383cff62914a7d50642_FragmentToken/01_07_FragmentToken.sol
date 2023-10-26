// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "./interface/IFragmentToken.sol";

contract FragmentToken is ERC20, IFragmentToken {
    address public immutable trustedCallerAddress;

    constructor(string memory name, string memory symbol, address _trustedCaller) ERC20(name, symbol) {
        trustedCallerAddress = _trustedCaller;
    }

    modifier onlyTrustedCaller() {
        if (msg.sender != trustedCallerAddress) revert CallerIsNotTrustedContract();
        _;
    }

    function mint(address account, uint256 amount) public onlyTrustedCaller {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyTrustedCaller {
        _burn(account, amount);
    }
}