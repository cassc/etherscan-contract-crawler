// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title NF3 Storage Registry Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to storage for the protocol.

interface IStorageRegistry {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    enum StorageRegistryErrorCodes {
        INVALID_NONCE,
        CALLER_NOT_APPROVED,
        INVALID_ADDRESS
    }

    error StorageRegistryError(StorageRegistryErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when status has changed.
    /// @param owner user whose nonce is updated
    /// @param nonce value of updated nonce
    event NonceSet(address owner, uint256 nonce);

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new loan contract address has set
    /// @param oldLoanAddress Previous loan contract address
    /// @param newLoanAddress New whitelist contract address
    event LoanSet(address oldLoanAddress, address newLoanAddress);

    /// @dev Emits when airdrop claim implementation address is set
    /// @param oldAirdropClaimImplementation Previous air drop claim implementation address
    /// @param newAirdropClaimImplementation New air drop claim implementation address
    event AirdropClaimImplementationSet(
        address oldAirdropClaimImplementation,
        address newAirdropClaimImplementation
    );

    /// @dev Emits when signing utils library address is set
    /// @param oldSigningUtilsAddress Previous air drop claim implementation address
    /// @param newSigningUtilsAddress New air drop claim implementation address
    event SigningUtilSet(
        address oldSigningUtilsAddress,
        address newSigningUtilsAddress
    );

    /// @dev Emits when new position token address has set.
    /// @param oldPositionTokenAddress Previous position token contract address
    /// @param newPositionTokenAddress New position token contract address
    event PositionTokenSet(
        address oldPositionTokenAddress,
        address newPositionTokenAddress
    );

    /// -----------------------------------------------------------------------
    /// Nonce actions
    /// -----------------------------------------------------------------------

    /// @dev Get the value of nonce without reverting.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function getNonce(address owner, uint256 _nonce)
        external
        view
        returns (bool);

    /// @dev Check if the nonce is in correct status.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function checkNonce(address owner, uint256 _nonce) external view;

    /// @dev Set the nonce value of a user. Can only be called by reserve contract.
    /// @param owner Address of the user
    /// @param _nonce Nonce value of the user
    function setNonce(address owner, uint256 _nonce) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param _marketAddress Market contract address
    function setMarket(address _marketAddress) external;

    /// @dev Set Vault contract address.
    /// @param _vaultAddress Vault contract address
    function setVault(address _vaultAddress) external;

    /// @dev Set Reserve contract address.
    /// @param _reserveAddress Reserve contract address
    function setReserve(address _reserveAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param _whitelistAddress contract address
    function setWhitelist(address _whitelistAddress) external;

    /// @dev Set Swap contract address.
    /// @param _swapAddress Swap contract address
    function setSwap(address _swapAddress) external;

    /// @dev Set Loan contract address
    /// @param _loanAddress Whitelist contract address
    function setLoan(address _loanAddress) external;

    /// @dev Set Signing Utils library address
    /// @param _signingUtilsAddress signing utils contract address
    function setSigningUtil(address _signingUtilsAddress) external;

    /// @dev Set air drop claim contract implementation address
    /// @param _airdropClaimImplementation Airdrop claim contract address
    function setAirdropClaimImplementation(address _airdropClaimImplementation)
        external;

    /// @dev Set position token contract address
    /// @param _positionTokenAddress position token contract address
    function setPositionToken(address _positionTokenAddress) external;

    /// @dev Whitelist airdrop contract that can be called for the user
    /// @param _contract address of the airdrop contract
    /// @param _allow bool value for the whitelist
    function setAirdropWhitelist(address _contract, bool _allow) external;

    /// @notice Set claim contract address for position token
    /// @param _tokenId Token id for which the claim contract is deployed
    /// @param _claimContract address of the claim contract
    function setClaimContractAddresses(uint256 _tokenId, address _claimContract)
        external;

    /// -----------------------------------------------------------------------
    /// Public Getter Functions
    /// -----------------------------------------------------------------------

    /// @dev Get whitelist contract address
    function whitelistAddress() external view returns (address);

    /// @dev Get vault contract address
    function vaultAddress() external view returns (address);

    /// @dev Get swap contract address
    function swapAddress() external view returns (address);

    /// @dev Get reserve contract address
    function reserveAddress() external view returns (address);

    /// @dev Get market contract address
    function marketAddress() external view returns (address);

    /// @dev Get loan contract address
    function loanAddress() external view returns (address);

    /// @dev Get airdropClaim contract address
    function airdropClaimImplementation() external view returns (address);

    /// @dev Get signing utils contract address
    function signingUtilsAddress() external view returns (address);

    /// @dev Get position token contract address
    function positionTokenAddress() external view returns (address);

    /// @dev Get claim contract address
    function claimContractAddresses(uint256 _tokenId)
        external
        view
        returns (address);

    /// @dev Get whitelist of an airdrop contract
    function airdropWhitelist(address _contract) external view returns (bool);
}