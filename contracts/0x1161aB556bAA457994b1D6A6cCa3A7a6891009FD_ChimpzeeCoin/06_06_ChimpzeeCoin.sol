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
     * @dev Burn tokens from owners wallet
     * @param _amount Token amount to be burned
     */
    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount * (10 ** decimals()));
    }
}