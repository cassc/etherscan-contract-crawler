pragma solidity 0.5.9;

import "./Wonderland/erc20/ERC20ExecuteExtension.sol";
import "./Wonderland/erc20/ERC20BaseToken.sol";
import "./Wonderland/erc20/ERC20BasicApproveExtension.sol";

contract Wonderland is ERC20ExecuteExtension, ERC20BasicApproveExtension, ERC20BaseToken {
    constructor(
        address arvAdmin,
        address executionAdmin,
        address beneficiary
    ) public {
        _admin = arvAdmin;
        _executionAdmin = executionAdmin;
        _mint(beneficiary, 3000000000000000000000000000);
    }

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public view returns (string memory) {
        return "Ariva";
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public view returns (string memory) {
        return "ARV";
    }
}