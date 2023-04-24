pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/token/ERC20/ERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "../dependencies/open-zeppelin/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "../interfaces/ILockContract.sol";


contract AllTradeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {
    
    constructor () initializer {
        __ERC20_init("Alltrade", "ALA");
        __Ownable_init();
        _mint(msg.sender, 100_000_000 * 1e18);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._transfer(sender, recipient, amount);
    }

   /**
   * @dev Withdraw Token in contract to an address, revert if it fails.
   * @param token token withdraw
   */
  function emergencySupport(address token) public onlyOwner {
    ERC20Upgradeable(token).transfer(msg.sender, ERC20Upgradeable(token).balanceOf(address(this)));
  }
}