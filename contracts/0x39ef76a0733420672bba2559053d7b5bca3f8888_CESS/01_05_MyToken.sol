// SPDX-License-Identifier: MIT
/**
 *               ______________                  
 *              / ____________ \                 
 *             /_/            \ \                
 *   _____________________     \ \       ________     ________     ________     ________   
 *  |_________  _________ \    / /      /  ____  \   /  _____/    / ______/    / ______/                
 *          / /          \ \__/ /      |  /    \_/  |  /         / /          / /                       
 *         / /__________  \____/       |  |         |  |_____    | |_____     | |_____                  
 *        |  ___________|  ____        |  |         |   _____|    \_____  \    \_____  \                
 *         \ \            / __ \       |  |     _   |  |                \  \         \  \               
 *   _______\ \__________/ /  \ \      |  \____/ \  |  \______   _______/  /  _______/  /               
 *  |_____________________/    \ \      \________/   \_______/   \________/   \________/                
 *             __              / /               
 *             \ \____________/ /                
 *              \______________/   
 * +--------------------------------------------------------------------------------------+
 * |                          CUMULUS ENCRYPTED STORAGE SYSTEM                            |
 * +--------------------------------------------------------------------------------------+
 *
 *  Cumulus Encrypted Storage System (CESS) is the first full-stack decentralized storage solution for 
 *  large-scale enterprise needs. CESS is a decentralized cloud storage network optimized for processing 
 *  high-frequency dynamic data while safeguarding users' data ownership, privacy, and asset protection.
 *
 *  For more information about CESS, visit: https://cess.cloud/
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CESS is ERC20 {
    address constant public FOUNDATION = 0x592C7B138A15555e552c76Ec7a19d323fB4BC53F;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("Cumulus Encrypted Storage System", "CESS") {
        uint256 _totalAmount = 10_000_000_000 * 10 ** 18; // 10 billion

        _mint(FOUNDATION, _totalAmount * 15 / 100); // 10% for community, 5% for foundation
        _mint(DEAD, _totalAmount * 25 / 100); // 25% for treasury
        _mint(DEAD, _totalAmount * 60 / 100); // 60% for mining
    }

    function burn(uint256 amount) public {
        _transfer(_msgSender(), DEAD, amount);
    }
}