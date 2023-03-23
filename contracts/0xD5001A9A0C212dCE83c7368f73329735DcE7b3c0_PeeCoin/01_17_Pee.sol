// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract PeeCoin is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {

    address public Catminter;
    uint256 public maxSupply; 
    uint256 private _totalSupply; 

    constructor() ERC20("PeeCoin", "Pee") ERC20Permit("Pee") {
        _mint(0xF54be5c6d80279e105AB46F1E994D97659577600, 100000000 * 10 ** decimals());
        _totalSupply += 100000000 * 10 ** decimals(); 
        maxSupply = 200000000 * 10 ** decimals(); 
    }

    modifier onlyMinter() {
        _checkCatminter();
        _;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply; 
    }

    function mint(address to, uint256 amount) public onlyMinter {
        require(_totalSupply + amount <= maxSupply, "Exceeded max supply"); 
        _totalSupply += amount; 
        _mint(to, amount);
    }

    function _checkCatminter() internal view virtual {
        require(Catminter == _msgSender(), "Ownable: caller is not the minter");
    }



    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function setCatminter(address _minter) public onlyOwner {
        Catminter = _minter;
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        _totalSupply -= amount; 
        super._burn(account, amount);
    }
}