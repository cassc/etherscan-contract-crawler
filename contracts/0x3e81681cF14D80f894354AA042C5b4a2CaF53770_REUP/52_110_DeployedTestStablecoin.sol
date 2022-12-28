// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract DeployedTestStablecoin is ERC20, ERC20Permit {
    uint8 immutable _decimals;
    bool immutable _hasPermit;

    bool public constant isFakeStablecoin = true;

    constructor(uint8 __decimals, bool __hasPermit)
        ERC20(
            __decimals == 6 ? "Test 6 Decimals" : "Test 18 Decimals",
            __decimals == 6 ? "Test6" : "Test18"
        )
        ERC20Permit(__decimals == 6 ? "Test 6 Decimals" : "Test 18 Decimals")
    {
        assert(__decimals == 6 || __decimals == 18);
        _decimals = __decimals;
        _hasPermit = __hasPermit;
        _mint(msg.sender, __decimals == 6 ? 10**19 : 10**31);
    }

    function decimals() public view virtual override returns (uint8)
    {
        return _decimals;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        assert(_hasPermit);
        ERC20Permit.permit(owner, spender, value, deadline, v, r, s);
    }
}