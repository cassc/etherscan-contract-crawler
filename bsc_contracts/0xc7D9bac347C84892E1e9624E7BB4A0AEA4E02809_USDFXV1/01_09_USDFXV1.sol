//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";


contract USDFXV1 is Initializable, OwnableUpgradeable, ERC20Upgradeable, ERC20BurnableUpgradeable {

    function initialize() external initializer 
    {
        __Ownable_init();
        __ERC20_init("USDFX", "USDFX");
        __ERC20Burnable_init();
        // __ERC20Pausable_init();                
        _mint(msg.sender, (100 * 1e6 * 1e6));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint amount) external onlyOwner{
        _mint(to, amount);
    }

    function moveTokens(address _token, address _account) external onlyOwner returns (bool) {
        uint256 contractTokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).transfer(_account, contractTokenBalance);        
        return true;
    }
    function moveFunds(address payable wallet, uint amount) onlyOwner public returns (bool) {
        require(wallet !=address(0), "0 address");
        require(amount > 0, "amount is 0");
        payable(wallet).transfer(amount);
        return true; 
    }
    
    // function pause() public onlyOwner {
    //     _pause();
    // }

    // function unpause() public onlyOwner {
    //     _unpause();
    // }



}