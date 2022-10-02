// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Coub is ERC20, Ownable {
    /* solhint-disable no-empty-blocks */
    constructor() ERC20("coub token", "COUB") {}

    function mintTo(address beneficiary, uint256 amount) external onlyOwner {
        _mint(beneficiary, amount);
    }
}


contract VCoub is ERC20, Ownable {
    /* solhint-disable no-empty-blocks */
    constructor() ERC20("coub reward token", "vCOUB") {}
    
    /**
    * @dev Returns the number of decimals used to get its user representation.
    */   
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mintTo(uint256[] calldata beneficiary)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            _mint(address(uint160(beneficiary[i])), (beneficiary[i]>>160));
        }
    }
}