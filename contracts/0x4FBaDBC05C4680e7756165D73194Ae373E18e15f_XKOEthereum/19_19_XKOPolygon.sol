// SPDX-License-Identifier: MIT
//    _/      _/  _/    _/    _/_/
//     _/  _/    _/  _/    _/    _/
//      _/      _/_/      _/    _/
//   _/  _/    _/  _/    _/    _/
//_/      _/  _/    _/    _/_/
pragma solidity ^0.8.17;

import "./XKO.sol";

/**
  * @dev Ethereum <> Polygon bridge requirement
  */
interface IChildToken {
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external;

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external;
}

/// @custom:security-contact [email protected]
contract XKOPolygon is XKO, IChildToken {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    address public chainManager;

    constructor(string memory name, string memory symbol) XKO(name, symbol) {}

    function setChainManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(hasRole(DEPOSITOR_ROLE, chainManager)){
            _revokeRole(DEPOSITOR_ROLE, chainManager);
        }
        chainManager = manager;
        _grantRole(DEPOSITOR_ROLE, chainManager);
    }

    /**
     * @dev See {IChildToken-deposit}.
     */
    function deposit(address user, bytes calldata depositData) external override onlyRole(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @dev See {IChildToken-withdraw}.
     */
    function withdraw(uint256 amount) external override {
        require(hasRole(DEPOSITOR_ROLE, chainManager), "Chain manager not declared by admin");
        _burn(_msgSender(), amount);
    }
}