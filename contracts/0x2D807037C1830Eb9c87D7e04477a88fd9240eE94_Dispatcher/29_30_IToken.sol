// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IService.sol";

interface IToken is IERC20Upgradeable {
    struct TokenInfo {
        string symbol;
        uint256 cap;
    }

    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        address pool_, 
        string memory symbol_, 
        uint256 cap_, 
        TokenType tokenType_, 
        address primaryTGE_, 
        string memory description_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function lock(
        address account,
        uint256 amount,
        uint256 deadline,
        uint256 proposalId
    ) external;

    function cap() external view returns (uint256);

    function minUnlockedBalanceOf(address from) external view returns (uint256);

    function unlockedBalanceOf(address account, uint256 proposalId)
        external
        view
        returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge_) external;

    function getTotalTGEVestedTokens() external view returns (uint256);
}