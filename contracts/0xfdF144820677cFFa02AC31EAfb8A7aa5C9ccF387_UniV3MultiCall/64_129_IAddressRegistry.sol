// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";

interface IAddressRegistry {
    event WhitelistStateUpdated(
        address[] indexed whitelistAddrs,
        DataTypesPeerToPeer.WhitelistState indexed whitelistState
    );
    event AllowedTokensForCompartmentUpdated(
        address indexed compartmentImpl,
        address[] tokens,
        bool isWhitelisted
    );
    event BorrowerWhitelistStatusClaimed(
        address indexed whitelistAuthority,
        address indexed borrower,
        uint256 whitelistedUntil
    );
    event BorrowerWhitelistUpdated(
        address indexed whitelistAuthority,
        address[] borrowers,
        uint256 whitelistedUntil
    );
    event CreatedWrappedTokenForERC721s(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] wrappedTokensInfo,
        string name,
        string symbol,
        address newErc20Addr
    );
    event CreatedWrappedTokenForERC20s(
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] wrappedTokensInfo,
        string name,
        string symbol,
        address newERC20Addr
    );

    /**
     * @notice initializes factory, gateway, and quote handler contracts
     * @param _lenderVaultFactory address of the factory for lender vaults
     * @param _borrowerGateway address of the gateway with which borrowers interact
     * @param _quoteHandler address of contract which handles quote logic
     */
    function initialize(
        address _lenderVaultFactory,
        address _borrowerGateway,
        address _quoteHandler
    ) external;

    /**
     * @notice adds new lender vault to registry
     * @dev can only be called lender vault factory
     * @param addr address of new lender vault
     * @return numRegisteredVaults number of registered vaults
     */
    function addLenderVault(
        address addr
    ) external returns (uint256 numRegisteredVaults);

    /**
     * @notice Allows user to claim whitelisted status
     * @param whitelistAuthority Address of whitelist authorithy
     * @param whitelistedUntil Timestamp until when user is whitelisted
     * @param compactSig Compact signature from whitelist authority
     * @param salt Salt to make signature unique
     */
    function claimBorrowerWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external;

    /**
     * @notice Allows user to wrap (multiple) ERC721 into one ERC20
     * @param tokensToBeWrapped Array of WrappedERC721TokenInfo
     * @param name Name of the new wrapper token
     * @param symbol Symbol of the new wrapper token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     */
    function createWrappedTokenForERC721s(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Allows user to wrap multiple ERC20 into one ERC20
     * @param tokensToBeWrapped Array of WrappedERC20TokenInfo
     * @param name Name of the new wrapper token
     * @param symbol Symbol of the new wrapper token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     */
    function createWrappedTokenForERC20s(
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Allows a whitelist authority to set the whitelistedUntil state for a given borrower
     * @dev Anyone can create their own whitelist, and lenders can decide if and which whitelist they want to use
     * @param borrowers Array of borrower addresses
     * @param whitelistedUntil Timestamp until which borrowers shall be whitelisted under given whitelist authority
     */
    function updateBorrowerWhitelist(
        address[] calldata borrowers,
        uint256 whitelistedUntil
    ) external;

    /**
     * @notice Sets the whitelist state for a given address
     * @dev Can only be called by registry owner
     * @param addrs Addresses for which whitelist state shall be set
     * @param whitelistState The whitelist state to which addresses shall be set
     */
    function setWhitelistState(
        address[] calldata addrs,
        DataTypesPeerToPeer.WhitelistState whitelistState
    ) external;

    /**
     * @notice Sets the allowed tokens for a given compartment implementation
     * @dev Can only be called by registry owner
     * @param compartmentImpl Compartment implementations for which allowed tokens shall be set
     * @param tokens List of tokens that shall be allowed for given compartment implementation
     * @param allowTokensForCompartment Boolean flag indicating whether tokens shall be allowed for compartment 
     implementation
     */
    function setAllowedTokensForCompartment(
        address compartmentImpl,
        address[] calldata tokens,
        bool allowTokensForCompartment
    ) external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns boolean flag indicating whether the borrower has been whitelisted by whitelistAuthority
     * @param whitelistAuthority Addresses of the whitelist authority
     * @param borrower Addresses of the borrower
     * @return Boolean flag indicating whether the borrower has been whitelisted by whitelistAuthority
     */
    function isWhitelistedBorrower(
        address whitelistAuthority,
        address borrower
    ) external view returns (bool);

    /**
     * @notice Returns boolean flag indicating whether token is whitelisted
     * @param token Addresses of the given token to check
     * @return Boolean flag indicating whether the token is whitelisted
     */
    function isWhitelistedERC20(address token) external view returns (bool);

    /**
     * @notice Returns the address of the vault factory
     * @return Address of the vault factory contract
     */
    function lenderVaultFactory() external view returns (address);

    /**
     * @notice Returns the address of the borrower gateway
     * @return Address of the borrower gateway contract
     */
    function borrowerGateway() external view returns (address);

    /**
     * @notice Returns the address of the quote handler
     * @return Address of the quote handler contract
     */
    function quoteHandler() external view returns (address);

    /**
     * @notice Returns the address of the MYSO token manager
     * @return Address of the MYSO token manager contract
     */
    function mysoTokenManager() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether given address is a registered vault
     * @param addr Address to check if it is a registered vault
     * @return Boolean flag indicating whether given address is a registered vault
     */
    function isRegisteredVault(address addr) external view returns (bool);

    /**
     * @notice Returns whitelist state for given address
     * @param addr Address to check whitelist state for
     * @return whitelistState Whitelist state for given address
     */
    function whitelistState(
        address addr
    ) external view returns (DataTypesPeerToPeer.WhitelistState whitelistState);

    /**
     * @notice Returns an array of registered vault addresses
     * @return vaultAddrs The array of registered vault addresses
     */
    function registeredVaults()
        external
        view
        returns (address[] memory vaultAddrs);

    /**
     * @notice Returns address of the owner
     * @return Address of the owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether given compartment implementation and token combination is whitelisted
     * @param compartmentImpl Address of compartment implementation to check if it is allowed for token
     * @param token Address of token to check if compartment implementation is allowed
     * @return isWhitelisted Boolean flag indicating whether compartment implementation is whitelisted for given token
     */
    function isWhitelistedCompartment(
        address compartmentImpl,
        address token
    ) external view returns (bool isWhitelisted);

    /**
     * @notice Returns current number of vaults registered
     * @return numVaults Current number of vaults registered
     */
    function numRegisteredVaults() external view returns (uint256 numVaults);
}