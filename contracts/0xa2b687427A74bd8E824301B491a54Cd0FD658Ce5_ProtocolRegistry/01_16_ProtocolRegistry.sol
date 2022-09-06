// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ProtocolBase.sol";

contract ProtocolRegistry is ProtocolBase {
    uint256 public govPlatformFee;
    uint256 public govAutosellFee;
    uint256 public govThresholdFee;

    // stable coin address enable or disable in protocol registry
    mapping(address => bool) public approveStable;

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isAddTokenRole(admin),
            "GovProtocolRegistry: msg.sender not add token admin."
        );
        _;
    }
    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isEditTokenRole(admin),
            "GovProtocolRegistry: msg.sender not edit token admin."
        );
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();
        require(
            IAdminRegistry(adminRegistry).isAddSpAccess(admin),
            "GovProtocolRegistry: No admin right to add Strategic Partner"
        );
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isEditSpAccess(admin),
            "GovProtocolRegistry: No admin right to update or remove Strategic Partner"
        );
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
        govPlatformFee = 150; //1.5 %
        govAutosellFee = 200; //2 % in Calculate APY FEE Function
        govThresholdFee = 200; //2 %
    }

    /// @dev function to set the address provider contract
    /// @param _addressProvider contract address provider
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev function to enable or disale stable coin in the gov protocol
    /// @param _stableAddress stable token contract address DAI, USDT, etc...
    /// @param _status bool value true or false to change status of stable coin
    function addEditStableCoin(
        address[] memory _stableAddress,
        bool[] memory _status
    ) external onlyEditTokenRole(msg.sender) {
        require(
            _stableAddress.length == _status.length,
            "GPR: length mismatch"
        );
        for (uint256 i = 0; i < _stableAddress.length; i++) {
            require(_stableAddress[i] != address(0x0), "GPR: null address");
            require(
                approveStable[_stableAddress[i]] != _status[i],
                "GPR: already in desired state"
            );
            approveStable[_stableAddress[i]] = _status[i];

            emit UpdatedStableCoinStatus(_stableAddress[i], _status[i]);
        }
    }

    /** external functions of the Gov Protocol Contract */

    /// @dev function to add token to approvedTokens mapping
    /// @param _tokenAddress of the new token Address
    /// @param marketData struct of the _tokenAddress

    function addTokens(
        address[] memory _tokenAddress,
        Market[] memory marketData
    ) external onlyAddTokenRole(msg.sender) {
        require(
            _tokenAddress.length == marketData.length,
            "GPR: Token Address Length must match Market Data"
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(_tokenAddress[i] != address(0x0), "GPR: null error");
            //checking Token Contract have not already added
            require(
                !this.isTokenApproved(_tokenAddress[i]),
                "GPR: already added Token Contract"
            );
            _addToken(_tokenAddress[i], marketData[i]);
        }
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _marketData struct to update the token market

    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external onlyEditTokenRole(msg.sender) {
        require(
            _tokenAddress.length == _marketData.length,
            "GPR: Token Address Length must match Market Data"
        );

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenApproved(_tokenAddress[i]),
                "GPR: cannot update the token data, add new token address first"
            );

            _updateToken(_tokenAddress[i], _marketData[i]);
            emit TokensUpdated(_tokenAddress[i], _marketData[i]);
        }
    }

    /// @dev function which change the approved token to enable or disable
    /// @param _tokenAddress address which is updating

    function changeTokensStatus(
        address[] memory _tokenAddress,
        bool[] memory _tokenStatus
    ) external onlyEditTokenRole(msg.sender) {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenEnabledForCreateLoan(_tokenAddress[i]) !=
                    _tokenStatus[i],
                "GPR: already in desired status"
            );

            approvedTokens[_tokenAddress[i]]
                .isTokenEnabledAsCollateral = _tokenStatus[i];

            emit TokenStatusUpdated(_tokenAddress[i], _tokenStatus[i]);
        }
    }

    /// @dev add sp wallet to the mapping approvedSps
    /// @param _tokenAddress token contract address
    /// @param _walletAddress sp wallet address to add

    function addSp(address _tokenAddress, address _walletAddress)
        external
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            !_isAlreadyAddedSp(_walletAddress),
            "GPR: SP Already Approved"
        );
        _addSp(_tokenAddress, _walletAddress);
    }

    /// @dev remove sp wallet from mapping
    /// @param _tokenAddress token address as a key to remove sp
    /// @param _removeWalletAddress sp wallet address to be removed

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external
        onlyEditSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            _isAlreadyAddedSp(_removeWalletAddress),
            "GPR: cannot remove the SP, does not exist"
        );

        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (approvedSps[_tokenAddress][i] == _removeWalletAddress) {
                _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
            }
        }

        emit SPWalletRemoved(_tokenAddress, _removeWalletAddress);
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );

        _addBulkSps(_tokenAddress, _walletAddress);
    }

    /// @dev function to update the sp wallet
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _oldWalletAddress old wallet address to be updated
    /// @param _newWalletAddress new wallet address

    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(_newWalletAddress != _oldWalletAddress, "GPR: same wallet for update not allowed");
        require(
            _isAlreadyAddedSp(_oldWalletAddress),
            "GPR: cannot update the wallet address, wallet address not exist or not a SP"
        );

        _updateSp(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /// @dev external function update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        _updateBulkSps(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            address removeWallet = _removeWalletAddress[i];
            require(
                _isAlreadyAddedSp(removeWallet),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            // delete approvedSps[_tokenAddress][i];
            //remove SP key from the mapping
            _removeSpKey(_getIndexofAddressfromArray(removeWallet));

            //also remove SP key from specific token address
            _removeSpKeyfromMapping(
                _getIndexofAddressfromArray(_tokenAddress),
                _tokenAddress
            );
        }
    }

    /** Public functions of the Gov Protocol Contract */

    /// @dev get all approved tokens from the allapprovedTokenContracts
    /// @return address[] returns all the approved token contracts
    function getallApprovedTokens() external view returns (address[] memory) {
        return allapprovedTokenContracts;
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    /// @return Market market data for the approved token address
    function getSingleApproveToken(address _tokenAddress)
        external
        view
        override
        returns (Market memory)
    {
        return approvedTokens[_tokenAddress];
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
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
        return (
            approvedTokens[_tokenAddress].gToken,
            approvedTokens[_tokenAddress].isMint,
            uint256(approvedTokens[_tokenAddress].tokenType)
        );
    }

    /// @dev function to check if sythetic mint option is on for the approved collateral token
    /// @param _tokenAddress collateral token address
    /// @return bool returns the bool value true or false
    function isSyntheticMintOn(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP &&
            approvedTokens[_tokenAddress].isMint;
    }

    /// @dev get all approved Sp wallets
    /// @return address[] returns the approved stragetic partner addresses
    function getAllApprovedSPs() external view returns (address[] memory) {
        return allApprovedSps;
    }

    /// @dev get wallet addresses of single tokenAddress
    /// @param _tokenAddress sp token address
    /// @return address[] returns the wallet addresses of the sp token
    function getSingleTokenSps(address _tokenAddress)
        external
        view
        override
        returns (address[] memory)
    {
        return approvedSps[_tokenAddress];
    }

    /// @dev set the percentage of the Gov Platform Fee to the Gov Lend Market Contracts
    /// @param _percentage percentage which goes to the gov platform

    function setGovPlatfromFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govPlatformFee = _percentage;
        emit GovPlatformFeeUpdated(_percentage);
    }

    /// @dev set the liquiation thershold percentage
    function setThresholdFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 5000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govThresholdFee = _percentage;
        emit ThresholdFeeUpdated(_percentage);
    }

    /// @dev set the autosell apy fee percentage
    /// @param _percentage percentage value of the autosell fee
    function setAutosellFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govAutosellFee = _percentage;
        emit AutoSellFeeUpdated(_percentage);
    }

    /// @dev get the gov platofrm fee percentage
    function getGovPlatformFee() external view override returns (uint256) {
        return govPlatformFee;
    }

    function getTokenMarket()
        external
        view
        override
        returns (address[] memory)
    {
        return allapprovedTokenContracts;
    }

    function getThresholdPercentage() external view override returns (uint256) {
        return govThresholdFee;
    }

    function getAutosellPercentage() external view override returns (uint256) {
        return govAutosellFee;
    }


    function isStableApproved(address _stable)
        external
        view
        override
        returns (bool)
    {
        return approveStable[_stable];
    }
}