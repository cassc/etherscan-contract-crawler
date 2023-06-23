pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import './owner/Operator.sol';

contract KBTC is ERC20Burnable, Operator {
    /**
     * @notice Constructs the KBTC ERC-20 contract.
     */
    constructor() public ERC20('KBTC', 'KBTC') {
        _mint(msg.sender, 10**12); // 100 sat for uniswap pair
    }

    /**
     * @notice Operator mints KBTC to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of KBTC to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}