// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./interfaces/IProtocolRegistry.sol";
import "./IGTokenFactory.sol";
import "contracts/admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../addressprovider/AddressProvider.sol";

/// @author IdeoFuzion Team
/// @title  Protocol Registry Base Contract
/// @dev abstract contract for the protocol registry contract

abstract contract ProtocolBase is
    OwnableUpgradeable,
    IProtocolRegistry,
    SuperAdminControl
{
    /// tokenAddress => spWalletAddress
    mapping(address => address[]) public approvedSps;
    /// array of all approved SP Wallet Addresses
    address[] public allApprovedSps;
    address public liquidatorContract;
    address public tokenMarket;
    address public gTokenFactory;

    address public addressProvider;

    /// @dev tokenContractAddress => Market struct
    mapping(address => Market) public approvedTokens;

    /// @dev array of all Approved ERC20 Token Contracts
    address[] allapprovedTokenContracts;
    event TokensAdded(
        address indexed tokenAddress,
        address indexed dexRouter,
        address indexed gToken,
        bool isMint,
        TokenType tokenType,
        bool isTokenEnabledAsCollateral
    );
    event TokensUpdated(
        address indexed tokenAddress,
        Market indexed _marketData
    );

    event SPWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event BulkSpWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddresses
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event SPWalletRemoved(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event TokenStatusUpdated(address indexed tokenAddress, bool status);
    event UpdatedStableCoinStatus(address indexed stableCoin, bool status);
    event AdminPercentageUpdated(uint256 AdminWalletpercentage);
    event UpdatedUnearnedAPYPer(uint256 unearnedAPYPer);
    event GovPlatformFeeUpdated(uint256 govPlatformPercentage);
    event ThresholdFeeUpdated(uint256 thresholdPercentageAutosellOff);
    event AutoSellFeeUpdated(uint256 autoSellFeePercentage);

    /// @dev function to set the liquidator contract used in the deployGToken function
    /// @param _liquidator address of the Gov Liquidator Contract
    function setLiquidatorContractAddress(address _liquidator)
        external
        onlyOwner
    {
        require(_liquidator != address(0), "Liquidator Empty");
        liquidatorContract = _liquidator;
    }

    /// @dev function
    function setTokenMarketAddress(address _tokenMarket) external onlyOwner {
        require(_tokenMarket != address(0), "Market Empty");
        tokenMarket = _tokenMarket;
    }

    function setGTokenFactory(address _tokenFactory) external onlyOwner {
        require(_tokenFactory != address(0), "Factory Empty");
        gTokenFactory = _tokenFactory;
    }

    /** Internal functions of the Gov Protocol Contract */

    /// @dev function to add token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param marketData struct object to be added in approvedTokens mapping

    function _addToken(address _tokenAddress, Market memory marketData)
        internal
    {

        require(_tokenAddress != marketData.dexRouter, "GPL: token and dex address same");

        //adding marketData to the approvedToken mapping
        if (marketData.tokenType == TokenType.ISVIP) {
            require(
                _tokenAddress == marketData.gToken,
                "GPL: gtoken must equal token address"
            );
            require(
                liquidatorContract != address(0x0) &&
                    tokenMarket != address(0x0),
                "GPL: set addresses first"
            );
            address adminRegistry = IAddressProvider(addressProvider)
                .getAdminRegistry();
            marketData.gToken = IGTokenFactory(gTokenFactory).deployGToken(
                _tokenAddress,
                liquidatorContract,
                tokenMarket,
                adminRegistry
            );
        } else {
            marketData.gToken = address(0x0);
            marketData.isMint = false;
        }

        approvedTokens[_tokenAddress] = marketData;

        emit TokensAdded(
            _tokenAddress,
            approvedTokens[_tokenAddress].dexRouter,
            approvedTokens[_tokenAddress].gToken,
            approvedTokens[_tokenAddress].isMint,
            approvedTokens[_tokenAddress].tokenType,
            approvedTokens[_tokenAddress].isTokenEnabledAsCollateral
        );
        allapprovedTokenContracts.push(_tokenAddress);
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param _marketData struct object to be added in approvedTokens mapping

    function _updateToken(address _tokenAddress, Market memory _marketData)
        internal
    {   
        
        require(_tokenAddress != _marketData.dexRouter, "GPL: token and dex address same");

        //update Token Data  to the approvedTokens mapping
        Market memory _prevTokenData = approvedTokens[_tokenAddress];

        if (
            _prevTokenData.gToken == address(0x0) &&
            _marketData.tokenType == TokenType.ISVIP
        ) {
            address adminRegistry = IAddressProvider(addressProvider)
                .getAdminRegistry();

            address gToken = IGTokenFactory(gTokenFactory).deployGToken(
                _tokenAddress,
                liquidatorContract,
                tokenMarket,
                adminRegistry
            );
            _marketData.gToken = gToken;
        } else if (_prevTokenData.tokenType == TokenType.ISVIP) {
            _marketData.gToken = _prevTokenData.gToken;
        } else {
            _marketData.gToken = address(0x0);
            _marketData.isMint = false;
        }

        approvedTokens[_tokenAddress] = _marketData;
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false if token enable or disbale for collateral
    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return approvedTokens[_tokenAddress].isTokenEnabledAsCollateral;
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false value for token address
    function isTokenApproved(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        uint256 length = allapprovedTokenContracts.length;
        for (uint256 i = 0; i < length; i++) {
            if (allapprovedTokenContracts[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress sp wallet address added to the approvedSps

    function _addSp(address _tokenAddress, address _walletAddress) internal {
        // add the sp wallet address to the approvedSps mapping
        approvedSps[_tokenAddress].push(_walletAddress);
        // push sp _walletAddress to allApprovedSps array
        allApprovedSps.push(_walletAddress);
        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    /// @dev check if _walletAddress is already added Sp in array
    /// @param _walletAddress wallet address checking

    function _isAlreadyAddedSp(address _walletAddress)
        internal
        view
        returns (bool)
    {
        uint256 length = allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev checking the approvedSps mapping if already walletAddress
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress wallet address of the approved Sp
    /// @return bool true or false value for the sp wallet address

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        override
        returns (bool)
    {
        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address currentWallet = approvedSps[_tokenAddress][i];
            if (currentWallet == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev remove the Sp token address from the allapprovedsps array
    /// @param index index of the sp address being removed from the allApprovedSps

    function _removeSpKey(uint256 index) internal {
        uint256 length = allApprovedSps.length;
        for (uint256 i = index; i < length - 1; i++) {
            allApprovedSps[i] = allApprovedSps[i + 1];
        }
        allApprovedSps.pop();
    }

    /// @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    /// @param index of the approved wallet sp
    /// @param _tokenAddress token contract address of the approvedToken sp

    function _removeSpKeyfromMapping(uint256 index, address _tokenAddress)
        internal
    {
        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = index; i < length - 1; i++) {
            approvedSps[_tokenAddress][i] = approvedSps[_tokenAddress][i + 1];
        }
        approvedSps[_tokenAddress].pop();
    }

    /// @dev getting index of sp from the allApprovedSps array
    /// @param _walletAddress getting this wallet address index
    function _getIndexofAddressfromArray(address _walletAddress)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return i;
            }
        }
    }

    /// @dev get index of the wallet from the approvedSps mapping
    /// @param tokenAddress token contract address
    /// @param _walletAddress getting this wallet address index

    function _getWalletIndexfromMapping(
        address tokenAddress,
        address _walletAddress
    ) internal view returns (uint256 index) {
        uint256 length = approvedSps[tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function _addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        internal
    {
        uint256 length = _walletAddress.length;
        for (uint256 i = 0; i < length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_walletAddress[i]),
                "one or more wallet addresses already added in allapprovedSps array"
            );

            approvedSps[_tokenAddress].push(_walletAddress[i]);
            allApprovedSps.push(_walletAddress[i]);
            emit BulkSpWalletAdded(_tokenAddress, _walletAddress[i]);
        }
    }

    /// @dev internal function to update Sp wallet Address,
    /// @dev doing it by removing old wallet first then add new wallet address
    /// @param _tokenAddress token contract address as a key to update sp wallet
    /// @param _oldWalletAddress old SP wallet address
    /// @param _newWalletAddress new SP wallet address

    function _updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) internal {
        //update wallet addres to the approved Sps mapping

        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address oldWalletAddress = approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(oldWalletAddress),
                    _tokenAddress
                );
                approvedSps[_tokenAddress].push(_newWalletAddress);
                allApprovedSps.push(_newWalletAddress);
            
        }
        emit SPWalletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /// @dev update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function _updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) internal {
        require(
            _oldWalletAddress.length == _newWalletAddress.length,
            "GPR: Length of old and new wallet should be equal"
        );

        for (uint256 i = 0; i < _oldWalletAddress.length; i++) {
            //checking Wallet if already added
            address currentWallet = _oldWalletAddress[i];
            address newWallet = _newWalletAddress[i];
            require(
                _isAlreadyAddedSp(currentWallet),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in array"
            );

            _removeSpKey(_getIndexofAddressfromArray(currentWallet));
            _removeSpKeyfromMapping(
                _getWalletIndexfromMapping(_tokenAddress, currentWallet),
                _tokenAddress
            );
            approvedSps[_tokenAddress].push(newWallet);
            allApprovedSps.push(newWallet);
            emit BulkSpWAlletUpdated(_tokenAddress, currentWallet, newWallet);
        }
    }
}