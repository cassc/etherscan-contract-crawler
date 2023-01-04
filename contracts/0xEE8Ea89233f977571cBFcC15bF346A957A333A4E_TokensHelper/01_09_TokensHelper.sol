// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IERC721Registry.sol";

contract TokensHelper {
    address public registry;

    constructor(address registryAddress) {
        require(registryAddress != address(0x0), "!registry");
        registry = registryAddress;
    }

    /**
        @dev Returns the token balances for a given account.
        @dev It can be used for ERC20 or ERC721 since both standards have the same `balanceOf(address)` function.
     */
    function getBalances(address account, address[] calldata tokens)
        external
        view
        returns (uint256[] memory balances)
    {
        uint256 length = tokens.length;
        balances = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            balances[index] = IERC20(tokens[index]).balanceOf(account);
        }
    }

    function getERC20Allowances(
        address account,
        address spender,
        address[] calldata tokens
    ) external view returns (uint256[] memory allowances) {
        uint256 length = tokens.length;
        allowances = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            allowances[index] = IERC20(tokens[index]).allowance(account, spender);
        }
    }

    function getERC1155Balances(
        address account,
        address[] calldata tokens,
        uint256 typeId
    ) external view returns (uint256[] memory balances) {
        uint256 length = tokens.length;
        balances = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            balances[index] = IERC1155(tokens[index]).balanceOf(account, typeId);
        }
    }

    function getAllBalances(address account)
        external
        view
        returns (
            string[] memory symbols,
            address[] memory tokens,
            uint256[] memory balances,
            uint256[][] memory tokenIds
        )
    {
        tokens = IERC721Registry(registry).getTokenAddresses();
        (
            symbols,
            balances,
            tokenIds
        ) = _getAllBalances(account, tokens);
    }

    function getAllBalancesBySource(address source, address account)
        external
        view
        returns (
            string[] memory symbols,
            address[] memory tokens,
            uint256[] memory balances,
            uint256[][] memory tokenIds
        )
    {
        tokens = IERC721Registry(registry).tokensBySource(source);
        (
            symbols,
            balances,
            tokenIds
        ) = _getAllBalances(account, tokens);
    }

    /** View Functions */

    /** Internal Functions */

    function _getAllBalances(address account, address[] memory tokens)
        internal
        view
        returns (
            string[] memory symbols,
            uint256[] memory balances,
            uint256[][] memory tokenIds
        )
    {
        uint256 length = tokens.length;
        symbols = new string[](length);
        tokenIds = new uint256[][](length);
        balances = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            balances[index] = IERC721(tokens[index]).balanceOf(account);
            symbols[index] = IERC721Metadata(tokens[index]).symbol();
            tokenIds[index] = IERC721AQueryableUpgradeable(tokens[index]).tokensOfOwner(account);
        }
    }

    /** Modifiers */
}