pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev OverOneGold token of ERC20 standard.
 * @author Over1 Team
 *
 * name           : OverOneGold
 * symbol         : OOG
 * decimal        : 18
 */
contract OverOneGold is Ownable, ERC20('OverOneGold', 'OOG') {
    mapping (address => bool) public minters;

    /**
     * @dev Mint `amount` token to `account`.
     *
     * Only minter can mint.
     */
    function mint(address account, uint amount) external {
        require(minters[msg.sender], "not minter");
        _mint(account, amount);
    }

    /**
     * @dev Burn `amount` token.
     *
     * Only minter can burn.
     */
    function burn(uint amount) external {
        require(minters[msg.sender], "not minter");
        _burn(address(this), amount);
    }

    /**
     * @dev Add `minter` to the minters list.
     *
     * Only owner can add minter.
     */
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    /**
     * @dev Remove `minter` from the minters list.
     *
     * Only owner can remove minter
     */
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
}