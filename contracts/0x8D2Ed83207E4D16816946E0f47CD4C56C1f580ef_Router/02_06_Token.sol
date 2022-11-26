// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Token Factory
/// @author Potemkin Viktor
/// @notice Factory for creating tokens for internal use 
/// @notice Factory owner access to user funds management

contract Token is ERC20 {

    ERC20 public tokenAddress;
    address private factoryOwner;
    uint8 public _decimals;
    address private router;

    constructor(
        address tokenAddress_,
        address router_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint8 decimals_
        ) ERC20(tokenName_, tokenSymbol_) {
        tokenAddress = ERC20(tokenAddress_);
        router = router_;
        _decimals = decimals_;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "Not router use function");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        _burn(owner, amount);
        tokenAddress.transferFrom(router, to, amount);
        return true;
    }

    function mint(address _account, uint256 _amount) external onlyRouter {
        _mint(_account, _amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {}

}