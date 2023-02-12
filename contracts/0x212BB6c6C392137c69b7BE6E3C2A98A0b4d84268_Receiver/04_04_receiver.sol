// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
pragma solidity 0.8.17;

// Tyrnis needs to listen to USDC transfer filtering by the param TO

contract Receiver is Initializable {
    address public vault;
    IERC20 _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USDC in ETH 6 decimals !!!
    event Withdraw(uint amount);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _vault) initializer public {
        vault = _vault;
    }

    function withdraw() external {
        _usdc.transfer(vault, _usdc.balanceOf(address(this)));
        emit Withdraw(_usdc.balanceOf(address(this)));
    }

    function rescueERC20(address token) public {
        IERC20 _token = IERC20(token);
        require(
            _token.balanceOf(address(this)) > 0,
            "Can't withdraw null balance"
        );
        _token.transfer(vault, _token.balanceOf(address(this)));
    }
}