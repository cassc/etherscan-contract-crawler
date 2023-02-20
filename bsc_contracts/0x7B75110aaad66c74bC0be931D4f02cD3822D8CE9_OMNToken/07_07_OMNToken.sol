// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "./interfaces/IOMN.sol";

contract OMNToken is IOMN, ERC20Capped {
    uint256 internal constant TOTAL_SUPPLY = 970_000_000 ether;

    address public treasury;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }

    constructor(
        address treasury_
    ) ERC20("Omega Network", "OMN") ERC20Capped(TOTAL_SUPPLY) {
        treasury = treasury_;
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Capped) {
        super._mint(account, amount);
    }

    function mint(
        address recipient,
        uint256 amount
    ) public override onlyTreasury {
        _mint(recipient, amount);
    }

    function burn(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}