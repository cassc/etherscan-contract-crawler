/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../interfaces/external/IWETH.sol';
import '../interfaces/IHashflowPool.sol';
import '../interfaces/IHashflowRouter.sol';

interface IERC20AllowanceExtension {
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
}

contract HashflowPool is IHashflowPool, Initializable, Context {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    string public name;

    SignerConfiguration public signerConfiguration;
    address public operations;

    address public router;

    mapping(address => uint256) public nonces;
    mapping(bytes32 => uint256) public xChainNonces;

    mapping(address => bool) internal _withrawalAccountAuth;
    mapping(bytes32 => bool) internal _filledXChainTxids;

    address public immutable _WETH;

    constructor(address weth) {
        require(
            weth != address(0),
            'HashflowPool::constructor WETH cannot be 0 address.'
        );
        _WETH = weth;
    }

    /// @dev Fallback function to receive native token.
    receive() external payable {}

    /// @inheritdoc IHashflowPool
    function initialize(
        string memory _name,
        address _signer,
        address _operations,
        address _router
    ) public override initializer {
        require(
            _signer != address(0),
            'HashflowPool::initialize Signer cannot be 0 address.'
        );
        require(
            _operations != address(0),
            'HashflowPool::initialize Operations cannot be 0 address.'
        );
        require(
            _router != address(0),
            'HashflowPool::initialize Router cannot be 0 address.'
        );
        require(
            bytes(_name).length > 0,
            'HashflowPool::initialize Name cannot be empty'
        );

        name = _name;

        SignerConfiguration memory signerConfig;
        signerConfig.enabled = true;
        signerConfig.signer = _signer;

        emit UpdateSigner(_signer, address(0));

        signerConfiguration = signerConfig;

        operations = _operations;
        router = _router;
    }

    modifier authorizedOperations() {
        require(
            _msgSender() == operations,
            'HashflowPool:authorizedOperations Sender must be operator.'
        );
        _;
    }

    modifier authorizedRouter() {
        require(
            _msgSender() == router,
            'HashflowPool::authorizedRouter Sender must be Router.'
        );
        _;
    }

    /// @inheritdoc IHashflowPool
    function tradeRFQT(RFQTQuote memory quote)
        external
        payable
        override
        authorizedRouter
    {
        /// Trust assumption: the Router has transferred baseToken.
        require(
            quote.baseToken != address(0) ||
                quote.externalAccount != address(0) ||
                msg.value == quote.effectiveBaseTokenAmount,
            'HashflowPool::tradeRFQT msg.value must equal effectiveBaseTokenAmount'
        );
        bytes32 quoteHash = _hashQuoteRFQT(quote);

        SignerConfiguration memory signerConfig = signerConfiguration;
        require(signerConfig.enabled, 'HashflowPool::tradeRFQT Disabled.');

        require(
            quoteHash.recover(quote.signature) == signerConfig.signer,
            'HashflowPool::tradeRFQT Invalid signer.'
        );
        _updateNonce(quote.effectiveTrader, quote.nonce);

        uint256 quoteTokenAmount = quote.quoteTokenAmount;
        if (quote.effectiveBaseTokenAmount < quote.baseTokenAmount) {
            quoteTokenAmount =
                (quote.effectiveBaseTokenAmount * quote.quoteTokenAmount) /
                quote.baseTokenAmount;
        }

        emit Trade(
            quote.trader,
            quote.effectiveTrader,
            quote.txid,
            quote.baseToken,
            quote.quoteToken,
            quote.effectiveBaseTokenAmount,
            quoteTokenAmount
        );

        if (quote.externalAccount == address(0)) {
            _transferFromPool(quote.quoteToken, quote.trader, quoteTokenAmount);
        } else {
            _transferFromExternalAccount(
                quote.externalAccount,
                quote.quoteToken,
                quote.trader,
                quoteTokenAmount
            );
        }
    }

    /// @inheritdoc IHashflowPool
    function tradeRFQM(RFQMQuote memory quote)
        external
        override
        authorizedRouter
    {
        SignerConfiguration memory signerConfig = signerConfiguration;
        require(signerConfig.enabled, 'HashflowPool::tradeRFQM Disabled.');

        bytes32 quoteHash = _hashQuoteRFQM(quote);
        require(
            quoteHash.recover(quote.makerSignature) == signerConfig.signer,
            'HashflowPool::tradeRFQM Invalid signer.'
        );

        emit Trade(
            quote.trader,
            quote.trader,
            quote.txid,
            quote.baseToken,
            quote.quoteToken,
            quote.baseTokenAmount,
            quote.quoteTokenAmount
        );

        if (quote.externalAccount == address(0)) {
            _transferFromPool(
                quote.quoteToken,
                quote.trader,
                quote.quoteTokenAmount
            );
        } else {
            _transferFromExternalAccount(
                quote.externalAccount,
                quote.quoteToken,
                quote.trader,
                quote.quoteTokenAmount
            );
        }
    }

    /// @inheritdoc IHashflowPool
    function tradeXChainRFQT(XChainRFQTQuote memory quote, address trader)
        external
        payable
        override
        authorizedRouter
    {
        require(
            quote.srcExternalAccount != address(0) ||
                quote.baseToken != address(0) ||
                msg.value == quote.effectiveBaseTokenAmount,
            'HashflowPool::tradeXChainRFQT msg.value must = amount'
        );

        SignerConfiguration memory signerConfig = signerConfiguration;
        require(
            signerConfig.enabled,
            'HashflowPool::tradeXChainRFQT Disabled.'
        );

        _updateNonceXChain(quote.dstTrader, quote.nonce);
        bytes32 quoteHash = _hashXChainQuoteRFQT(quote);
        require(
            quoteHash.recover(quote.signature) == signerConfig.signer,
            'HashflowPool::tradeXChainRFQT Invalid signer'
        );

        uint256 effectiveQuoteTokenAmount = quote.quoteTokenAmount;
        if (quote.effectiveBaseTokenAmount < quote.baseTokenAmount) {
            effectiveQuoteTokenAmount =
                (quote.quoteTokenAmount * quote.effectiveBaseTokenAmount) /
                quote.baseTokenAmount;
        }

        emit XChainTrade(
            quote.dstChainId,
            quote.dstPool,
            trader,
            quote.dstTrader,
            quote.txid,
            quote.baseToken,
            quote.quoteToken,
            quote.effectiveBaseTokenAmount,
            effectiveQuoteTokenAmount
        );
    }

    /// @inheritdoc IHashflowPool
    function fillXChain(
        address externalAccount,
        bytes32 txid,
        address trader,
        address quoteToken,
        uint256 quoteTokenAmount
    ) external override authorizedRouter {
        require(
            !_filledXChainTxids[txid],
            'HashflowPool::fillXChain Quote has been executed previously.'
        );
        _filledXChainTxids[txid] = true;

        emit XChainTradeFill(txid);

        if (externalAccount == address(0)) {
            _transferFromPool(quoteToken, trader, quoteTokenAmount);
        } else {
            _transferFromExternalAccount(
                externalAccount,
                quoteToken,
                trader,
                quoteTokenAmount
            );
        }
    }

    /// @inheritdoc IHashflowPool
    function tradeXChainRFQM(XChainRFQMQuote memory quote)
        external
        override
        authorizedRouter
    {
        SignerConfiguration memory signerConfig = signerConfiguration;
        require(
            signerConfig.enabled,
            'HashflowPool::tradeXChainRFQM Disabled.'
        );

        bytes32 quoteHash = _hashXChainQuoteRFQM(quote);
        require(
            quoteHash.recover(quote.makerSignature) == signerConfig.signer,
            'HashflowPool::tradeXChainRFQM Invalid signer'
        );
        emit XChainTrade(
            quote.dstChainId,
            quote.dstPool,
            quote.trader,
            quote.dstTrader,
            quote.txid,
            quote.baseToken,
            quote.quoteToken,
            quote.baseTokenAmount,
            quote.quoteTokenAmount
        );
    }

    /// @inheritdoc IHashflowPool
    function updateXChainPoolAuthorization(
        AuthorizedXChainPool[] calldata pools,
        bool status
    ) external override authorizedOperations {
        for (uint256 i = 0; i < pools.length; i++) {
            require(pools[i].pool != bytes32(0));
            IHashflowRouter(router).updateXChainPoolAuthorization(
                pools[i].chainId,
                pools[i].pool,
                status
            );
        }
    }

    /// @inheritdoc IHashflowPool
    function updateXChainMessengerAuthorization(
        address xChainMessenger,
        bool authorized
    ) external override authorizedOperations {
        require(
            xChainMessenger != address(0),
            'HashflowPool::updateXChainMessengerAuthorization Invalid messenger address.'
        );
        IHashflowRouter(router).updateXChainMessengerAuthorization(
            xChainMessenger,
            authorized
        );
    }

    /// @dev ERC1271 implementation.
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        if (hash.recover(signature) == signerConfiguration.signer) {
            magicValue = 0x1626ba7e;
        }
    }

    /// @inheritdoc IHashflowPool
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external override authorizedOperations {
        IERC20(token).forceApprove(spender, amount);
    }

    /// @inheritdoc IHashflowPool
    function increaseTokenAllowance(
        address token,
        address spender,
        uint256 amount
    ) external override authorizedOperations {
        IERC20(token).safeIncreaseAllowance(spender, amount);
    }

    /// @inheritdoc IHashflowPool
    function decreaseTokenAllowance(
        address token,
        address spender,
        uint256 amount
    ) external override authorizedOperations {
        IERC20(token).safeDecreaseAllowance(spender, amount);
    }

    /// @inheritdoc IHashflowPool
    function removeLiquidity(
        address token,
        address recipient,
        uint256 amount
    ) external override authorizedOperations {
        SignerConfiguration memory signerConfig = signerConfiguration;
        require(
            signerConfig.enabled,
            'HashflowPool::removeLiquidity Disabled.'
        );

        require(amount > 0, 'HashflowPool::removeLiquidity Invalid amount');
        address _recipient;
        if (recipient != address(0)) {
            require(
                _withrawalAccountAuth[recipient],
                'HashflowPool::removeLiquidity Recipient must be hedging account'
            );

            _recipient = recipient;
        } else {
            _recipient = _msgSender();
        }

        emit RemoveLiquidity(token, _recipient, amount);

        _transferFromPool(token, _recipient, amount);
    }

    /// @inheritdoc IHashflowPool
    function updateWithdrawalAccount(
        address[] memory withdrawalAccounts,
        bool authorized
    ) external override authorizedOperations {
        for (uint256 i = 0; i < withdrawalAccounts.length; i++) {
            require(withdrawalAccounts[i] != address(0));
            _withrawalAccountAuth[withdrawalAccounts[i]] = authorized;
            emit UpdateWithdrawalAccount(withdrawalAccounts[i], authorized);
        }
    }

    /// @inheritdoc IHashflowPool
    function updateSigner(address newSigner)
        external
        override
        authorizedOperations
    {
        require(newSigner != address(0));

        SignerConfiguration memory signerConfig = signerConfiguration;

        emit UpdateSigner(newSigner, signerConfig.signer);

        signerConfig.signer = newSigner;
        signerConfiguration = signerConfig;
    }

    /// @inheritdoc IHashflowPool
    function killswitchOperations(bool enabled)
        external
        override
        authorizedRouter
    {
        SignerConfiguration memory signerConfig = signerConfiguration;

        signerConfig.enabled = enabled;

        signerConfiguration = signerConfig;
    }

    function getReserves(address token)
        external
        view
        override
        returns (uint256)
    {
        return _getReserves(token);
    }

    /**
     * @dev Prevents against replay for RFQ-T. Checks that nonces are strictly increasing.
     */
    function _updateNonce(address trader, uint256 nonce) internal {
        require(
            nonce > nonces[trader],
            'HashflowPool::_updateNonce Invalid nonce.'
        );
        nonces[trader] = nonce;
    }

    /**
     * @dev Prevents against replay for X-Chain RFQ-T. Checks that nonces are strictly increasing.
     */
    function _updateNonceXChain(bytes32 trader, uint256 nonce) internal {
        require(
            nonce > xChainNonces[trader],
            'HashflowPool::_updateNonceXChain Invalid nonce.'
        );
        xChainNonces[trader] = nonce;
    }

    function _transferFromPool(
        address token,
        address recipient,
        uint256 value
    ) internal {
        if (token == address(0)) {
            payable(recipient).sendValue(value);
        } else {
            IERC20(token).safeTransfer(recipient, value);
        }
    }

    /// @dev Helper function to transfer quoteToken from external account.
    function _transferFromExternalAccount(
        address externalAccount,
        address token,
        address receiver,
        uint256 value
    ) private {
        if (token == address(0)) {
            IERC20(_WETH).safeTransferFrom(
                externalAccount,
                address(this),
                value
            );

            IWETH(_WETH).withdraw(value);
            payable(receiver).sendValue(value);
        } else {
            IERC20(token).safeTransferFrom(externalAccount, receiver, value);
        }
    }

    function _getReserves(address token) internal view returns (uint256) {
        return
            token == address(0)
                ? address(this).balance
                : IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Generates a quote hash for RFQ-t.
     */
    function _hashQuoteRFQT(RFQTQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    keccak256(
                        abi.encodePacked(
                            address(this),
                            quote.trader,
                            quote.effectiveTrader,
                            quote.externalAccount,
                            quote.baseToken,
                            quote.quoteToken,
                            quote.baseTokenAmount,
                            quote.quoteTokenAmount,
                            quote.nonce,
                            quote.quoteExpiry,
                            quote.txid,
                            block.chainid
                        )
                    )
                )
            );
    }

    function _hashQuoteRFQM(RFQMQuote memory quote)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    keccak256(
                        abi.encodePacked(
                            quote.pool,
                            quote.externalAccount,
                            quote.trader,
                            quote.baseToken,
                            quote.quoteToken,
                            quote.baseTokenAmount,
                            quote.quoteTokenAmount,
                            quote.quoteExpiry,
                            quote.txid,
                            block.chainid
                        )
                    )
                )
            );
    }

    function _hashXChainQuoteRFQT(XChainRFQTQuote memory quote)
        private
        pure
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        quote.srcChainId,
                        quote.dstChainId,
                        quote.srcPool,
                        quote.dstPool,
                        quote.srcExternalAccount,
                        quote.dstExternalAccount
                    )
                ),
                quote.dstTrader,
                quote.baseToken,
                quote.quoteToken,
                quote.baseTokenAmount,
                quote.quoteTokenAmount,
                quote.quoteExpiry,
                quote.nonce,
                quote.txid,
                quote.xChainMessenger
            )
        );
        return
            keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n32', digest)
            );
    }

    function _hashXChainQuoteRFQM(XChainRFQMQuote memory quote)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    keccak256(
                        abi.encodePacked(
                            keccak256(
                                abi.encodePacked(
                                    quote.srcChainId,
                                    quote.dstChainId,
                                    quote.srcPool,
                                    quote.dstPool,
                                    quote.srcExternalAccount,
                                    quote.dstExternalAccount
                                )
                            ),
                            quote.trader,
                            quote.baseToken,
                            quote.quoteToken,
                            quote.baseTokenAmount,
                            quote.quoteTokenAmount,
                            quote.quoteExpiry,
                            quote.txid,
                            quote.xChainMessenger
                        )
                    )
                )
            );
    }
}