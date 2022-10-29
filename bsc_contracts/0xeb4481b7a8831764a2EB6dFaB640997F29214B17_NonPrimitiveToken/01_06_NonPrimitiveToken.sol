// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import "Ownable.sol";
import "ERC20.sol";


/// @title `NonPrimitiveToken` is the token minted and burnt on the chains where there is no
/// Primitive Token for a cross-chain asset. Primitive Token is either a native token or a ERC-20 token
/// which already exists. `NonPrimitiveToken` is deployed by XY Token Bridge. For `NonPrimitiveToken` to be minted,
/// there must have been 1:1 Primitive Token locked on some other chain. In contrast, to unlock Primitive Token,
/// there must have been 1:1 NonPrimitiveToken burnt.
contract NonPrimitiveToken is ERC20, Ownable {
    /// @param name_ ERC-20 token name
    /// @param symbol_ ERC-20 token symbol
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    mapping (address => bool) public isMinter;

    modifier onlyMinter {
        require(isMinter[msg.sender], "ERR_NOT_MINTER");
        _;
    }

    function setMinter(address minter, bool _isMinter) external onlyOwner {
        isMinter[minter] = _isMinter;

        emit SetMinter(minter, _isMinter);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    event SetMinter(address minter, bool isMinter);
}