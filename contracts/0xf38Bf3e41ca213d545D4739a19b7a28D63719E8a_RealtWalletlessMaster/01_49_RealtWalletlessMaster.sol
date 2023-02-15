// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IBridgeToken.sol";
import "./interfaces/IRealtWalletlessMaster.sol";
import "./PermissionManager.sol";
import "./AbstractGnosisSafeProxyFactory.sol";
import "./GnosisSafeOwner.sol";
import "./WalletList.sol";
import "./RequestClient.sol";
import "./MTPClient.sol";
import "./ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact [email protected]
contract RealtWalletlessMaster is
    IRealtWalletlessMaster,
    Initializable,
    UUPSUpgradeable,
    PermissionManager,
    GnosisSafeOwner,
    AbstractGnosisSafeProxyFactory,
    WalletList,
    RequestClient,
    MTPClient,
    ReentrancyGuardUpgradeable
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint8 private constant VERSION = 2;
    uint256 private _nonce;

    function initialize(
        address[] memory mtpWallets_,
        address[] memory tokenWhitelist_,
        address[] memory destinationWhitelist_,
        address[] memory feeAddressWhitelist_,
        address feeProxy_
    ) external reinitializer(VERSION) {
        __RequestClient_init(
            tokenWhitelist_,
            destinationWhitelist_,
            feeAddressWhitelist_,
            feeProxy_
        );
        __MTPClient_init(mtpWallets_);
        __ReentrancyGuard_init();
    }

    // ----------- SAFE CREATION ------------

    function _checkAndDeploy(uint256 salt) private returns (address) {
        address futureSafeAddress = computeAddress(salt);
        bool isDeployed = _walletSalt.contains(futureSafeAddress);
        require(!isDeployed, "RWM03");
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
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, _to, _value);
        execTransactionWrapper(target, token, data);
    }

    function buyBack(
        GnosisSafeL2 clientWallet,
        IBridgeToken token,
        uint256 amount
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        require(!_isIn(address(token), _tokenWhitelist), "RWM05");
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
        uint256 size = tokens.length;
        require(size == amounts.length, "RWM06");
        for (uint256 index = 0; index < size; index++) {
            require(!_isIn(address(tokens[index]), _tokenWhitelist), "RWM05");
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

    function fiatWithdraw(
        GnosisSafeL2 clientWallet,
        address token,
        address mtpWallet,
        uint256 amount
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        require(_isIn(token, _tokenWhitelist), "RWM05");
        require(_isIn(mtpWallet, _mtpWallets), "RWM11");
        _transferWrapper(clientWallet, token, mtpWallet, amount);
        emit FiatWithdraw(clientWallet, token, mtpWallet, amount);
        return true;
    }

    function satoshiCheck(
        GnosisSafeL2 clientWallet
    ) external payable override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        require(msg.value > 999 && msg.value < 10000, "RWM16");
        (bool sent,) = payable(clientWallet).call{value: msg.value}("");
        require(sent, "RWM13");
        _execTransaction(clientWallet, msg.sender, msg.value, new bytes(0), Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), _contractSignature);
        emit SatoshiCheck(clientWallet, msg.value);
        return true;
    }

    function buyTokens(
        GnosisSafeL2 clientWallet,
        address feeProxy_,
        address to,
        uint256 amount,
        address[] memory path,
        bytes memory paymentReference,
        uint256 feeAmount,
        address feeAddress,
        uint256 maxToSpend,
        uint256 maxRateTimespan
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused returns (bool) {
        require(path.length > 0, "RWM15");
        address token = path[path.length - 1];
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        require(_isIn(token, _tokenWhitelist), "RWM05");
        require(_isIn(to, _destinationWhitelist), "RWM12");
        require(_isIn(feeAddress, _feeAddressWhitelist), "RWM14");
        require(feeProxy_ == _feeProxy, "RWM10");
        uint256 allowance = IERC20(token).allowance(
            address(clientWallet),
            _feeProxy
        );
        if (allowance < maxToSpend) {
            bytes memory approveData = abi.encodeWithSelector(
                IERC20.approve.selector,
                feeProxy_,
                maxToSpend
            );
            execTransactionWrapper(clientWallet, token, approveData);
        }
        bytes memory transferData = abi.encodeWithSelector(
            IERC20ConversionProxy.transferFromWithReferenceAndFee.selector,
            to,
            amount,
            path,
            paymentReference,
            feeAmount,
            feeAddress,
            maxToSpend,
            maxRateTimespan
        );
        execTransactionWrapper(clientWallet, _feeProxy, transferData);
        emit TokenBought(clientWallet, paymentReference);
        return true;
    }

    function ownershipCustodyExit(GnosisSafeL2 clientWallet, address newOwner)
        external
        onlyRole(MODERATOR_ROLE)
        whenNotPaused
        returns (bool)
    {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        _swapOwner(address(clientWallet), address(this), newOwner);
        emit OwnershipCustodyExit(clientWallet, newOwner);
        return true;
    }

    function fundsCustodyExit(
        GnosisSafeL2 clientWallet,
        address destination,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external onlyRole(MODERATOR_ROLE) whenNotPaused returns (bool) {
        require(_walletSalt.contains(address(clientWallet)), "RWM02");
        uint256 size = tokens.length;
        require(size == amounts.length, "RWM06");
        for (uint256 index = 0; index < size; index++) {
            _transferWrapper(
                clientWallet,
                tokens[index],
                destination,
                amounts[index]
            );
        }
        emit FundsCustodyExit(clientWallet, destination, tokens, amounts);
        return true;
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

    function _authorizeRequestClient() internal override moderatorOrAdmin {}

    function _authorizeMTPClient() internal override moderatorOrAdmin {}

    function _swapOwner(address wallet, address oldOwner, address newOwner) internal override {
        bytes memory data = abi.encodeWithSelector(
            OwnerManager.swapOwner.selector,
            address(0x1),
            oldOwner,
            newOwner
        );
        execTransactionWrapper(GnosisSafeL2(payable(wallet)), wallet, data);
    }

    function _isIn(address item, address[] memory array)
        private
        pure
        returns (bool)
    {
        uint256 size = array.length;
        if (size == 0) return true;
        for (uint256 index = 0; index < size; index++) {
            if (array[index] == item) return true;
        }
        return false;
    }

    /// @return nonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function nonce() external view returns (uint256) {
        return _nonce;
    }
}