// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Tracks amounts deposited and or withdrawn, on a per contract:token basis.  Does not allow an account to
 * withdraw more than it has deposited, and provides balance functions inspired by ERC1155.
 */
abstract contract BalanceTrackingMixin {
    struct DepositBalance {
        // balance of deposits, contract address => (token id => balance)
        mapping(address => mapping(uint256 => uint256)) balances;
    }

    mapping(address => DepositBalance) private accountBalances;

    function _depositIntoAccount(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 newBalance = accountBalances[account].balances[contractAddress][tokenId] + amount;
        accountBalances[account].balances[contractAddress][tokenId] = newBalance;
    }

    function _depositIntoAccount(
        address account,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        require(tokenIds.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            _depositIntoAccount(account, contractAddress, tokenIds[i], amounts[i]);
        }
    }

    function _withdrawFromAccount(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(accountBalances[account].balances[contractAddress][tokenId] >= amount, "Insufficient balance");
        uint256 newBalance = accountBalances[account].balances[contractAddress][tokenId] - amount;
        accountBalances[account].balances[contractAddress][tokenId] = newBalance;
    }

    function _withdrawFromAccount(
        address account,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        require(tokenIds.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            _withdrawFromAccount(account, contractAddress, tokenIds[i], amounts[i]);
        }
    }

    function balanceOf(
        address account,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256 balance) {
        require(account != address(0), "Zero address");
        return accountBalances[account].balances[contractAddress][tokenId];
    }

    function balanceOfBatch(
        address account,
        address[] memory contractAddresses,
        uint256[] memory tokenIds
    ) public view returns (uint256[] memory batchBalances) {
        require(contractAddresses.length == tokenIds.length, "Length mismatch");

        batchBalances = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchBalances[i] = balanceOf(account, contractAddresses[i], tokenIds[i]);
        }
    }
}