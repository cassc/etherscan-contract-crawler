/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */
pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/apps-token-manager/contracts/TokenManager.sol";
import "@aragon/apps-vault/contracts/Vault.sol";
import "../../../core/IWeeziCore.sol";
import "../../../lib/SafeMath256.sol";
import "../../../lib/SafeMath16.sol";

contract Withdrawal is AragonApp {
    using SafeMath256 for uint256;

    // keccak256("MANAGER_ROLE");
    bytes32 public constant MANAGER_ROLE =
        0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08;
    bytes32 public constant WITHDRAW_TOKEN_ROLE =
        0x998a940b522cbb96f3d240eb15dbce06a9fdc2c802f74a1f9680d0224a972c97;
    bytes32 public constant SET_WEEZICORE_ROLE =
        0x02147177c11f57bcc5e2f18437603cef42e8c89188271f80f9cf86c1c2a5763b;
    bytes32 public constant SET_TOKEN_MANAGER_ROLE =
        0x6376e9f03a2a03710fd0134497368b6bb4d6a15f1fab7cecd6ed82366e318479;
    bytes32 public constant SET_VAULT_ROLE =
        0xfe9ef65436ff43441033ae0f232d2e2c84e3d8270693efecea236ba234fe69f7;

    string private constant ERROR_VAULT = "VAULT_NOT_A_CONTRACT";
    string private constant ERROR_WEEZI_CORE = "WEEZI_CORE_NOT_A_CONTRACT";
    string private constant ERROR_TOKEN_MANAGER =
        "TOKEN_MANAGER_NOT_A_CONTRACT";
    string private constant ERROR_VAULT_FUNDS = "VAULT_NOT_ENOUGH_FUNDS";
    string private constant ERROR_CANNOT_BURN_ZERO =
        "WITHDRAWAL_CANNOT_BURN_ZERO";
    string private constant ERROR_INSUFFICIENT_BALANCE =
        "WITHDRAWAL_INSUFFICIENT_BALANCE";

    event SetTokenManager(address tokenManager);
    event SetVault(address vault);
    event SetWeeziCore(address weeziCore);
    event WithdrawSuccess(
        address sender,
        uint256 amount,
        address token,
        uint256 targetTokenAmount,
        address targetToken,
        uint256 price,
        address serviceAddress,
        uint256 serviceFeeAmount,
        uint256 timestamp,
        bytes _signature
    );

    IWeeziCore public weeziCore;
    Vault public vault;
    TokenManager public tokenManager;

    struct WithdrawalParams {
        address _sender;
        uint256 _amount; // кол-во сжигаемых community token
        address _token; // community token
        uint256 _targetTokenAmount; // кол-во возвращаемых токенов
        address _targetToken; // токены, которые хотят получить
        uint256 _price; // цена community token в токенах, которые хотят получить
        uint256 _serviceFeeAmount; // в таргет токенах
        uint256 _timestamp;
        bytes _signature;
    }
    modifier withValidData(WithdrawalParams params) {
        // Check that signature is not expired and is valid
        //
        require(
            weeziCore.isValidSignatureDate(params._timestamp),
            "EXPIRED_PRICE_DATA"
        );

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                params._sender,
                params._amount,
                params._token,
                params._targetTokenAmount,
                params._targetToken,
                params._price,
                params._serviceFeeAmount,
                params._timestamp
            )
        );

        require(
            weeziCore.isValidSignature(dataHash, params._signature),
            "INVALID_SIGNATURE"
        );
        _;
    }

    function initialize(
        Vault _vault,
        TokenManager _tokenManager,
        IWeeziCore _weeziCore
    ) external onlyInit {
        require(isContract(_vault), ERROR_VAULT);
        require(isContract(_weeziCore), ERROR_WEEZI_CORE);
        require(isContract(_tokenManager), ERROR_TOKEN_MANAGER);
        vault = _vault;
        weeziCore = _weeziCore;
        tokenManager = _tokenManager;
        initialized();
    }

    /**
     * @notice Set the Token Manager to `_tokenManager`.
     * @param _tokenManager The new token manager address
     */
    function setTokenManager(address _tokenManager)
        external
        auth(SET_TOKEN_MANAGER_ROLE)
    {
        require(isContract(_tokenManager), ERROR_TOKEN_MANAGER);

        tokenManager = TokenManager(_tokenManager);
        emit SetTokenManager(_tokenManager);
    }

    /**
     * @notice Set the Vault to `_vault`.
     * @param _vault The new vault address
     */
    function setVault(address _vault) external auth(SET_VAULT_ROLE) {
        vault = Vault(_vault);
        emit SetVault(_vault);
    }

    /**
     * @notice Set the WeeziCore to `_weeziCore`.
     * @param _weeziCore The new weeziCore address
     */
    function setWeeziCore(address _weeziCore)
        external
        auth(SET_WEEZICORE_ROLE)
    {
        require(isContract(_weeziCore), ERROR_WEEZI_CORE);

        weeziCore = IWeeziCore(_weeziCore);
        emit SetWeeziCore(_weeziCore);
    }

    function withdrawal(WithdrawalParams params)
        public
        withValidData(params)
        auth(WITHDRAW_TOKEN_ROLE)
        isInitialized
        nonReentrant
    {
        require(params._amount > 0, ERROR_CANNOT_BURN_ZERO);

        require(
            vault.balance(params._targetToken) >=
                params._targetTokenAmount.add(params._serviceFeeAmount),
            ERROR_VAULT_FUNDS
        );

        vault.transfer(
            params._targetToken,
            /*msg.sender*/
            params._sender,
            params._targetTokenAmount
        );

        address feeWalletAddress = weeziCore.getFeeWalletAddress();
        if (feeWalletAddress != address(0)) {
            vault.transfer(
                params._targetToken,
                feeWalletAddress,
                params._serviceFeeAmount
            );
        }
        tokenManager.burn(
            /*msg.sender*/
            params._sender,
            params._amount
        );

        emit WithdrawSuccess(
            params._sender,
            params._amount,
            params._token,
            params._targetTokenAmount,
            params._targetToken,
            params._price,
            feeWalletAddress,
            params._serviceFeeAmount,
            params._timestamp,
            params._signature
        );
    }
}