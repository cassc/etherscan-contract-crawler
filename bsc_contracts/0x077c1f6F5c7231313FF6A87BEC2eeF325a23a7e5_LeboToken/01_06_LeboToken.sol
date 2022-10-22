// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/// [Max Supply]             : 250.000.000 Token.
/// -----------------------------------------------------------------------------------------------------------
/// [Liquidity & Incentives] : 23%
/// [Foundation reserve]     : 21.2%
/// [Team & Advisors]        : 17.4% ➔ Unlock 1.45% more every 3 months.
/// [Marketing]              : 10%
/// -----------------------------------------------------------------------------------------------------------
/// [Token Sale]             : 28.4%
/// -----------------------------------------------------------------------------------------------------------
contract LeboToken is ERC20, Ownable {
    uint256 internal cap_ = 250000000e18;
    address internal treasury_;

    event TreasuryContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    constructor() ERC20("Lebo Finance", "LEBO") {}

    /**
     * Max supply: 250.000.000
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(_msgSender() != address(0), "BEP20: mint to the zero address");
        require((totalSupply() + amount) <= cap_, "Cannot mint more than cap");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function maxSupply() public view returns (uint256) {
        return cap_;
    }

    function treasury() public view returns (address) {
        return treasury_;
    }

    function setTreasury(address _treasury) public onlyOwner {
        emit TreasuryContractChanged(treasury_, _treasury);
        treasury_ = _treasury;
    }
}