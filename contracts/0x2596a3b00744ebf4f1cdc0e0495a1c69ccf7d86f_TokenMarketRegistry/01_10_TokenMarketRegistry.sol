// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../../admin/interfaces/IProtocolRegistry.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";

/// @title helper contract providing the data to the loan market contracts.
contract TokenMarketRegistry is
    ITokenMarketRegistry,
    OwnableUpgradeable,
    SuperAdminControl
{

    uint256 public loanActivateLimit;
    uint256 public minLoanAmountAllowed;
    uint256 public ltvPercentage;

    address public govAdminRegistry;
    address public ProtocolRegistry;
    address public addressProvider;

    address public AGGREGATION_ROUTER_1InchV4;

    mapping(address => bool) public whitelistAddress;
    address[] public allWhitelistAddresses;


    function initialize() external initializer {
        __Ownable_init();
        ltvPercentage = 125;
    }

    /// @dev function to set minimum loan amount allowed to create loan
    /// @param _minLoanAmount should be set in normal value, not in decimals, as decimals are handled in Token and NFT Market Loans
    function setMinLoanAmount(uint256 _minLoanAmount) external onlyOwner {
        require(_minLoanAmount > 0, "minLoanAmount Invalid");
        minLoanAmountAllowed = _minLoanAmount;
    }

    function setAggregatorRouter1InchV4(address _1InchAggregatorV4)
        external
        onlyOwner
    {
        require(_1InchAggregatorV4 != address(0), "address invalid");
        AGGREGATION_ROUTER_1InchV4 = _1InchAggregatorV4;
    }

    /// @dev function to update the address provider the contract address provider
    function updateAddresses() external onlyOwner {
        ProtocolRegistry = IAddressProvider(addressProvider)
            .getProtocolRegistry();
        govAdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
    }

    /// @dev set the contract address provider
    /// @param _addressProvider contract address of the address provider
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
    event LTVPercentageUpdated(uint256 ltvPercentage);

    /// @dev set the loan activate limit for the token market contract
    /// @param _loansLimit limit allowed for loan activation
    function setloanActivateLimit(uint256 _loansLimit)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    /// @dev returns the loan activate limit
    /// @return uint256 returns the loan activation limit for the lender
    function getLoanActivateLimit() external view override returns (uint256) {
        return loanActivateLimit;
    }

    /// @dev set the LTV percentage limit
    /// @param _ltvPercentage percentage allowed for the liquidation
    function setLTVPercentage(uint256 _ltvPercentage)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_ltvPercentage > 0, "GTM: percentage amount error");
        ltvPercentage = _ltvPercentage;
        emit LTVPercentageUpdated(_ltvPercentage);
    }

    /// @dev get the ltv percentage set by the super admin
    /// @return uint256 returns the ltv percentage amount
    function getLTVPercentage() external view override returns (uint256) {
        return ltvPercentage;
    }

    /// @dev set whitelist address for lending unlimited loans
    /// @param _lender add lender address for unlimited loan activation
    /// @param _value bool value true or false to remove unlimited loan feature for loan activation
    function setWhilelistAddress(address _lender, bool _value)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        require(!isWhitelisedLender(_lender), "GTM: lender already whitelisted");
        whitelistAddress[_lender] = _value;
        allWhitelistAddresses.push(_lender);
    }

    /// @dev set whitelist address for lending unlimited loans
    /// @param _lender add lender address for unlimited loan activation
    /// @param _value bool value true or false to remove unlimited loan feature for loan activation
    function updateWhilelistAddress(address _lender, bool _value)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        require(isWhitelisedLender(_lender), "GTM: cannot update lender");
        require(whitelistAddress[_lender] != _value, "already assigned");
        whitelistAddress[_lender] = _value;

    }

    function isWhitelisedLender(address _lender) public view returns(bool) {
        uint256 lengthLenders = allWhitelistAddresses.length;
        for (uint256 i = 0; i < lengthLenders; i++) {
            if (allWhitelistAddresses[i] == _lender) {
                return true;
            }
        }
        return false;
    }

    function getAllWhitelisedLenders() external view returns(address[] memory) {
        return allWhitelistAddresses;
    }

    /// @dev returns boolean flag is address is whitelisted for unlimited lending
    /// @param _lender address of the lender for checking if its whitelisted for activate unlimited loans
    /// @return bool value returns for whitelisted addresses
    function isWhitelistedForActivation(address _lender)
        external
        view
        override
        returns (bool)
    {
        return whitelistAddress[_lender];
    }

    /// @dev check if the caller is super admin
    /// @param _wallet call of the function in loan overall protocol
    /// @return bool returns true or false for the _wallet address
    function isSuperAdminAccess(address _wallet)
        external
        view
        override
        returns (bool)
    {
        return IAdminRegistry(govAdminRegistry).isSuperAdminAccess(_wallet);
    }

    /// @dev checks if token is approved or not
    /// @param _token  collateral token address to check if approved
    /// @return bool return true or false value for the approved tokens
    function isTokenApproved(address _token)
        external
        view
        override
        returns (bool)
    {
        return IProtocolRegistry(ProtocolRegistry).isTokenApproved(_token);
    }

    /// @dev checks if token enable for creating loans in token market
    /// @param _token collateral token address
    /// @return bool returns true or false value
    function isTokenEnabledForCreateLoan(address _token)
        external
        view
        override
        returns (bool)
    {
        return
            IProtocolRegistry(ProtocolRegistry).isTokenEnabledForCreateLoan(
                _token
            );
    }

    /// @dev get the gov platform fee
    /// @return uint256 returns the platform fee set by the super admin
    function getGovPlatformFee() external view override returns (uint256) {
        return IProtocolRegistry(ProtocolRegistry).getGovPlatformFee();
    }

    /// @dev function that will get AutoSell APY fee of the loan amount
    /// @param loanAmount loan amount for autosell apy fee deduction
    /// @param autosellAPY autosell apy fee in percentage
    /// @param loanterminDays loan term length in days
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }

    /// @dev function that will get APY fee of the loan amount in borrower
    /// @param _loanAmountInBorrowed loan amount in stable coin
    /// @param _apyOffer apy offer by the borrower in percentage value (basis points)
    /// @param _termsLengthInDays loan term length in days
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return
            ((_loanAmountInBorrowed * _apyOffer) / 10000 / 365) *
            _termsLengthInDays;
    }

    /// @dev get the single approved token data including the dex router address
    /// @param _tokenAddress approved collateral token address
    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        override
        returns (
            address,
            bool,
            uint256
        )
    {
        return
            IProtocolRegistry(ProtocolRegistry).getSingleApproveTokenData(
                _tokenAddress
            );
    }

    /// @dev to check if synthetic mint option is on or off for approved vip tokens
    /// @param _tokenAddress address of the collateral token
    /// @return bool returns true or false value
    function isSyntheticMintOn(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return
            IProtocolRegistry(ProtocolRegistry).isSyntheticMintOn(
                _tokenAddress
            );
    }

    /// @dev to check if stable coin is approved
    /// @param _stable stable coin addres
    /// @return bool returns ture or false value
    function isStableApproved(address _stable)
        external
        view
        override
        returns (bool)
    {
        return IProtocolRegistry(ProtocolRegistry).isStableApproved(_stable);
    }

    function getOneInchAggregator() external view override returns (address) {
        return AGGREGATION_ROUTER_1InchV4;
    }

    function getMinLoanAmountAllowed()
        external
        view
        override
        returns (uint256)
    {
        return minLoanAmountAllowed;
    }
}