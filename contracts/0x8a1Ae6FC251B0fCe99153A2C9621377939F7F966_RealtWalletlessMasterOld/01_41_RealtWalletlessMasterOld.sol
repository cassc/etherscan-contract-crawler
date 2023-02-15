// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBridgeToken.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IRealtWalletlessMaster.sol";
import "./PermissionManager.sol";
import "./AbstractGnosisSafeProxyFactory.sol";
import "./GnosisSafeOwner.sol";
import "./WalletList.sol";

/// @custom:security-contact [email protected]
contract RealtWalletlessMasterOld is
    IRealtWalletlessMaster,
    Initializable,
    UUPSUpgradeable,
    PermissionManager,
    GnosisSafeOwner,
    AbstractGnosisSafeProxyFactory,
    WalletList
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint256 private _nonce;

    function initialize(
        address singleton_,
        address admin_,
        address moderator_,
        address operator_
    ) external initializer {
        __UUPSUpgradeable_init();
        __PermissionManager_init(admin_, moderator_, operator_);
        __GnosisSafeOwner_init(singleton_);
    }

    // ----------- SAFE CREATION ------------

    function _checkAndDeploy(uint256 salt) private returns (address) {
        address futureSafeAddress = computeAddress(salt);
        (bool success, ) = _walletSalt.tryGet(futureSafeAddress);
        require(!success, "RWM03");
        address proxy = address(createProxyWithNonce(_singleton, _setup, salt));
        _walletSalt.set(proxy, salt);
        if (salt >= _nonce) _nonce = salt + 1;
        return proxy;
    }

    function createSafe()
        external
        override
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
        returns (address, uint256)
    {
        address proxy = _checkAndDeploy(_nonce);
        return (proxy, _nonce - 1);
    }

    function createSafeWithSalt(uint256 salt)
        external
        override
        onlyRole(MODERATOR_ROLE)
        whenNotPaused
        returns (address, uint256)
    {
        address proxy = _checkAndDeploy(salt);
        return (proxy, salt);
    }

    // --------------------------------------

    // ----------- SAFE OPERATION -----------

    function _transferWrapper(
        GnosisSafeL2 target,
        address token,
        address _to,
        uint256 _value
    ) private {
        bytes4 selector = IBridgeToken.transfer.selector;
        bytes memory data = abi.encodeWithSelector(selector, _to, _value);
        execTransactionWrapper(target, token, data);
    }

    function buyBack(
        GnosisSafeL2 clientWallet,
        IBridgeToken token,
        uint256 amount
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        address owner = token.owner();
        _transferWrapper(clientWallet, address(token), owner, amount);
        emit BuyBack(clientWallet, token, amount);
        return true;
    }

    function batchBuyBack(
        GnosisSafeL2 clientWallet,
        IBridgeToken[] calldata tokens,
        uint256[] calldata amounts
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        require(tokens.length == amounts.length, "RWM06");
        for (uint256 index = 0; index < tokens.length; index++) {
            address owner = tokens[index].owner();
            _transferWrapper(
                clientWallet,
                address(tokens[index]),
                owner,
                amounts[index]
            );
        }
        emit BatchBuyBack(clientWallet, tokens, amounts);
        return true;
    }

    function fiatWithdraw()
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
        returns (address)
    {
        // TODO Fill that
        return address(0);
    }

    function custodyExitOwner(GnosisSafeL2 clientWallet)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
        returns (address)
    {
        // TODO Fill that
        return address(0);
    }

    function custodyExitAddress(GnosisSafeL2 clientWallet)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
        returns (address)
    {
        // TODO Fill that
        return address(0);
    }

    function addSafeOwner(GnosisSafeL2 clientWallet, address newOwner)
        external
        override
        onlyRole(MODERATOR_ROLE)
        whenNotPaused
        returns (bool)
    {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        bytes memory data = abi.encodeWithSelector(
            OwnerManager.addOwnerWithThreshold.selector,
            newOwner,
            1 //_threshold
        );
        execTransactionWrapper(clientWallet, address(clientWallet), data);
        emit AddSafeOwner(clientWallet, newOwner);
        return true;
    }

    function removeSafeOwner(
        GnosisSafeL2 clientWallet,
        address prevOwner,
        address owner
    ) external override onlyRole(MODERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        bytes memory data = abi.encodeWithSelector(
            OwnerManager.removeOwner.selector,
            prevOwner,
            owner,
            1 //_threshold
        );
        execTransactionWrapper(clientWallet, address(clientWallet), data);
        emit RemoveSafeOwner(clientWallet, prevOwner, owner);
        return true;
    }

    // Upgrade contract
    function _authorizeUpgrade(address) internal override moderatorOrAdmin {}

    function _canUpdateWalletList() internal override moderatorOrAdmin {}

    function _checkAdminRole() internal override moderatorOrAdmin {}

    /// @return nonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function nonce() external view returns (uint256) {
        return _nonce;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}