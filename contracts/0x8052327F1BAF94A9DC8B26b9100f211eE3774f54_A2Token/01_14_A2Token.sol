// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract A2Token is ERC20, ERC20Burnable, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    string constant NAME    = 'A2DAO Token';
    string constant SYMBOL  = 'ATD';
    uint8 constant DECIMALS  = 18;
    uint256 constant TOTAL_SUPPLY = 20_000_000 * 10**uint256(DECIMALS);

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE"); //Whitelisted addresses can transfer token when paused
    bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE"); //Pause manager can pause/unpause
    bytes32 public constant TRANSFER_MANAGER_ROLE = keccak256("TRANSFER_MANAGER_ROLE"); //Transfer manager can withdraw ETH/ERC20/NFT from the contract


    modifier onlyPauseManager(){
        require(hasRole(PAUSE_MANAGER_ROLE, _msgSender()), "!pause manager");
        _;
    }

    modifier onlyTransferManager(){
        require(hasRole(TRANSFER_MANAGER_ROLE, _msgSender()), "!transfer manager");
        _;
    }

    modifier onlyDefaultAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    constructor() ERC20(NAME, SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(WHITELISTED_ROLE, _msgSender());
        _setupRole(PAUSE_MANAGER_ROLE, _msgSender());
        _setupRole(TRANSFER_MANAGER_ROLE, _msgSender());
        _mint(_msgSender(), TOTAL_SUPPLY);
        // _pause(); // no need to pause initially
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused() || hasRole(WHITELISTED_ROLE, _msgSender()), "transfers paused");
    }

    function pause() external onlyPauseManager {
        _pause();
    }

    function unpause() external onlyPauseManager {
        _unpause();
    }

    function withdrawETH() external onlyTransferManager {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyTransferManager {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }

    function withdrawERC721(IERC721 token, uint256 id) external onlyTransferManager {
        token.transferFrom(address(this), _msgSender(), id);
    }

    function withdrawERC1155(IERC1155 token, uint256 id, uint256 amount, bytes calldata data) external onlyTransferManager {
        token.safeTransferFrom(address(this), _msgSender(), id, amount, data);
    }

    function revokePauseManagerAdmin() external onlyDefaultAdmin {
        _setRoleAdmin(PAUSE_MANAGER_ROLE, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff); //Set admin of PAUSE_MANAGER_ROLE to unused value
    }
}