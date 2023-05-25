pragma solidity 0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";


contract CustomToken is ERC20, ERC20Detailed, ERC20Capped, ERC20Burnable {
    constructor(
            string memory _name,
            string memory _symbol,
            uint8 _decimals,
            uint256 _maxSupply
        )
        ERC20Burnable()
        ERC20Capped(_maxSupply)
        ERC20Detailed(_name, _symbol, _decimals)
        ERC20()
        public {
            
        }
}