// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/token/ERC20/ERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "../dependencies/open-zeppelin/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract DogeContract is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("DOGE", "DOGE");
        __Ownable_init();
        _mint(msg.sender, 44_000_000_000 * 1e18);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner{
      _mint(to, amount);
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
        ERC20Upgradeable(token).transfer(
            msg.sender,
            ERC20Upgradeable(token).balanceOf(address(this))
        );
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "BNB_TRANSFER_FAILED");
    }

    /**
     * @dev Withdraw BNB to an address, revert if it fails.
     * @param recipient recipient of the transfer
     * @param amountBNB amount of the transfer
     */
    function withdrawBNB(address recipient, uint256 amountBNB)
        public
        onlyOwner
    {
        if (amountBNB > 0) {
            _safeTransferBNB(recipient, amountBNB);
        } else {
            _safeTransferBNB(recipient, address(this).balance);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}