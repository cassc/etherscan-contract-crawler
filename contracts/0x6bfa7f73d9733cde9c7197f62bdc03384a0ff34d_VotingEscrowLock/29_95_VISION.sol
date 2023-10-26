//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/governance/Governed.sol";

contract VISION is ERC20, Governed, Initializable {
    address private _minter;
    string private _name;
    string private _symbol;

    constructor() ERC20("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    modifier onlyMinter {
        require(msg.sender == _minter, "Not a minter");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address minter_,
        address gov_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _minter = minter_;
        Governed.initialize(gov_);
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address minter_) public governed {
        _setMinter(minter_);
    }

    function _setMinter(address minter_) internal {
        _minter = minter_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function minter() public view returns (address) {
        return _minter;
    }
}