// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {DataTypesPeerToPeer} from "./DataTypesPeerToPeer.sol";
import {Errors} from "../Errors.sol";
import {Helpers} from "../Helpers.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {IERC721Wrapper} from "./interfaces/wrappers/ERC721/IERC721Wrapper.sol";
import {IERC20Wrapper} from "./interfaces/wrappers/ERC20/IERC20Wrapper.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

/**
 * @dev AddressRegistry is a contract that stores addresses of other contracts and controls whitelist state
 * IMPORTANT: This contract allows for de-whitelisting as well. This is an important security feature because if
 * a contract or token is found to present a vulnerability, it can be de-whitelisted to prevent further borrowing
 * with that token (repays and withdrawals would still be allowed). In the limit of a total de-whitelisting of all
 * tokens, all borrowing in the protocol would be paused. This feature can also be utilized if a fork with the same chainId is found.
 */
contract AddressRegistry is Initializable, Ownable2Step, IAddressRegistry {
    using ECDSA for bytes32;

    address public lenderVaultFactory;
    address public borrowerGateway;
    address public quoteHandler;
    address public mysoTokenManager;
    address public erc721Wrapper;
    address public erc20Wrapper;
    mapping(address => bool) public isRegisteredVault;
    mapping(bytes => bool) internal _signatureIsInvalidated;
    mapping(address => mapping(address => uint256))
        internal _borrowerWhitelistedUntil;
    mapping(address => DataTypesPeerToPeer.WhitelistState)
        public whitelistState;
    // compartment => token => active
    mapping(address => mapping(address => bool))
        internal _isTokenWhitelistedForCompartment;
    address[] internal _registeredVaults;

    constructor() {
        super._transferOwnership(msg.sender);
    }

    function initialize(
        address _lenderVaultFactory,
        address _borrowerGateway,
        address _quoteHandler
    ) external initializer {
        _checkOwner();
        if (
            _lenderVaultFactory == address(0) ||
            _borrowerGateway == address(0) ||
            _quoteHandler == address(0)
        ) {
            revert Errors.InvalidAddress();
        }
        if (
            _lenderVaultFactory == _borrowerGateway ||
            _lenderVaultFactory == _quoteHandler ||
            _borrowerGateway == _quoteHandler
        ) {
            revert Errors.DuplicateAddresses();
        }
        lenderVaultFactory = _lenderVaultFactory;
        borrowerGateway = _borrowerGateway;
        quoteHandler = _quoteHandler;
    }

    function setWhitelistState(
        address[] calldata addrs,
        DataTypesPeerToPeer.WhitelistState state
    ) external {
        _checkIsInitialized();
        _checkOwner();
        uint256 addrsLen = addrs.length;
        if (addrsLen < 1) {
            revert Errors.InvalidArrayLength();
        }

        (
            address _erc721Wrapper,
            address _erc20Wrapper,
            address _mysoTokenManager
        ) = (erc721Wrapper, erc20Wrapper, mysoTokenManager);
        // note (1/2): ERC721WRAPPER, ERC20WRAPPER and MYSO_TOKEN_MANAGER state can only be "occupied" by
        // one addresses ("singleton state")
        if (
            state == DataTypesPeerToPeer.WhitelistState.ERC721WRAPPER ||
            state == DataTypesPeerToPeer.WhitelistState.ERC20WRAPPER ||
            state == DataTypesPeerToPeer.WhitelistState.MYSO_TOKEN_MANAGER
        ) {
            if (addrsLen != 1) {
                revert Errors.InvalidArrayLength();
            }
            if (addrs[0] == address(0)) {
                revert Errors.InvalidAddress();
            }
            _updateSingletonAddr(
                addrs[0],
                state,
                _erc721Wrapper,
                _erc20Wrapper,
                _mysoTokenManager
            );
            whitelistState[addrs[0]] = state;
        } else {
            // note (2/2): all other states can be "occupied" by multiple addresses
            for (uint256 i; i < addrsLen; ) {
                if (addrs[i] == address(0)) {
                    revert Errors.InvalidAddress();
                }
                if (whitelistState[addrs[i]] == state) {
                    revert Errors.StateAlreadySet();
                }
                // check if addr was singleton before and delete, if needed
                _checkAddrAndDeleteIfSingleton(
                    addrs[i],
                    _erc721Wrapper,
                    _erc20Wrapper,
                    _mysoTokenManager
                );
                whitelistState[addrs[i]] = state;
                unchecked {
                    ++i;
                }
            }
        }
        emit WhitelistStateUpdated(addrs, state);
    }

    function setAllowedTokensForCompartment(
        address compartmentImpl,
        address[] calldata tokens,
        bool allowTokensForCompartment
    ) external {
        _checkIsInitialized();
        _checkOwner();
        // check that tokens can only be whitelisted for valid compartment (whereas de-whitelisting is always possible)
        if (
            allowTokensForCompartment &&
            whitelistState[compartmentImpl] !=
            DataTypesPeerToPeer.WhitelistState.COMPARTMENT
        ) {
            revert Errors.NonWhitelistedCompartment();
        }
        uint256 tokensLen = tokens.length;
        if (tokensLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        for (uint256 i; i < tokensLen; ) {
            if (allowTokensForCompartment && !isWhitelistedERC20(tokens[i])) {
                revert Errors.NonWhitelistedToken();
            }
            if (
                _isTokenWhitelistedForCompartment[compartmentImpl][tokens[i]] ==
                allowTokensForCompartment
            ) {
                revert Errors.InvalidUpdate();
            }
            _isTokenWhitelistedForCompartment[compartmentImpl][
                tokens[i]
            ] = allowTokensForCompartment;
            unchecked {
                ++i;
            }
        }
        emit AllowedTokensForCompartmentUpdated(
            compartmentImpl,
            tokens,
            allowTokensForCompartment
        );
    }

    function addLenderVault(address addr) external returns (uint256) {
        _checkIsInitialized();
        // catches case where address registry is uninitialized (lenderVaultFactory == address(0))
        if (msg.sender != lenderVaultFactory) {
            revert Errors.InvalidSender();
        }
        isRegisteredVault[addr] = true;
        _registeredVaults.push(addr);
        return _registeredVaults.length;
    }

    function claimBorrowerWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external {
        if (_signatureIsInvalidated[compactSig]) {
            revert Errors.InvalidSignature();
        }
        bytes32 payloadHash = keccak256(
            abi.encode(
                address(this),
                msg.sender,
                whitelistedUntil,
                block.chainid,
                salt
            )
        );
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(payloadHash);
        (bytes32 r, bytes32 vs) = Helpers.splitSignature(compactSig);
        address recoveredSigner = messageHash.recover(r, vs);
        if (
            whitelistAuthority == address(0) ||
            recoveredSigner != whitelistAuthority
        ) {
            revert Errors.InvalidSignature();
        }
        mapping(address => uint256)
            storage whitelistedUntilPerBorrower = _borrowerWhitelistedUntil[
                whitelistAuthority
            ];
        if (
            whitelistedUntil < block.timestamp ||
            whitelistedUntil <= whitelistedUntilPerBorrower[msg.sender]
        ) {
            revert Errors.CannotClaimOutdatedStatus();
        }
        whitelistedUntilPerBorrower[msg.sender] = whitelistedUntil;
        _signatureIsInvalidated[compactSig] = true;
        emit BorrowerWhitelistStatusClaimed(
            whitelistAuthority,
            msg.sender,
            whitelistedUntil
        );
    }

    function createWrappedTokenForERC721s(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol,
        bytes calldata mysoTokenManagerData
    ) external {
        address _erc721Wrapper = erc721Wrapper;
        if (_erc721Wrapper == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager)
                .processP2PCreateWrappedTokenForERC721s(
                    msg.sender,
                    tokensToBeWrapped,
                    mysoTokenManagerData
                );
        }
        address newERC20Addr = IERC721Wrapper(_erc721Wrapper)
            .createWrappedToken(msg.sender, tokensToBeWrapped, name, symbol);
        whitelistState[newERC20Addr] = DataTypesPeerToPeer
            .WhitelistState
            .ERC20_TOKEN;
        emit CreatedWrappedTokenForERC721s(
            tokensToBeWrapped,
            name,
            symbol,
            newERC20Addr
        );
    }

    function createWrappedTokenForERC20s(
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol,
        bytes calldata mysoTokenManagerData
    ) external {
        address _erc20Wrapper = erc20Wrapper;
        if (_erc20Wrapper == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager)
                .processP2PCreateWrappedTokenForERC20s(
                    msg.sender,
                    tokensToBeWrapped,
                    mysoTokenManagerData
                );
        }
        address newERC20Addr = IERC20Wrapper(_erc20Wrapper).createWrappedToken(
            msg.sender,
            tokensToBeWrapped,
            name,
            symbol
        );
        whitelistState[newERC20Addr] = DataTypesPeerToPeer
            .WhitelistState
            .ERC20_TOKEN;
        emit CreatedWrappedTokenForERC20s(
            tokensToBeWrapped,
            name,
            symbol,
            newERC20Addr
        );
    }

    function updateBorrowerWhitelist(
        address[] calldata borrowers,
        uint256 whitelistedUntil
    ) external {
        uint256 borrowersLen = borrowers.length;
        if (borrowersLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        for (uint256 i; i < borrowersLen; ) {
            mapping(address => uint256)
                storage whitelistedUntilPerBorrower = _borrowerWhitelistedUntil[
                    msg.sender
                ];
            if (
                borrowers[i] == address(0) ||
                whitelistedUntil == whitelistedUntilPerBorrower[borrowers[i]]
            ) {
                revert Errors.InvalidUpdate();
            }
            whitelistedUntilPerBorrower[borrowers[i]] = whitelistedUntil;
            unchecked {
                ++i;
            }
        }
        emit BorrowerWhitelistUpdated(msg.sender, borrowers, whitelistedUntil);
    }

    function isWhitelistedBorrower(
        address whitelistAuthority,
        address borrower
    ) external view returns (bool) {
        return
            _borrowerWhitelistedUntil[whitelistAuthority][borrower] >=
            block.timestamp;
    }

    function isWhitelistedCompartment(
        address compartment,
        address token
    ) external view returns (bool) {
        return
            whitelistState[compartment] ==
            DataTypesPeerToPeer.WhitelistState.COMPARTMENT &&
            _isTokenWhitelistedForCompartment[compartment][token];
    }

    function registeredVaults() external view returns (address[] memory) {
        return _registeredVaults;
    }

    function numRegisteredVaults() external view returns (uint256) {
        return _registeredVaults.length;
    }

    function transferOwnership(
        address _newOwnerProposal
    ) public override(Ownable2Step, IAddressRegistry) {
        _checkIsInitialized();
        if (
            _newOwnerProposal == address(this) ||
            _newOwnerProposal == pendingOwner() ||
            _newOwnerProposal == owner()
        ) {
            revert Errors.InvalidNewOwnerProposal();
        }
        // @dev: access control check via super.transferOwnership()
        super.transferOwnership(_newOwnerProposal);
    }

    function owner()
        public
        view
        override(Ownable, IAddressRegistry)
        returns (address)
    {
        return super.owner();
    }

    function pendingOwner()
        public
        view
        override(Ownable2Step, IAddressRegistry)
        returns (address)
    {
        return super.pendingOwner();
    }

    function isWhitelistedERC20(address token) public view returns (bool) {
        DataTypesPeerToPeer.WhitelistState tokenWhitelistState = whitelistState[
            token
        ];
        return
            tokenWhitelistState ==
            DataTypesPeerToPeer.WhitelistState.ERC20_TOKEN ||
            tokenWhitelistState ==
            DataTypesPeerToPeer
                .WhitelistState
                .ERC20_TOKEN_REQUIRING_COMPARTMENT;
    }

    function renounceOwnership() public pure override {
        revert Errors.Disabled();
    }

    function _updateSingletonAddr(
        address newAddr,
        DataTypesPeerToPeer.WhitelistState state,
        address _erc721Wrapper,
        address _erc20Wrapper,
        address _mysoTokenManager
    ) internal {
        // check if address already has given state set or
        // other singleton addresses occupy target state
        if (
            whitelistState[newAddr] == state ||
            whitelistState[_erc721Wrapper] == state ||
            whitelistState[_erc20Wrapper] == state ||
            whitelistState[_mysoTokenManager] == state
        ) {
            revert Errors.StateAlreadySet();
        }
        // check if addr was singleton before and delete, if needed
        _checkAddrAndDeleteIfSingleton(
            newAddr,
            _erc721Wrapper,
            _erc20Wrapper,
            _mysoTokenManager
        );
        if (state == DataTypesPeerToPeer.WhitelistState.ERC721WRAPPER) {
            erc721Wrapper = newAddr;
        } else if (state == DataTypesPeerToPeer.WhitelistState.ERC20WRAPPER) {
            erc20Wrapper = newAddr;
        } else {
            mysoTokenManager = newAddr;
        }
    }

    function _checkAddrAndDeleteIfSingleton(
        address addr,
        address _erc721Wrapper,
        address _erc20Wrapper,
        address _mysoTokenManager
    ) internal {
        if (addr == _erc721Wrapper) {
            delete erc721Wrapper;
        } else if (addr == _erc20Wrapper) {
            delete erc20Wrapper;
        } else if (addr == _mysoTokenManager) {
            delete mysoTokenManager;
        }
    }

    function _checkIsInitialized() internal view {
        if (_getInitializedVersion() == 0) {
            revert Errors.Uninitialized();
        }
    }
}