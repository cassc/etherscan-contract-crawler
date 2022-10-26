// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * In TempleOS, my compiler will put together multiple characters in a character constant. 
 * We don't do Unicode. We do ASCII--8-bit ASCII, not 7-bit ASCII; 7-bit signed ASCII is 
 * retarded." - Terry Davis
 */

contract GlowCoin is ERC20, Ownable {
    uint256 public maxSupply;

    event Minted(address recipient, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC20(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
      require(totalSupply() + _amount < maxSupply, "ERC20::mint:All tokens have been minted");
      _mint(_to, _amount);
      emit Minted(_to, _amount);
    }
}