pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract LMC is ERC20Burnable, AccessControlEnumerable {
    uint256 public constant MAX_SUPPLY = 1e9 * 1e18;

    bytes32 public constant MINT_ROLE = bytes32(uint256(1));

    constructor() ERC20("Littlemami Coin", "LMC") {
        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), MAX_SUPPLY / 20);
    }

    function mint(
        address _account,
        uint256 _amount
    ) external onlyRole(MINT_ROLE) {
        require(
            _amount + totalSupply() <= MAX_SUPPLY,
            "LM : Out of max supply"
        );
        _mint(_account, _amount);
    }
}