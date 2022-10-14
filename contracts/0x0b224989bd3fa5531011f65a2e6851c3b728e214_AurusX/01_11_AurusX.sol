// contracts/AurusX.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract AurusX is ERC20PausableUpgradeable, OwnableUpgradeable {

    event ForceTransfer(address indexed from, address indexed to, uint256 value, bytes32 details);

    function initialize(string memory name_, string memory symbol_, uint256 totalSupply_) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init_unchained();
        _mint(msg.sender, totalSupply_);                
    }    

    /*
     * Pause transfers
     */
    function pauseTransfers() external onlyOwner {
        _pause();
    }    

    /*
     * Resume transfers
     */
    function resumeTransfers() external onlyOwner {
        _unpause();
    }

    /*
     * Force transfer callable by owner (governance).
     */ 
    function forceTransfer(address sender_, address recipient_, uint256 amount_, bytes32 details_) external onlyOwner {
        _burn(sender_,amount_);
        _mint(recipient_,amount_);
        emit ForceTransfer(sender_, recipient_, amount_, details_);
    }    
}