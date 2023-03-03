// SPDX-License-Identifier: MIT

/**    ______  ____  ____  _____  ____    ____  _______   ________  ________  ________  
 *   .' ___  ||_   ||   _||_   _||_   \  /   _||_   __ \ |  __   _||_   __  ||_   __  | 
 *  / .'   \_|  | |__| |    | |    |   \/   |    | |__) ||_/  / /    | |_ \_|  | |_ \_| 
 *  | |         |  __  |    | |    | |\  /| |    |  ___/    .'.' _   |  _| _   |  _| _  
 *  \ `.___.'\ _| |  | |_  _| |_  _| |_\/_| |_  _| |_     _/ /__/ | _| |__/ | _| |__/ | 
 *   `.____ .'|____||____||_____||_____||_____||_____|   |________||________||________| 
 */

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ChimpzeeCoin is ERC20, Ownable {
    mapping(address => bool) public blacklisted;

    event LogAddToBlacklist(address[] indexed blacklisted);
    event LogRemoveFromBlacklist(address[] indexed removed);

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _name Name of the token
     * @param _symbol Symbol of the token
     * @param _amount Token amount to be minted
     */
    constructor (string memory _name, string memory _symbol, uint256 _amount) ERC20(_name, _symbol) {       
        _mint(_msgSender(), _amount * (10 ** decimals()));
    }
    
    /**
     * @dev Mint new tokens to owners wallet
     * @param _amount Token amount to be minted
     */
    function mint(uint256 _amount) external onlyOwner {
        _mint(_msgSender(), _amount * (10 ** decimals()));
    }

    /**
     * @dev Burn tokens from owners wallet
     * @param _amount Token amount to be burned
     */
    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount * (10 ** decimals()));
    }

    /**
     * @dev Prevents blacklisted address to receive or send
     */
    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal view override {
        require(!blacklisted[from] && !blacklisted[to], "ERC20: blacklisted address");
    }

    /**
     * @dev Adds single or multiple address to the blacklist
     * @param _accounts Address or addresses to be blacklisted
     */
    function addToBlacklist(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklisted[_accounts[i]] = true;
        }
        emit LogAddToBlacklist(_accounts);
    }

    /**
     * @dev Removes single or multiple address from the blacklist
     * @param _accounts Address or addresses to be removed from blacklist
     */
    function removeFromBlacklist(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklisted[_accounts[i]] = false;
        }
        emit LogRemoveFromBlacklist(_accounts);
    }
}