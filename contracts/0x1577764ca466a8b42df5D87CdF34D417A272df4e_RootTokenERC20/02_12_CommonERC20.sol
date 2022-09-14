// SPDX-License-Identifier: Playchain
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract CommonERC20 is ERC20, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    modifier only(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }

    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function claimEthers() external only(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function claimTokens(address _contract) external only(DEFAULT_ADMIN_ROLE) {
        IERC20 other_token = IERC20(_contract);
        other_token.transfer(msg.sender, other_token.balanceOf(address(this)));
    }

    function pause() external whenNotPaused only(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external whenPaused only(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Burning can be done as per requirement
     * @param user user for whom tokens are being burned
     * @param amount amount of token to mint
     */
    function burn(address user, uint256 amount) public only(BURNER_ROLE) {
        _burn(user, amount);
    }

}