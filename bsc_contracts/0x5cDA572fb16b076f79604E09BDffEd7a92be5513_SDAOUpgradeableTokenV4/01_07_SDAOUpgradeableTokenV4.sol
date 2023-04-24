// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SDAOUpgradeableTokenV4 is Initializable, OwnableUpgradeable, ERC20Upgradeable {
    
    bool v2upgrade;
    bool v3upgrade;

    function initialize(string memory name, string memory symbol, uint256 initialSupply) public virtual initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _mint(_msgSender(), initialSupply);
    }

    function burn(uint256 amount) public onlyOwner {

     	require (amount > 0,"Invalid amount");
        _burn(_msgSender(), amount);
        
    }

    function additionalMint(uint256 newSupply) public onlyOwner {

     	require (!v3upgrade,"already upgraded");
        _mint(_msgSender(), newSupply);
        v3upgrade = true;
    }

}