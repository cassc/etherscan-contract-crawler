//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

/**
 * @title Commit Token
 * @notice Commit Token is used for redeeming stable coins, buying crypto products
 *      from the village market and mining vision tokens. It is minted by the admin and
 *      given to the contributors. The amount of mintable token is limited to the balance
 *      of redeemable stable coins. Therefore, it's 1:1 pegged to the given stable coin
 *      or expected to have higher value than the redeemable coin values.
 */
contract COMMIT is ERC20Burnable, Initializable {
    using SafeMath for uint256;

    address private _minter;
    uint256 private _totalBurned;
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
        address minter_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _minter = minter_;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address minter_) public onlyMinter {
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

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _totalBurned = _totalBurned.add(amount);
    }
}