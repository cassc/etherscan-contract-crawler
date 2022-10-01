pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BondUnit contract
/// @author Justin Position
/// @dev Control bond units (token)
abstract contract BondUnitLending is ERC20 {
    // the fixed supply bond ever mint
    uint256 public bondSupply;
    string private bondName;
    string private bondSymbol;

    constructor() ERC20("", "") {}


    function initBondUnit(
        uint256 bondSupply_,
        string memory name_,
        string memory symbol_)
    internal {
        bondSupply = bondSupply_;
        bondName = name_;
        bondSymbol = symbol_;
    }

    function name() public view override(ERC20) returns (string memory) {
        return bondName;
    }

    function symbol() public view override(ERC20) returns (string memory) {
        return bondSymbol;
    }

    function _mint(address account, uint256 amount) internal override(ERC20) {
        super._mint(account, amount);
        require(totalSupply() <= bondSupply, "over supply");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        if (from != address(0))
            require(_bondTransferable(), "not transferable");
    }

    function _bondTransferable() internal virtual returns (bool);
}