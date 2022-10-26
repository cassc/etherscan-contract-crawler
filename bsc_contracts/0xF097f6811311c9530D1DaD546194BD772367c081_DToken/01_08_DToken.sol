// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ERC20.sol";
import "../interfaces/IDToken.sol";
import "../interfaces/ILogic.sol";

contract DToken is IDToken, ERC20, IERC20Metadata, Ownable {
    bytes32 immutable NAME;
    bytes32 immutable SYMBOL;
    uint8   immutable DECIMALS;

    /// @dev this should be standard
    event ERC20Created(
        address indexed creator,
        bytes32 indexed name,
        bytes32 indexed symbol,
        uint            decimals
    );

    constructor(ILogic logic_, uint idx_) {
        (NAME, SYMBOL, DECIMALS) = logic_.getDTokenInfo(idx_);
        transferOwnership(logic_.POOL());
        emit ERC20Created(_msgSender(), NAME, SYMBOL, DECIMALS);
    }

    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked(NAME));
    }

    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked(SYMBOL));
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function mint(uint256 amount_, address account_) external override onlyOwner {
        _mint(account_, amount_);
    }

    function burn(uint256 amount_, address account_) external override onlyOwner {
        _burn(account_, amount_);
    }

    function burn(address account_) external override onlyOwner {
        _burn(account_, balanceOf(account_));
    }
}