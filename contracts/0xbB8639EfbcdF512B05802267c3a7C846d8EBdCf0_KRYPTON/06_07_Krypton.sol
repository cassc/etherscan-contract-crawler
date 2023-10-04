// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


import "./ERC20BaseToken.sol";


contract KRYPTON is ERC20BaseToken {

    constructor(address executionAdmin, address beneficiary) {
        _admin = msg.sender;
        _executionAdmin = executionAdmin;
        _mint(beneficiary, 10000000000 * 10**9);
    }

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public pure returns (string memory) {
        return "Krypton";
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public pure returns (string memory) {
        return "KRYPTON";
    }

    function burn(address account, uint256 amount) external {
        require(
            msg.sender == getAdmin(),
            "only admin");
        _burn(account, amount);
    }

    function setTrading()external {
        require(
            msg.sender == getAdmin(),
            "only admin");
        tradingEnabled = !tradingEnabled;
    }

}