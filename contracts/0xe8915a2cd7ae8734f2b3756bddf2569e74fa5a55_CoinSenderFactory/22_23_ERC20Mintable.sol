// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Mintable is ERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint;

    uint256 private __maxTotalSupply;
    uint8 private __decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _maxTotalSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        _mint(_owner, _initialSupply * 10**uint256(_decimals));
        __maxTotalSupply = _maxTotalSupply * 10**uint256(_decimals);
        transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        if (__maxTotalSupply > 0 ) {
            require(totalSupply() + amount <= __maxTotalSupply, "ERC20: mint amount exceeds maxTotalSupply");
        }

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function maxTotalSupply() public view returns (uint256) {
        return __maxTotalSupply;
    }

    function decimals() public view override returns(uint8) {
        return __decimals;
    }
}