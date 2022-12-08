// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarGateway } from './interfaces/IAxelarGateway.sol';
import { IAxelarAuth } from './interfaces/IAxelarAuth.sol';
import { IERC20 } from './interfaces/IERC20.sol';
import { IBurnableMintableCappedERC20 } from './interfaces/IBurnableMintableCappedERC20.sol';
import { ITokenDeployer } from './interfaces/ITokenDeployer.sol';

import { ECDSA } from './ECDSA.sol';
import { DepositHandler } from './DepositHandler.sol';
import { AdminMultisigBase } from './AdminMultisigBase.sol';

contract AxelarGateway is IAxelarGateway, AdminMultisigBase {
    enum TokenType {
        InternalBurnable,
        InternalBurnableFrom,
        External
    }

    /// @dev Removed slots; Should avoid re-using
    // bytes32 internal constant KEY_ALL_TOKENS_FROZEN = keccak256('all-tokens-frozen');
    // bytes32 internal constant PREFIX_TOKEN_FROZEN = keccak256('token-frozen');

    /// @dev Storage slot with the address of the current implementation. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 internal constant KEY_IMPLEMENTATION = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    // AUDIT: slot names should be prefixed with some standard string
    bytes32 internal constant PREFIX_COMMAND_EXECUTED = keccak256('command-executed');
    bytes32 internal constant PREFIX_TOKEN_ADDRESS = keccak256('token-address');
    bytes32 internal constant PREFIX_TOKEN_TYPE = keccak256('token-type');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED = keccak256('contract-call-approved');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT = keccak256('contract-call-approved-with-mint');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('token-mint-amount');

    bytes32 internal constant SELECTOR_BURN_TOKEN = keccak256('burnToken');
    bytes32 internal constant SELECTOR_DEPLOY_TOKEN = keccak256('deployToken');
    bytes32 internal constant SELECTOR_MINT_TOKEN = keccak256('mintToken');
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL = keccak256('approveContractCall');
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT = keccak256('approveContractCallWithMint');
    bytes32 internal constant SELECTOR_TRANSFER_OPERATORSHIP = keccak256('transferOperatorship');

    // solhint-disable-next-line var-name-mixedcase
    address internal immutable AUTH_MODULE;
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable TOKEN_DEPLOYER_IMPLEMENTATION;

    constructor(address authModule_, address tokenDeployerImplementation_) {
        if (authModule_.code.length == 0) revert InvalidAuthModule();
        if (tokenDeployerImplementation_.code.length == 0) revert InvalidTokenDeployer();

        AUTH_MODULE = authModule_;
        TOKEN_DEPLOYER_IMPLEMENTATION = tokenDeployerImplementation_;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();

        _;
    }

    /******************\
    |* Public Methods *|
    \******************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external {
        _burnTokenFrom(msg.sender, symbol, amount);
        emit TokenSent(msg.sender, destinationChain, destinationAddress, symbol, amount);
    }

    function callContract(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload
    ) external {
        emit ContractCall(msg.sender, destinationChain, destinationContractAddress, keccak256(payload), payload);
    }

    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external {
        _burnTokenFrom(msg.sender, symbol, amount);
        emit ContractCallWithToken(msg.sender, destinationChain, destinationContractAddress, keccak256(payload), payload, symbol, amount);
    }

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view override returns (bool) {
        return getBool(_getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash));
    }

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view override returns (bool) {
        return
            getBool(
                _getIsContractCallApprovedWithMintKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash, symbol, amount)
            );
    }

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external override returns (bool valid) {
        bytes32 key = _getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, msg.sender, payloadHash);
        valid = getBool(key);
        if (valid) _setBool(key, false);
    }

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external override returns (bool valid) {
        bytes32 key = _getIsContractCallApprovedWithMintKey(commandId, sourceChain, sourceAddress, msg.sender, payloadHash, symbol, amount);
        valid = getBool(key);
        if (valid) {
            // Prevent re-entrance
            _setBool(key, false);
            _mintToken(symbol, msg.sender, amount);
        }
    }

    /***********\
    |* Getters *|
    \***********/

    function authModule() public view returns (address) {
        return AUTH_MODULE;
    }

    function tokenDeployer() public view returns (address) {
        return TOKEN_DEPLOYER_IMPLEMENTATION;
    }

    function tokenMintLimit(string memory symbol) public view override returns (uint256) {
        return getUint(_getTokenMintLimitKey(symbol));
    }

    function tokenMintAmount(string memory symbol) public view override returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return getUint(_getTokenMintAmountKey(symbol, block.timestamp / 6 hours));
    }

    /// @dev This function is kept around to keep things working for internal
    /// tokens that were deployed before the token freeze functionality was removed
    function allTokensFrozen() external pure override returns (bool) {
        return false;
    }

    function implementation() public view override returns (address) {
        return getAddress(KEY_IMPLEMENTATION);
    }

    function tokenAddresses(string memory symbol) public view override returns (address) {
        return getAddress(_getTokenAddressKey(symbol));
    }

    /// @dev This function is kept around to keep things working for internal
    /// tokens that were deployed before the token freeze functionality was removed
    function tokenFrozen(string memory) external pure override returns (bool) {
        return false;
    }

    function isCommandExecuted(bytes32 commandId) public view override returns (bool) {
        return getBool(_getIsCommandExecutedKey(commandId));
    }

    /// @dev Returns the current `adminEpoch`.
    function adminEpoch() external view override returns (uint256) {
        return _adminEpoch();
    }

    /// @dev Returns the admin threshold for a given `adminEpoch`.
    function adminThreshold(uint256 epoch) external view override returns (uint256) {
        return _getAdminThreshold(epoch);
    }

    /// @dev Returns the array of admins within a given `adminEpoch`.
    function admins(uint256 epoch) external view override returns (address[] memory results) {
        uint256 adminCount = _getAdminCount(epoch);
        results = new address[](adminCount);

        for (uint256 i; i < adminCount; ++i) {
            results[i] = _getAdmin(epoch, i);
        }
    }

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external override onlyAdmin {
        if (symbols.length != limits.length) revert InvalidSetMintLimitsParams();

        for (uint256 i = 0; i < symbols.length; i++) {
            string memory symbol = symbols[i];
            uint256 limit = limits[i];

            if (tokenAddresses(symbol) == address(0)) revert TokenDoesNotExist(symbol);

            _setTokenMintLimit(symbol, limit);
        }
    }

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external override onlyAdmin {
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        emit Upgraded(newImplementation);

        // AUDIT: If `newImplementation.setup` performs `selfdestruct`, it will result in the loss of _this_ implementation (thereby losing the gateway)
        //        if `upgrade` is entered within the context of _this_ implementation itself.
        if (setupParams.length != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(IAxelarGateway.setup.selector, setupParams));

            if (!success) revert SetupFailed();
        }

        _setImplementation(newImplementation);
    }

    /**********************\
    |* External Functions *|
    \**********************/

    /// @dev Not publicly accessible as overshadowed in the proxy
    function setup(bytes calldata params) external override {
        // Prevent setup from being called on a non-proxy (the implementation).
        if (implementation() == address(0)) revert NotProxy();

        (address[] memory adminAddresses, uint256 newAdminThreshold, bytes memory newOperatorsData) = abi.decode(
            params,
            (address[], uint256, bytes)
        );

        // NOTE: Admin epoch is incremented to easily invalidate current admin-related state.
        uint256 newAdminEpoch = _adminEpoch() + uint256(1);
        _setAdminEpoch(newAdminEpoch);
        _setAdmins(newAdminEpoch, adminAddresses, newAdminThreshold);

        if (newOperatorsData.length != 0) {
            IAxelarAuth(AUTH_MODULE).transferOperatorship(newOperatorsData);

            emit OperatorshipTransferred(newOperatorsData);
        }
    }

    function execute(bytes calldata input) external override {
        (bytes memory data, bytes memory proof) = abi.decode(input, (bytes, bytes));

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(data));

        // returns true for current operators
        bool allowOperatorshipTransfer = IAxelarAuth(AUTH_MODULE).validateProof(messageHash, proof);

        uint256 chainId;
        bytes32[] memory commandIds;
        string[] memory commands;
        bytes[] memory params;

        (chainId, commandIds, commands, params) = abi.decode(data, (uint256, bytes32[], string[], bytes[]));

        if (chainId != block.chainid) revert InvalidChainId();

        uint256 commandsLength = commandIds.length;

        if (commandsLength != commands.length || commandsLength != params.length) revert InvalidCommands();

        for (uint256 i; i < commandsLength; ++i) {
            bytes32 commandId = commandIds[i];

            if (isCommandExecuted(commandId)) continue; /* Ignore if duplicate commandId received */

            bytes4 commandSelector;
            bytes32 commandHash = keccak256(abi.encodePacked(commands[i]));

            if (commandHash == SELECTOR_DEPLOY_TOKEN) {
                commandSelector = AxelarGateway.deployToken.selector;
            } else if (commandHash == SELECTOR_MINT_TOKEN) {
                commandSelector = AxelarGateway.mintToken.selector;
            } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL) {
                commandSelector = AxelarGateway.approveContractCall.selector;
            } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT) {
                commandSelector = AxelarGateway.approveContractCallWithMint.selector;
            } else if (commandHash == SELECTOR_BURN_TOKEN) {
                commandSelector = AxelarGateway.burnToken.selector;
            } else if (commandHash == SELECTOR_TRANSFER_OPERATORSHIP) {
                if (!allowOperatorshipTransfer) continue;

                allowOperatorshipTransfer = false;
                commandSelector = AxelarGateway.transferOperatorship.selector;
            } else {
                continue; /* Ignore if unknown command received */
            }

            // Prevent a re-entrancy from executing this command before it can be marked as successful.
            _setCommandExecuted(commandId, true);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(abi.encodeWithSelector(commandSelector, params[i], commandId));

            if (success) emit Executed(commandId);
            else _setCommandExecuted(commandId, false);
        }
    }

    /******************\
    |* Self Functions *|
    \******************/

    function deployToken(bytes calldata params, bytes32) external onlySelf {
        (string memory name, string memory symbol, uint8 decimals, uint256 cap, address tokenAddress, uint256 mintLimit) = abi.decode(
            params,
            (string, string, uint8, uint256, address, uint256)
        );

        // Ensure that this symbol has not been taken.
        if (tokenAddresses(symbol) != address(0)) revert TokenAlreadyExists(symbol);

        if (tokenAddress == address(0)) {
            // If token address is no specified, it indicates a request to deploy one.
            bytes32 salt = keccak256(abi.encodePacked(symbol));

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = TOKEN_DEPLOYER_IMPLEMENTATION.delegatecall(
                abi.encodeWithSelector(ITokenDeployer.deployToken.selector, name, symbol, decimals, cap, salt)
            );

            if (!success) revert TokenDeployFailed(symbol);

            tokenAddress = abi.decode(data, (address));

            _setTokenType(symbol, TokenType.InternalBurnableFrom);
        } else {
            // If token address is specified, ensure that there is a contact at the specified address.
            if (tokenAddress.code.length == uint256(0)) revert TokenContractDoesNotExist(tokenAddress);

            // Mark that this symbol is an external token, which is needed to differentiate between operations on mint and burn.
            _setTokenType(symbol, TokenType.External);
        }

        _setTokenAddress(symbol, tokenAddress);
        _setTokenMintLimit(symbol, mintLimit);

        emit TokenDeployed(symbol, tokenAddress);
    }

    function mintToken(bytes calldata params, bytes32) external onlySelf {
        (string memory symbol, address account, uint256 amount) = abi.decode(params, (string, address, uint256));

        _mintToken(symbol, account, amount);
    }

    function burnToken(bytes calldata params, bytes32) external onlySelf {
        (string memory symbol, bytes32 salt) = abi.decode(params, (string, bytes32));

        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);

        if (_getTokenType(symbol) == TokenType.External) {
            address depositHandlerAddress = _getCreate2Address(salt, keccak256(abi.encodePacked(type(DepositHandler).creationCode)));
            // codehash is 0x0 when the deposit handler is not deployed or at the end of tx processing after being destroyed.
            // However, it is NOT 0x0 during the tx processing where it is deployed even though it is destroyed.
            if (depositHandlerAddress.codehash != bytes32(0)) return;

            DepositHandler depositHandler = new DepositHandler{ salt: salt }();

            (bool success, bytes memory returnData) = depositHandler.execute(
                tokenAddress,
                abi.encodeWithSelector(IERC20.transfer.selector, address(this), IERC20(tokenAddress).balanceOf(address(depositHandler)))
            );

            if (!success || (returnData.length != uint256(0) && !abi.decode(returnData, (bool)))) revert BurnFailed(symbol);

            // NOTE: `depositHandler` must always be destroyed in the same runtime context that it is deployed.
            depositHandler.destroy(address(this));
        } else {
            IBurnableMintableCappedERC20(tokenAddress).burn(salt);
        }
    }

    function approveContractCall(bytes calldata params, bytes32 commandId) external onlySelf {
        (
            string memory sourceChain,
            string memory sourceAddress,
            address contractAddress,
            bytes32 payloadHash,
            bytes32 sourceTxHash,
            uint256 sourceEventIndex
        ) = abi.decode(params, (string, string, address, bytes32, bytes32, uint256));

        _setContractCallApproved(commandId, sourceChain, sourceAddress, contractAddress, payloadHash);
        emit ContractCallApproved(commandId, sourceChain, sourceAddress, contractAddress, payloadHash, sourceTxHash, sourceEventIndex);
    }

    function approveContractCallWithMint(bytes calldata params, bytes32 commandId) external onlySelf {
        (
            string memory sourceChain,
            string memory sourceAddress,
            address contractAddress,
            bytes32 payloadHash,
            string memory symbol,
            uint256 amount,
            bytes32 sourceTxHash,
            uint256 sourceEventIndex
        ) = abi.decode(params, (string, string, address, bytes32, string, uint256, bytes32, uint256));

        _setContractCallApprovedWithMint(commandId, sourceChain, sourceAddress, contractAddress, payloadHash, symbol, amount);
        emit ContractCallApprovedWithMint(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            symbol,
            amount,
            sourceTxHash,
            sourceEventIndex
        );
    }

    function transferOperatorship(bytes calldata newOperatorsData, bytes32) external onlySelf {
        IAxelarAuth(AUTH_MODULE).transferOperatorship(newOperatorsData);

        emit OperatorshipTransferred(newOperatorsData);
    }

    /********************\
    |* Internal Methods *|
    \********************/

    function _callERC20Token(address tokenAddress, bytes memory callData) internal returns (bool) {
        if (tokenAddress.code.length == 0) return false;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = tokenAddress.call(callData);
        return success && (returnData.length == 0 || abi.decode(returnData, (bool)));
    }

    function _mintToken(
        string memory symbol,
        address account,
        uint256 amount
    ) internal {
        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);

        _setTokenMintAmount(symbol, tokenMintAmount(symbol) + amount);

        if (_getTokenType(symbol) == TokenType.External) {
            bool success = _callERC20Token(tokenAddress, abi.encodeWithSelector(IERC20.transfer.selector, account, amount));

            if (!success) revert MintFailed(symbol);
        } else {
            IBurnableMintableCappedERC20(tokenAddress).mint(account, amount);
        }
    }

    function _burnTokenFrom(
        address sender,
        string memory symbol,
        uint256 amount
    ) internal {
        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);
        if (amount == 0) revert InvalidAmount();

        TokenType tokenType = _getTokenType(symbol);
        bool burnSuccess;

        if (tokenType == TokenType.External) {
            burnSuccess = _callERC20Token(
                tokenAddress,
                abi.encodeWithSelector(IERC20.transferFrom.selector, sender, address(this), amount)
            );

            if (!burnSuccess) revert BurnFailed(symbol);

            return;
        }

        if (tokenType == TokenType.InternalBurnableFrom) {
            burnSuccess = _callERC20Token(
                tokenAddress,
                abi.encodeWithSelector(IBurnableMintableCappedERC20.burnFrom.selector, sender, amount)
            );

            if (!burnSuccess) revert BurnFailed(symbol);

            return;
        }

        burnSuccess = _callERC20Token(
            tokenAddress,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                sender,
                IBurnableMintableCappedERC20(tokenAddress).depositAddress(bytes32(0)),
                amount
            )
        );

        if (!burnSuccess) revert BurnFailed(symbol);

        IBurnableMintableCappedERC20(tokenAddress).burn(bytes32(0));
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getTokenMintLimitKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_MINT_LIMIT, symbol));
    }

    function _getTokenMintAmountKey(string memory symbol, uint256 day) internal pure returns (bytes32) {
        // abi.encode to securely hash dynamic-length symbol data followed by day
        return keccak256(abi.encode(PREFIX_TOKEN_MINT_AMOUNT, symbol, day));
    }

    function _getTokenTypeKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_TYPE, symbol));
    }

    function _getTokenAddressKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_ADDRESS, symbol));
    }

    function _getIsCommandExecutedKey(bytes32 commandId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_COMMAND_EXECUTED, commandId));
    }

    function _getIsContractCallApprovedKey(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_CONTRACT_CALL_APPROVED, commandId, sourceChain, sourceAddress, contractAddress, payloadHash));
    }

    function _getIsContractCallApprovedWithMintKey(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT,
                    commandId,
                    sourceChain,
                    sourceAddress,
                    contractAddress,
                    payloadHash,
                    symbol,
                    amount
                )
            );
    }

    /********************\
    |* Internal Getters *|
    \********************/

    function _getCreate2Address(bytes32 salt, bytes32 codeHash) internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash)))));
    }

    function _getTokenType(string memory symbol) internal view returns (TokenType) {
        return TokenType(getUint(_getTokenTypeKey(symbol)));
    }

    /********************\
    |* Internal Setters *|
    \********************/

    function _setTokenMintLimit(string memory symbol, uint256 limit) internal {
        _setUint(_getTokenMintLimitKey(symbol), limit);

        emit TokenMintLimitUpdated(symbol, limit);
    }

    function _setTokenMintAmount(string memory symbol, uint256 amount) internal {
        uint256 limit = tokenMintLimit(symbol);
        if (limit > 0 && amount > limit) revert ExceedMintLimit(symbol);

        // solhint-disable-next-line not-rely-on-time
        _setUint(_getTokenMintAmountKey(symbol, block.timestamp / 6 hours), amount);
    }

    function _setTokenType(string memory symbol, TokenType tokenType) internal {
        _setUint(_getTokenTypeKey(symbol), uint256(tokenType));
    }

    function _setTokenAddress(string memory symbol, address tokenAddress) internal {
        _setAddress(_getTokenAddressKey(symbol), tokenAddress);
    }

    function _setCommandExecuted(bytes32 commandId, bool executed) internal {
        _setBool(_getIsCommandExecutedKey(commandId), executed);
    }

    function _setContractCallApproved(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal {
        _setBool(_getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash), true);
    }

    function _setContractCallApprovedWithMint(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount
    ) internal {
        _setBool(
            _getIsContractCallApprovedWithMintKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash, symbol, amount),
            true
        );
    }

    function _setImplementation(address newImplementation) internal {
        _setAddress(KEY_IMPLEMENTATION, newImplementation);
    }
}