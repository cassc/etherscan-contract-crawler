// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./emitter.sol";

/// @title StationX Governance Token Contract
/// @dev Base Contract as a reference for DAO Governance Token contract proxies
contract ERC20NonTransferable is ERC20Upgradeable, AccessControl, Ownable {
    using SafeMath for uint256;

    ///@dev Admin role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    bytes32 constant operationNameAND = keccak256(abi.encodePacked(("AND")));
    bytes32 constant operationNameOR = keccak256(abi.encodePacked(("OR")));

    ///@dev flag check Admin takes fees in USDC or GT token
    bool public feeUSDC;

    ///@dev This will hold what has bean deposited till date
    mapping(address => uint256) public USDCDeposited;

    ///@dev This will hold what is transfered to admin till date
    mapping(address => uint256) public USDCTransferedToAdmin;

    ///@dev Address of Gnosis safe owning this DAO
    address public gnosisAddress;

    ///@dev amount/investment amount needed to be raised
    uint256 public totalRaiseAmount;

    ///@dev minimum amount need to be deposited by a user to become a member
    uint256 public minDepositPerUser;

    ///@dev minimum deposit a user can perform into a DAO
    uint256 public maxDepositPerUser;

    ///@dev timestamp when the deposit is closed
    uint256 public depositCloseTime;

    ///@dev fees transferred to the owner pre deposit(Creator/deployer of DAO)
    uint256 public ownerFeePerDeposit;

    ///@dev quorum of the DAO
    uint256 public quorum;

    ///@dev threshold of the DAO
    uint256 public threshold;

    ///@dev token contract address of the stable Coin USDC
    address public usdcTokenAddress;

    /// @dev balances mapping of each DAO members for governance token
    mapping(address => uint256) public balances;

    /// @dev counter to store number of proposals in a contract
    uint256 proposalCounter = 0;

    /// @dev array to store members addresses
    address[] members;

    /// @dev members mapping to manage array of address
    mapping(address => bool) membersMapping;

    ///@dev deployer/owner of the Gnosis sdk
    address public deployerAddress;

    ///@dev address of the emitter contract
    address emitterContractAddress;

    uint256 constant EIGHTEEN_DECIMALS = 10**18;

    /// Total tokens in circulation
    uint256 public totalTokensMinted = 0;

    /// Is Governance Active Boolean
    bool public isGovernanceActive = true;

    ///@dev structure of the proposal
    struct Proposals {
        string proposalHash;
        string proposalStatus;
        uint256 proposalId;
        address customTokenAddress;
        address airDropTokenAddress;
        bool[] executionIds;
        uint256 quorum;
        uint256 threshold;
        uint256 totalRaiseAmount;
        uint256 airDropAmount;
        uint256[] mintGTAmounts; // amounts array to send GT to different wallets
        address[] mintGTAddresses; // wallet’s address array where to send GT address in sync with mintGTAmounts
        uint256[] customTokenAmounts; // amounts array to send custom token to different wallets
        address[] customTokenAddresses; // wallet’s address array where to send custom token in sync with customTokenAmounts
        uint256 ownersAirdropFees;
        address[] daoAdminAddresses;
    }

    // For Multiple Token Support
    struct MultiTokensObject {
        address[] tokenList;
        mapping(address => uint256) minTokenRequired;
        mapping(uint256 => string) tokenOperations;
        mapping(address => bool) isTokenNFT;
    }

    MultiTokensObject tokenGatingInfo;

    bool public isTokenGatingApplied = false;

    /// @dev array to store proposals
    Proposals[] proposalArray;

    /// @dev onlyGnosis modifier to allow only Owner access to functions
    modifier onlyGnosis() {
        require(gnosisAddress == msg.sender, "Only Owner");
        _;
    }

    /// @dev get list of all proposals
    function getProposals() public view returns (Proposals[] memory) {
        return proposalArray;
    }

    /// @dev details of user
    function userDetails(address _userAddress)
        public
        view
        returns (
            bool,
            uint256,
            bool
        )
    {
        bool isAdmin = hasRole(ADMIN, _userAddress);
        return (membersMapping[_userAddress], balances[_userAddress], isAdmin);
    }

    /// @dev Function to update Minimum and Maximum deposits allowed by DAO members
    /// @param _minDepositPerUser New minimum deposit requirement amount in wei
    /// @param _maxDepositPerUser New maximum deposit limit amount in wei
    function updateMinMaxDeposit(
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser
    ) external {
        require(hasRole(ADMIN, msg.sender), "Only Admin");

        require(_minDepositPerUser > 0, "Min amount should be greater then 0");
        require(
            _maxDepositPerUser > _minDepositPerUser,
            "Max amount should be grater than min"
        );

        minDepositPerUser = _minDepositPerUser;
        maxDepositPerUser = _maxDepositPerUser;
        Emitter(emitterContractAddress).updateMinMaxDeposit(
            address(this),
            _minDepositPerUser,
            _maxDepositPerUser
        );
    }

    /// @dev Function to update DAO Owner Fee
    /// @param _ownerFeePerDeposit New Owner fee
    function updateOwnerFee(uint256 _ownerFeePerDeposit) external {
        require(hasRole(ADMIN, msg.sender), "Only Admin");
        require(_ownerFeePerDeposit < 100, "Owners fees cannot exceed 100");
        ownerFeePerDeposit = _ownerFeePerDeposit;

        Emitter(emitterContractAddress).updateOwnerFee(
            address(this),
            _ownerFeePerDeposit
        );
    }

    /// @dev Function to close deposit
    function closeDeposit() external {
        require(hasRole(ADMIN, msg.sender), "Only Admin");
        require(depositCloseTime > block.timestamp, "Deposit already closed");
        depositCloseTime = block.timestamp;
        Emitter(emitterContractAddress).closeDeposit(
            address(this),
            block.timestamp
        );
    }

    /// @dev function to check deposit is enabled or disabled
    function checkDeposit() public view returns (bool) {
        if (block.timestamp < depositCloseTime) return true;
        else return false;
    }

    /// @dev Function to start deposit
    /// @param _days New close date
    function startDeposit(uint256 _days) external {
        require(hasRole(ADMIN, msg.sender), "Only Admin");
        require(_days > 0, "Days should be grater than 0");
        require(depositCloseTime < block.timestamp, "Deposit already started");

        depositCloseTime = block.timestamp.add(_days.mul(86400));

        Emitter(emitterContractAddress).startDeposit(
            address(this),
            block.timestamp,
            depositCloseTime
        );
    }

    /// @dev Function to setup multiple token checks to gate community
    /// @param _tokenList List of tokens to use to gate community
    /// @param _minTokenRequired Minimum amount of each tokens required
    /// @param _tokenOperations Operations to perform the check
    /// @param _isTokenNFT List of boolean values if or not the token in token list is NFT
    function setupTokenGating(
        address[] calldata _tokenList,
        uint256[] calldata _minTokenRequired,
        string[] calldata _tokenOperations,
        bool[] calldata _isTokenNFT
    ) external onlyGnosis {
        require(_tokenList.length < 5, "Does not support more than 4 tokens");

        require(
            _tokenList.length == _minTokenRequired.length,
            "Incorrect parameters passed"
        );

        require(
            _tokenList.length == _tokenOperations.length + 1,
            "Incorrect parameters passed"
        );

        require(
            _tokenList.length == _isTokenNFT.length,
            "Incorrect parameters passed"
        );

        tokenGatingInfo.tokenList = _tokenList;

        for (uint8 i = 0; i < _tokenList.length; i++) {
            tokenGatingInfo.minTokenRequired[_tokenList[i]] = _minTokenRequired[
                i
            ];
            tokenGatingInfo.tokenOperations[i] = _tokenOperations[i];
            tokenGatingInfo.isTokenNFT[_tokenList[i]] = _isTokenNFT[i];
        }

        isTokenGatingApplied = true;
    }

    function disableTokenGating() external onlyGnosis {
        isTokenGatingApplied = false;
    }

    function getGatingTokenList() public view returns (address[] memory) {
        return tokenGatingInfo.tokenList;
    }

    function getGatingTokenOperations(uint8 _i)
        public
        view
        returns (string memory)
    {
        return tokenGatingInfo.tokenOperations[_i];
    }

    function getGatingTokenRequired(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return tokenGatingInfo.minTokenRequired[_tokenAddress];
    }

    function getGatingTokenIsNFT(address _tokenAddress)
        public
        view
        returns (bool)
    {
        return tokenGatingInfo.isTokenNFT[_tokenAddress];
    }

    /// @dev Function to deposit USDC by DAO members and assign equivalent Governance token to members after owner fee
    /// @param _usdcTokenAddress USDC Contract Address
    /// @param _totalAmount USDC amount to deposit
    function deposit(address _usdcTokenAddress, uint256 _totalAmount) external {
        require(depositCloseTime > block.timestamp, "Deposit Closed");
        require(_usdcTokenAddress == usdcTokenAddress, "Only USDC allowed");
        require(
            _totalAmount >= minDepositPerUser,
            "Amount less than min criteria"
        );
        require(
            _totalAmount <= maxDepositPerUser,
            "Amount greater than max criteria"
        );

        bool finalCheck = true;

        if (isTokenGatingApplied) {
            address tokenAddress1 = tokenGatingInfo.tokenList[0];
            uint256 tokenBalance1;

            if (tokenGatingInfo.isTokenNFT[tokenAddress1]) {
                tokenBalance1 = ERC721(tokenAddress1).balanceOf(msg.sender);
            } else {
                tokenBalance1 = ERC20(tokenAddress1).balanceOf(msg.sender);
            }

            bool check1 = tokenBalance1 >=
                tokenGatingInfo.minTokenRequired[tokenAddress1];

            for (uint8 i = 1; i < tokenGatingInfo.tokenList.length - 1; i++) {
                address tokenAddress2 = tokenGatingInfo.tokenList[i + 1];
                uint256 tokenBalance2;
                if (tokenGatingInfo.isTokenNFT[tokenAddress2]) {
                    tokenBalance2 = ERC721(tokenAddress2).balanceOf(msg.sender);
                } else {
                    tokenBalance2 = ERC20(tokenAddress2).balanceOf(msg.sender);
                }

                bool check2 = tokenBalance2 >=
                    tokenGatingInfo.minTokenRequired[tokenAddress2];

                bytes32 tokenOperation = keccak256(
                    abi.encodePacked(tokenGatingInfo.tokenOperations[i - 1])
                );

                if (tokenOperation == operationNameAND) {
                    finalCheck = check1 && check2;
                } else if (tokenOperation == operationNameOR) {
                    finalCheck = check1 || check2;
                }

                if (i < tokenGatingInfo.tokenList.length - 1) {
                    check1 = finalCheck;
                }
            }
        }

        require(finalCheck, "Token Gating Checks Failed");

        uint256 daoBalance = ERC20(_usdcTokenAddress).balanceOf(address(this));

        daoBalance += _totalAmount;

        require(
            daoBalance < totalRaiseAmount,
            "DAO exceeded total raise amount"
        );

        uint256 adminShareUsdc = (_totalAmount.mul(ownerFeePerDeposit)).div(
            100
        );
        uint256 userShareUsdc = _totalAmount.sub(adminShareUsdc);

        uint256 customTokenDecimals = ERC20(_usdcTokenAddress).decimals();
        uint256 customTokenConversion = 1 * 10**customTokenDecimals;

        uint256 totalGtTokens = (_totalAmount.mul(EIGHTEEN_DECIMALS)).div(
            customTokenConversion
        );
        uint256 userShareGt = (userShareUsdc.mul(EIGHTEEN_DECIMALS)).div(
            customTokenConversion
        );

        if (membersMapping[msg.sender] == false) {
            members.push(msg.sender);
            membersMapping[msg.sender] = true;
        }

        if (feeUSDC) {
            USDCDeposited[_usdcTokenAddress] += userShareUsdc;
            ERC20(_usdcTokenAddress).transferFrom(
                msg.sender,
                address(this),
                userShareUsdc
            );
            USDCTransferedToAdmin[_usdcTokenAddress] += adminShareUsdc;
            ERC20(_usdcTokenAddress).transferFrom(
                msg.sender,
                deployerAddress,
                adminShareUsdc
            );
            mintToken(msg.sender, totalGtTokens);
            balances[msg.sender] = balances[msg.sender].add(totalGtTokens);

            Emitter(emitterContractAddress).deposited(
                address(this),
                msg.sender,
                _usdcTokenAddress,
                _totalAmount,
                block.timestamp,
                ownerFeePerDeposit,
                adminShareUsdc,
                feeUSDC
            );

            Emitter(emitterContractAddress).newUser(
                address(this),
                msg.sender,
                _usdcTokenAddress,
                _totalAmount,
                block.timestamp,
                totalGtTokens,
                false
            );
        } else {
            USDCDeposited[_usdcTokenAddress] += _totalAmount;
            ERC20(_usdcTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _totalAmount
            );
            mintToken(msg.sender, userShareGt);
            mintToken(deployerAddress, (totalGtTokens.sub(userShareGt)));
            balances[msg.sender] = balances[msg.sender].add(userShareGt);
            balances[deployerAddress] = balances[deployerAddress].add(
                totalGtTokens.sub(userShareGt)
            );

            Emitter(emitterContractAddress).deposited(
                address(this),
                msg.sender,
                _usdcTokenAddress,
                _totalAmount,
                block.timestamp,
                ownerFeePerDeposit,
                totalGtTokens.sub(userShareGt),
                feeUSDC
            );

            Emitter(emitterContractAddress).newUser(
                address(this),
                msg.sender,
                _usdcTokenAddress,
                _totalAmount,
                block.timestamp,
                totalGtTokens.sub(userShareGt),
                false
            );
        }
    }

    /// @dev function to execute the proposal
    /// @param params the structure of the proposal
    function updateProposalAndExecution(Proposals memory params)
        external
        onlyGnosis
    {
        if (params.executionIds[0] == true) {
            airDropToken(
                params.airDropTokenAddress,
                params.airDropAmount,
                params.ownersAirdropFees
            );
        }
        if (params.executionIds[1] == true) {
            mintGTToAddress(params.mintGTAmounts, params.mintGTAddresses);
        }
        if (params.executionIds[2] == true) {
            updateGovernanceSettings(params.quorum, params.threshold);
        }
        if (params.executionIds[3] == true) {
            updateRaiseAmount(params.totalRaiseAmount);
        }
        if (params.executionIds[4] == true) {
            sendCustomToken(
                params.customTokenAddress,
                params.customTokenAmounts,
                params.customTokenAddresses
            );
        }
        if (params.executionIds[5] == true) {
            addDaoAdmin(params.daoAdminAddresses);
        }
        proposalArray.push(params);
        proposalCounter += 1;
    }

    function addDaoAdmin(address[] memory _daoAdminAddresses) internal {
        require(_daoAdminAddresses.length > 0, "Invalid address parameters");

        for (uint256 i = 0; i < _daoAdminAddresses.length; i++) {
            if (membersMapping[_daoAdminAddresses[i]] == false) {
                members.push(_daoAdminAddresses[i]);
                membersMapping[_daoAdminAddresses[i]] = true;
            }
            _setupRole(ADMIN, _daoAdminAddresses[i]);
        }

        Emitter(emitterContractAddress).daoAdminsAdded(
            address(this),
            _daoAdminAddresses,
            usdcTokenAddress
        );
    }

    /// @dev function to send the custom token
    /// @param _customTokenAddress is the token contract address
    /// @param _amountArray array of amount to be transferred
    /// @param _addresses array of address where the amount should be transferred
    function sendCustomToken(
        address _customTokenAddress,
        uint256[] memory _amountArray,
        address[] memory _addresses
    ) internal {
        require(_amountArray.length == _addresses.length, "Invalid parameters");

        uint256 _minimumRequired = 0;
        for (uint256 j = 0; j < _amountArray.length; j++) {
            _minimumRequired = _minimumRequired.add(_amountArray[j]);
        }

        require(
            _minimumRequired <=
                ERC20(_customTokenAddress).balanceOf(address(this)),
            "Insufficient funds"
        );

        for (uint256 i = 0; i < _amountArray.length; i++) {
            ERC20(_customTokenAddress).transfer(_addresses[i], _amountArray[i]);
        }

        Emitter(emitterContractAddress).sendCustomToken(
            address(this),
            _customTokenAddress,
            _amountArray,
            _addresses
        );
    }

    /// @dev function to mint GT token to a addresses
    /// @param _amountArray array of amount to be transferred
    /// @param _userAddress array of address where the amount should be transferred
    function mintGTToAddress(
        uint256[] memory _amountArray,
        address[] memory _userAddress
    ) internal {
        require(
            _amountArray.length == _userAddress.length,
            "Invalid parameters"
        );

        for (uint256 i = 0; i < _amountArray.length; i++) {
            mintToken(_userAddress[i], _amountArray[i]);
            if (membersMapping[_userAddress[i]] == false) {
                members.push(_userAddress[i]);
                membersMapping[_userAddress[i]] = true;

                Emitter(emitterContractAddress).newUser(
                    address(this),
                    _userAddress[i],
                    usdcTokenAddress,
                    0,
                    block.timestamp,
                    _amountArray[i],
                    false
                );
            }

            balances[_userAddress[i]] = balances[_userAddress[i]].add(
                _amountArray[i]
            );
        }

        Emitter(emitterContractAddress).mintGTToAddress(
            address(this),
            _amountArray,
            _userAddress
        );
    }

    /// @dev function to update governance settings
    /// @param _quorum update quorum into the contract
    /// @param _threshold update threshold into the contract
    function updateGovernanceSettings(uint256 _quorum, uint256 _threshold)
        internal
    {
        require(_quorum > 0, "Quorum should be greater than 0");
        require(_threshold > 0, "Threshold should be greater than 0");

        require(_quorum <= 100, "Quorum should be less than 100");
        require(_threshold <= 100, "Threshold should be less than 100");

        quorum = _quorum;
        threshold = _threshold;

        Emitter(emitterContractAddress).updateGovernanceSettings(
            address(this),
            _quorum,
            _threshold
        );
    }

    /// @dev function to perform airdrop
    /// @param _airdropTokenAddress contract address of token for which airdrop is conducted
    /// @param _airdropAmount total amount to conduct airdrop
    /// @param _ownersAirdropFees the fees owner is charging for the airdrop
    function airDropToken(
        address _airdropTokenAddress,
        uint256 _airdropAmount,
        uint256 _ownersAirdropFees
    ) internal {
        require(_ownersAirdropFees < 100, "Owner fees should be less than 100");
        require(_ownersAirdropFees >= 0, "Owner cannot be less than 0");

        uint256 _holdings = ERC20(_airdropTokenAddress).balanceOf(
            address(this)
        );

        require(_holdings >= _airdropAmount, "Insufficient funds for airdrop");

        uint256 _updatedAmount;
        if (_ownersAirdropFees == 0) {
            _updatedAmount = _airdropAmount;
        } else {
            uint256 _deployerShare = ((_airdropAmount).mul(_ownersAirdropFees))
                .div(100);
            ERC20(_airdropTokenAddress).transfer(
                deployerAddress,
                _deployerShare
            );
            _updatedAmount = _airdropAmount.sub(_deployerShare);
        }

        for (uint256 i = 0; i < members.length; i++) {
            uint256 _dropAmount = (balanceOf(members[i]).mul(_updatedAmount))
                .div(totalTokensMinted);
            ERC20(_airdropTokenAddress).transfer(members[i], _dropAmount);
        }

        Emitter(emitterContractAddress).airDropToken(
            address(this),
            _airdropTokenAddress,
            _airdropAmount,
            _ownersAirdropFees
        );
    }

    /// @dev function to update governance settings
    /// @param _totalRaiseAmount update the total amount in DAO
    function updateRaiseAmount(uint256 _totalRaiseAmount) internal {
        require(_totalRaiseAmount > 0, "Amount should be grater than 0");
        totalRaiseAmount = _totalRaiseAmount;

        Emitter(emitterContractAddress).updateRaiseAmount(
            address(this),
            _totalRaiseAmount
        );
    }

    /// @dev Function to give Governance details
    /// @return  depositCloseTime, minDepositPerUser, maxDepositPerUser, members count, quorum
    function getGovernorDetails()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            depositCloseTime,
            minDepositPerUser,
            maxDepositPerUser,
            quorum,
            totalRaiseAmount,
            members.length
        );
    }

    /// @dev Function to give Members details
    /// @return  members addresses list
    function getMembersDetails() external view returns (address[] memory) {
        return members;
    }

    /// @dev Function to give Members details
    /// @return  members addresses list
    function getMembersBalances()
        external
        view
        returns (uint256[] memory, address[] memory)
    {
        uint256[] memory _balances = new uint256[](members.length);

        for (uint256 i = 0; i < members.length; i++) {
            _balances[i] = balances[members[i]];
        }

        return (_balances, members);
    }

    /// @dev Function to give user balance
    /// @return  uint256 user balance
    function checkUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @dev Function to change governance active
    function updateGovernanceActive(bool _isGovernanceActive)
        external
        onlyGnosis
    {
        isGovernanceActive = _isGovernanceActive;
    }

    /// @dev initialize Function to initialize Token contract
    /// @param _name reflect the name of Governance Token
    /// @param _symbol reflect the symbol of Governance Token
    /// @param _totalDeposit total deposit to be conducted
    /// @param _minDeposit min deposit a user can make into DAO
    /// @param _maxDeposit max deposit a user can make into DAO
    /// @param _ownerFee fee of owner 0-100
    /// @param _days number of days DAO will be open to accept deposit
    /// @param _feeUSDC boolean to check admin takes fees in USDC or Governance token
    /// @param _quorum reflect the symbol of Governance Token
    /// @param _threshold reflect the symbol of Governance Token
    /// @param _gnosisAddress reflect the symbol of Governance Token
    /// @param _USDC reflect the symbol of Governance Token
    function initializeERC20(
        string calldata _name,
        string calldata _symbol,
        uint256 _totalDeposit,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _ownerFee,
        uint256 _days,
        bool _feeUSDC,
        uint256 _quorum,
        uint256 _threshold,
        address _gnosisAddress,
        address _USDC,
        address _emitter,
        address[] memory _daoAdmins,
        bool _isGovernanceActive
    ) public initializer {
        require(_minDeposit > 0, "Min deposit should be grater than 0");
        require(_maxDeposit > 0, "Max deposit should be grater than 0");
        require(
            _maxDeposit > _minDeposit,
            "Amount should be grater than min amount"
        );

        require(
            _totalDeposit > _maxDeposit,
            "Total raise amount should be grater than max amount"
        );

        require(_quorum > 0, "Quorum should be greater than 0");
        require(_quorum <= 100, "Quorum should be less then or equal to 100");

        require(_threshold > 0, "Threshold should be greater than 0");
        require(
            _threshold <= 100,
            "Threshold should be less then or equal to 100"
        );

        require(_days > 0, "Days cannot be 0");

        require(_ownerFee >= 0, "Owner fee cannot be less than 0");
        require(_ownerFee < 100, "Owner fee cannot exceed 100");

        require(_gnosisAddress != address(0), "Owner cannot be null");

        require(_USDC != address(0), "USDC cannot be null");

        totalRaiseAmount = _totalDeposit;
        minDepositPerUser = _minDeposit;
        maxDepositPerUser = _maxDeposit;
        depositCloseTime = block.timestamp.add(_days.mul(86400));
        ownerFeePerDeposit = _ownerFee;
        gnosisAddress = _gnosisAddress;
        feeUSDC = _feeUSDC;
        quorum = _quorum;
        threshold = _threshold;
        usdcTokenAddress = _USDC;
        emitterContractAddress = _emitter;
        deployerAddress = tx.origin;
        membersMapping[tx.origin] = true;
        isGovernanceActive = _isGovernanceActive;

        for (uint256 i = 0; i < _daoAdmins.length; i++) {
            _setupRole(ADMIN, _daoAdmins[i]);
            membersMapping[_daoAdmins[i]] = true;
            members.push(_daoAdmins[i]);
        }

        __ERC20_init(_name, _symbol);
    }

    /// @dev Function to give Governance Token  details
    /// @return token name, symbol and total supply
    function tokenDetails()
        external
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        return (name(), symbol(), totalSupply());
    }

    function getUsdcDetails(address _tokenAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            USDCDeposited[_tokenAddress],
            USDCTransferedToAdmin[_tokenAddress]
        );
    }

    function stableCoinDecimals() public view returns (uint8) {
        return ERC20(usdcTokenAddress).decimals();
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @dev Function to override transfer to restrict token transfers
    function transfer(address, uint256) public pure override returns (bool) {
        require(false, "TOKENS NON-TRANSFERABLE");
        return true;
    }

    /// @dev Function to override transferFrom to restrict token transfers
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        require(false, "TOKENS NON-TRANSFERABLE");
        return true;
    }

    /// @dev Function to mint Governance Token and assign delegate
    /// @param to Address to which tokens will be minted
    /// @param amount Value of tokens to be minted based on deposit by DAO member
    function mintToken(address to, uint256 amount) internal {
        _mint(to, amount);
        totalTokensMinted = totalTokensMinted.add(amount);
    }

    /// @dev Function to burn Governance Token
    /// @param account Address from where token will be burned
    /// @param amount Value of tokens to be burned
    function burnToken(address account, uint256 amount) internal {
        _burn(account, amount);
    }

    /// @dev Internal function that needs to be override
    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }
}