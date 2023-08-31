// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/pools/ILpToken.sol";
import "../interfaces/pools/ITorusPool.sol";

contract LpToken is ILpToken, ERC20 {
    address public immutable minter;
    modifier onlyMinter() {
        require(msg.sender == minter, "not authorized");
        _;
    }

    uint8 private __decimals;

    constructor(
        address _minter,
        uint8 _decimals,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        minter = _minter;
        __decimals = _decimals;
    }

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return __decimals;
    }

    function mint(address _account, uint256 _amount)
        external
        override
        onlyMinter
        returns (uint256)
    {
        _mint(_account, _amount);
        return _amount;
    }

    function burn(address _owner, uint256 _amount) external override onlyMinter returns (uint256) {
        _burn(_owner, _amount);
        return _amount;
    }
}