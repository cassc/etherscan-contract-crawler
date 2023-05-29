pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev WorldChainShare token of ERC20 standard.
 * @author Over1 Team
 *
 * name           : WorldChainShare
 * symbol         : WCS
 * decimal        : 0
 * initial supply : 1000 WCS
 */
contract WorldChainShare is Ownable, ERC20 {
    mapping (address => bool) public minters;

    /**
     * @dev Mint initial tokens.
     */
    constructor() public Ownable() ERC20('WorldChainShare', 'WCS') {
        _setupDecimals(0);
        _mint(msg.sender, 1000);
    }

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