pragma solidity 0.4.24;

import "contracts/lib/SafeERC20.sol";
import "contracts/lib/IsContract.sol";
import "contracts/lib/IVaultRecoverable.sol";
import "contracts/lib/EtherTokenConstant.sol";

contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT =
        "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED =
        "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(
                token.safeTransfer(vault, balance),
                ERROR_TOKEN_TRANSFER_FAILED
            );
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
     * @dev By default deriving from AragonApp makes it recoverable
     * @param token Token address that would be recovered
     * @return bool whether the app allows the recovery
     */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}