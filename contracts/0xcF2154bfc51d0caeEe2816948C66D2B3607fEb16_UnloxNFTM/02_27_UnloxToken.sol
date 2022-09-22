pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UnloxToken is Ownable, ERC20Burnable, ERC20Pausable, ReentrancyGuard {
    constructor() public ERC20("Unlox", "ULOX") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    function unpause() public onlyOwner whenPaused {
        super._unpause();
    }

    function issueBonusCoin(address receiverAddr, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        assert(amount > 0);
        _mint(receiverAddr, amount);
    }

    function useCoinFrom(address account, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        _burn(account, amount);
    }
}