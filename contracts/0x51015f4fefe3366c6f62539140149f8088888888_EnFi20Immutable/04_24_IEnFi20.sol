// SPDX-License-Identifier: UNLICENSED
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.20;
import "IERC20Base.sol";
import "IERC20Metadata.sol";
import "draft-IERC20Permit.sol";

//import "IRole.sol";

interface IEnFi20 is IERC20Base, IERC20Metadata, IERC20Permit {
    // Events
    event WhiteListWallet(address _wallet, bool _status);
}