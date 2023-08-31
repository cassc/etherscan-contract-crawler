// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@iden3/contracts/validators/CredentialAtomicQuerySigValidator.sol";
import "@iden3/contracts/lib/verifierSigWrapper.sol";

contract ERC20Mock is ERC20 {
    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimalPlaces_
    ) ERC20(name_, symbol_) {
        _decimals = decimalPlaces_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to_, uint256 amount_) public {
        _mint(to_, amount_);
    }

    function burn(address to_, uint256 amount_) public {
        _burn(to_, amount_);
    }
}