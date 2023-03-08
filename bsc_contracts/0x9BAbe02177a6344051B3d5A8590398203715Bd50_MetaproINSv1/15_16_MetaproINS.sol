//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";
import "./libraries/Royalty.sol";
import "./libraries/Referral.sol";

contract MetaproINSv1 is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    struct INSConfiguration {
        // @dev: nft token id
        uint256 tokenId;
        // @dev: price per 1 nft token - value in busd
        uint256 pricePerToken;
        // @dev: INS starting block
        uint256 startBlock;
        // @dev: INS ending block
        uint256 endBlock;
        // @dev: INS min token deposits - value in NFT token
        uint256 minCap;
        // @dev: INS max token deposits - value in NFT token
        uint256 maxCap;
        // @dev: INS min token deposits - value in BUSD
        uint256 minCapInBusd;
        // @dev: INS max token deposits - value in BUSD
        uint256 maxCapInBusd;
        // @dev: Allow principants to do multiple deposits per INS
        bool multipleDeposits;
        // @dev: INS creator
        address operator;
        // @dev: Current capacity in BUSD
        uint256 currentCapInBusd;
        // @dev: Current capacity in token quantity
        uint256 currentCap;
        // @dev: INS validity - value in boolean
        bool valid;
        // @dev: INS id
        uint256 insId;
    }

    struct TokenIns {
        uint256 tokenId;
        address tokenContractAddress;
    }

    struct WalletIns {
        uint256 insId;
        bool finalized;
    }

    struct INSDeposit {
        // @dev: principal wallet address
        address wallet;
        // @dev: deposit amount in busd
        uint256 amount;
        // @dev: deposit finished state
        bool finished;
        // @dev: deposit blockNumber
        uint256 blockNumber;
    }

    // Contracts
    IERC20 public busd;
    MetaproReferral public metaproReferral;
    MetaproRoyalty public metaproRoyalty;

    //Contract addresses
    address private busdAddress;
    address private referralAddress;
    address private royaltyAddress;
    address public tressuryAddress;

    // @dev: Current created INS
    mapping(uint256 => INSConfiguration) public availableIns;

    // @dev: dictionary with ins token quantity for withdraw/giveBack purposes
    mapping(uint256 => uint256) private insTokenQuantity;

    // @dev: dictionary with ins deposits amount for withdraw/giveBack purposes
    mapping(uint256 => uint256) private insBalance;

    mapping(uint256 => bool) private operatorWithdrawed;
    // @dev: dictionary with ins token contract address insId -> insTokenContractAddress ERC1155
    mapping(uint256 => address) private insTokenContractAddress;

    // @dev: dictionary with insId => Referral.ReferralFees
    mapping(uint256 => Referral.ReferralFees) public insReferralFees;

    // @dev: dictionary with insId => Royalty.RoyaltyTeamMember[]
    mapping(uint256 => Royalty.RoyaltyTeamMember[])
        public insRoyaltyTeamMembers;

    // @dev: Tressury fee - interger value - example: 500 -> 5%
    uint256 public treasuryFee = 500; // 500 = 5%

    // @dev: dictionary with principants deposits - token_id => deposits
    mapping(uint256 => INSDeposit[]) private insDeposits;

    // @dev: dictionary with WalletIns[] - wallet address => WalletIns[]
    mapping(address => WalletIns[]) private walletIns;

    // @dev: list of created ins ids
    uint256[] private createdInsIds;

    // @dev: list of active ins token ids
    TokenIns[] private activeInsTokenIds;

    // @dev: list of finished ins token ids
    TokenIns[] private finishedInsTokenIds;

    // @dev: dictionary with alreadyCompletedIns state
    mapping(uint256 => bool) private alreadyCompletedIns;

    uint256 private currentInsId = 1;

    event Deposit(
        uint256 _tokenId,
        uint256 _insId,
        address _target,
        uint256 _amount
    );

    event OperatorGiveBack(
        uint256 _insId,
        address _target,
        uint256 _tokenAmount
    );
    event OperatorWithdraw(
        uint256 _insId,
        address _target,
        uint256 _earnings,
        uint256 _tokenAmount
    );
    event DepositorGiveBack(
        uint256 _insId,
        address _target,
        uint256 _tokenAmount
    );
    event DepositorWithdraw(
        uint256 _insId,
        address _target,
        uint256 _tokenAmount
    );

    event BUSDAddressUpdated(address _address);
    event TokenAddressUpdated(address _address);
    event TressuryAddressUpdated(address _address);
    event ReferralAddressUpdated(address _address);
    event RoyaltyAddressUpdated(address _address);

    event INSComplete(uint256 insId, uint256 _tokenId);
    event TreasuryFeeUpdated(uint256 _fee);
    event INSCreated(
        address tokenContractAddress,
        uint256 tokenId,
        uint256 insId,
        uint256 minCap,
        uint256 maxCap,
        uint256 pricePerToken,
        uint256 startBlock,
        uint256 endBlock,
        bool multipleDeposits
    );

    constructor(
        address _busdAddress,
        address _tressuryAddress,
        address _referralAddress,
        address _royaltyAddress
    ) {
        busd = IERC20(_busdAddress);
        tressuryAddress = _tressuryAddress;
        metaproReferral = MetaproReferral(_referralAddress);
        referralAddress = _referralAddress;
        metaproRoyalty = MetaproRoyalty(_royaltyAddress);
        royaltyAddress = _royaltyAddress;
    }

    function create(
        address _tokenContractAddress,
        uint256 _tokenId,
        uint256 _minCap,
        uint256 _maxCap,
        uint256 _pricePerToken,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _multipleDeposits,
        uint256 _level1ReferralFee,
        uint256 _level2ReferralFee,
        uint256 _level3ReferralFee,
        bytes memory _data
    ) external nonReentrant returns (uint256) {
        // Check if provided tokenContractAddress is valid
        require(
            Address.isContract(_tokenContractAddress),
            "INS: provide a valid ERC1155 contract address"
        );
        // Check if provided tokenId is valid
        require(
            _tokenId > 0,
            "INS: invalid tokenId, value must be positive number"
        );
        // Check if pricePerToken in positive
        require(
            _pricePerToken > 0,
            "INS: pricePerToken must be greater than 0"
        );
        // Check if minCap is greater or equal to maxCap
        require(
            _minCap <= _maxCap,
            "INS: maxCap must be greater or equal than minCap"
        );
        // Check is sum of referral fees is valid
        require(
            _level1ReferralFee.add(_level2ReferralFee).add(
                _level3ReferralFee
            ) <= 1500,
            "INS: the sum of referral fees can not be greater than 15%"
        );
        // Check is balance of a given ERC1155 token is valid
        require(
            IERC1155(_tokenContractAddress).balanceOf(msg.sender, _tokenId) >=
                _maxCap,
            "INS: insufficient ERC1155 balance, the value must be at least equal to maxCap"
        );

        require(
            _startBlock < _endBlock,
            "INS: startBlock must be lower than endBlock"
        );

        IERC1155(_tokenContractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _maxCap,
            _data
        );

        INSConfiguration memory configuration = INSConfiguration(
            _tokenId,
            _pricePerToken,
            _startBlock,
            _endBlock,
            _minCap,
            _maxCap,
            _minCap * _pricePerToken,
            _maxCap * _pricePerToken,
            _multipleDeposits,
            msg.sender,
            0,
            0,
            true,
            currentInsId
        );

        insTokenContractAddress[currentInsId] = _tokenContractAddress;

        saveInsReferralFees(
            _level1ReferralFee,
            _level2ReferralFee,
            _level3ReferralFee
        );

        saveInsRoyaltyFees(currentInsId, _tokenId);

        availableIns[currentInsId] = configuration;

        // Saves ins token quantity needed for the further operations
        insTokenQuantity[configuration.insId] = configuration.maxCap;

        //Activate tokenId
        activateTokenId(_tokenId, _tokenContractAddress);
        // Add insId to wallet
        addInsToWallet(configuration.insId, msg.sender);

        emit INSCreated(
            _tokenContractAddress,
            _tokenId,
            currentInsId,
            _minCap,
            _maxCap,
            _pricePerToken,
            _startBlock,
            _endBlock,
            _multipleDeposits
        );

        currentInsId++;

        return currentInsId - 1;
    }

    function saveInsReferralFees(
        uint256 _level1ReferralFee,
        uint256 _level2ReferralFee,
        uint256 _level3ReferralFee
    ) private {
        Referral.ReferralFees memory feesConfig = Referral.ReferralFees(
            _level1ReferralFee,
            _level2ReferralFee,
            _level3ReferralFee
        );
        insReferralFees[currentInsId] = feesConfig;
    }

    function saveInsRoyaltyFees(uint256 _insId, uint256 _tokenId) private {
        Royalty.RoyaltyTeamMember[] memory teamMembers = metaproRoyalty
            .getTeamMembers(_tokenId, insTokenContractAddress[_insId]);

        Royalty.RoyaltyTeamMember[]
            storage royaltyInsFees = insRoyaltyTeamMembers[_insId];

        for (uint256 i = 0; i < teamMembers.length; ++i) {
            royaltyInsFees.push(teamMembers[i]);
        }
    }

    function deposit(
        uint256 insId,
        uint256 _quantity,
        address _referrer
    ) external nonReentrant {
        require(insId > 0, "INS: insId must be a positive number");

        INSConfiguration storage configuration = availableIns[insId];

        require(
            configuration.valid,
            "INS: ins configuration not found or ins is finished"
        );

        require(
            block.number >= configuration.startBlock,
            "INS: ins not started"
        );

        require(block.number <= configuration.endBlock, "INS: ins is finished");

        require(_quantity > 0, "INS: quantity must be greater than 0");

        if (configuration.maxCapInBusd != 0) {
            require(
                configuration.currentCap < configuration.maxCap,
                "INS: Cap full"
            );
            uint256 availableCap = configuration.maxCap -
                configuration.currentCap;
            require(
                _quantity <= availableCap,
                "INS: amount exceeds available ins cap"
            );
        }

        INSDeposit memory walletDeposit = INSDeposit(
            msg.sender,
            _quantity.mul(configuration.pricePerToken),
            false,
            block.number
        );

        uint256 transactionAmount = _quantity.mul(configuration.pricePerToken);

        if (configuration.multipleDeposits) {
            busd.transferFrom(msg.sender, address(this), transactionAmount);
            insDeposits[insId].push(walletDeposit);
        } else {
            INSDeposit[] memory _insDeposits = insDeposits[insId];
            bool deposited = false;
            for (uint256 i = 0; i < _insDeposits.length; ++i) {
                if (_insDeposits[i].wallet == msg.sender) {
                    deposited = true;
                }
            }

            if (deposited) {
                revert("INS: ins doesn't support multiple deposits");
            } else {
                busd.transferFrom(msg.sender, address(this), transactionAmount);
                insDeposits[insId].push(walletDeposit);
            }
        }

        configuration.currentCapInBusd += transactionAmount;
        configuration.currentCap += _quantity;

        insBalance[insId] += transactionAmount;

        availableIns[insId] = configuration;

        metaproReferral.setReferral(msg.sender, _referrer);

        // Add insId to wallet
        addInsToWallet(configuration.insId, msg.sender);

        emit Deposit(
            configuration.tokenId,
            insId,
            msg.sender,
            transactionAmount
        );
    }

    function withdraw(uint256 _insId, bytes memory _data)
        external
        nonReentrant
    {
        require(_insId > 0, "INS: insId must be a positive number");

        INSConfiguration storage _insConfiguration = availableIns[_insId];
        Referral.ReferralFees storage _feesConfiguration = insReferralFees[
            _insId
        ];

        require(
            _insConfiguration.valid,
            "INS: ins configuration not found or ins is finished"
        );

        require(!alreadyCompletedIns[_insId], "INS: ins is already finished");
        require(
            block.number >= _insConfiguration.endBlock ||
                _insConfiguration.maxCap == _insConfiguration.currentCap ||
                block.number < _insConfiguration.startBlock,
            "INS: ins is in progress or max cap is not reached"
        );

        bool canWidtraw = false;
        if (_insConfiguration.operator == msg.sender) {
            canWidtraw = true;
        } else {
            for (uint256 i = 0; i < insDeposits[_insId].length; i++) {
                INSDeposit memory currentDeposit = insDeposits[_insId][i];
                if (currentDeposit.wallet == msg.sender) {
                    canWidtraw = true;
                }
            }
        }

        require(
            canWidtraw,
            "INS: You must be operator of the token or one of user that deposited funds"
        );

        bool isInsOperator = msg.sender == _insConfiguration.operator;

        if (_insConfiguration.minCap != 0) {
            // Ins is not completed - deposited tokens will be returned to all depositers
            if (_insConfiguration.currentCap < _insConfiguration.minCap) {
                if (isInsOperator)
                    processOperatorGiveBack(_insConfiguration, _data);
                else processDepositorGiveBack(_insConfiguration);

                // Ins is completed - token will be distributed through depositers
            } else {
                if (isInsOperator)
                    processOperatorWithdraw(
                        _insConfiguration,
                        insBalance[_insId],
                        _feesConfiguration,
                        insDeposits[_insId],
                        _data
                    );
                else
                    processDepositorWithdraw(
                        _insConfiguration,
                        _feesConfiguration,
                        _data
                    );
            }
        } else {
            if (isInsOperator)
                processOperatorWithdraw(
                    _insConfiguration,
                    insBalance[_insId],
                    _feesConfiguration,
                    insDeposits[_insId],
                    _data
                );
            else
                processDepositorWithdraw(
                    _insConfiguration,
                    _feesConfiguration,
                    _data
                );
        }

        finalizeInsByWallet(_insId, msg.sender);

        if (
            insTokenQuantity[_insConfiguration.insId] == 0 &&
            insBalance[_insId] == 0
        ) {
            finalizeTokenId(
                _insConfiguration.tokenId,
                insTokenContractAddress[_insId],
                _insId
            );
            _insConfiguration.valid = false;
            alreadyCompletedIns[_insId] = true;
            emit INSComplete(_insId, _insConfiguration.tokenId);
        }
    }

    function emergencyInsWithdraw(uint256 _insId, bytes memory _data)
        external
        onlyOwner
    {
        INSConfiguration storage _insConfiguration = availableIns[_insId];

        require(
            _insConfiguration.insId != 0,
            "INS: insId configuration not found"
        );

        uint256 busdBalance = insBalance[_insId];
        uint256 tokenBalance = insTokenQuantity[_insId];

        if (busdBalance > 0) {
            busd.transfer(msg.sender, busdBalance);
            insBalance[_insId] = 0;
        }
        if (tokenBalance > 0) {
            IERC1155(insTokenContractAddress[_insId]).safeTransferFrom(
                address(this),
                msg.sender,
                _insConfiguration.tokenId,
                tokenBalance,
                _data
            );
            insTokenQuantity[_insId] = 0;
        }

        for (uint256 index = 0; index < insDeposits[_insId].length; index++) {
            finalizeInsByWallet(_insId, insDeposits[_insId][index].wallet);
        }

        finalizeTokenId(
            _insConfiguration.tokenId,
            insTokenContractAddress[_insId],
            _insId
        );

        alreadyCompletedIns[_insId] = true;
        _insConfiguration.valid = false;
        emit INSComplete(_insId, _insConfiguration.tokenId);
    }

    function addInsToWallet(uint256 _insId, address _walletAddress) private {
        bool insAdded = false;
        for (uint256 i = 0; i < walletIns[_walletAddress].length; i++) {
            if (walletIns[_walletAddress][i].insId == _insId) insAdded = true;
        }
        WalletIns memory _walletIns = WalletIns({
            insId: _insId,
            finalized: false
        });
        if (!insAdded) walletIns[_walletAddress].push(_walletIns);
    }

    function finalizeInsByWallet(uint256 _insId, address _walletAddress)
        private
    {
        for (uint256 i = 0; i < walletIns[_walletAddress].length; i++) {
            if (walletIns[_walletAddress][i].insId == _insId)
                walletIns[_walletAddress][i].finalized = true;
        }
    }

    function getWalletIns(address _walletAddress)
        public
        view
        returns (WalletIns[] memory)
    {
        return walletIns[_walletAddress];
    }

    function activateTokenId(uint256 _tokenId, address _tokenContractAddress)
        private
    {
        // To avoid duplication we need to check if active _tokenId already exists
        createdInsIds.push(currentInsId);
        bool enableToActivate = true;
        for (uint256 i = 0; i < activeInsTokenIds.length; i++) {
            if (
                activeInsTokenIds[i].tokenId == _tokenId &&
                activeInsTokenIds[i].tokenContractAddress ==
                _tokenContractAddress
            ) {
                enableToActivate = false;
            }
        }

        TokenIns memory tokenIns = TokenIns(_tokenId, _tokenContractAddress);

        if (enableToActivate) {
            activeInsTokenIds.push(tokenIns);
        }

        // We need to back remove _tokenId from finished
        for (uint256 i = 0; i < finishedInsTokenIds.length; i++) {
            if (
                finishedInsTokenIds[i].tokenId == _tokenId &&
                finishedInsTokenIds[i].tokenContractAddress ==
                _tokenContractAddress
            ) {
                delete finishedInsTokenIds[i];
            }
        }
    }

    function finalizeTokenId(
        uint256 _tokenId,
        address _tokenContractAddress,
        uint256 _insId
    ) private {
        INSConfiguration[] memory tokenInsConfiguration = getTokenIns(_tokenId);
        TokenIns memory tokenIns = TokenIns(_tokenId, _tokenContractAddress);

        bool allInsForTokenIdFinalized = true;

        for (uint256 i = 0; i < tokenInsConfiguration.length; i++) {
            if (
                tokenInsConfiguration[i].valid &&
                tokenInsConfiguration[i].insId != _insId
            ) {
                allInsForTokenIdFinalized = false;
            }
        }

        if (allInsForTokenIdFinalized) {
            for (uint256 i = 0; i < activeInsTokenIds.length; i++) {
                if (
                    activeInsTokenIds[i].tokenId == _tokenId &&
                    activeInsTokenIds[i].tokenContractAddress ==
                    _tokenContractAddress
                ) {
                    delete activeInsTokenIds[i];
                    finishedInsTokenIds.push(tokenIns);
                }
            }
        }
    }

    function getInsDeposits(uint256 _insId)
        public
        view
        returns (INSDeposit[] memory)
    {
        return insDeposits[_insId];
    }

    function getInsWalletDeposits(uint256 _insId, address _walletAddress)
        public
        view
        returns (INSDeposit[] memory)
    {
        uint256 correctDepositsSize = 0;

        for (uint256 i = 0; i < insDeposits[_insId].length; i++) {
            if (insDeposits[_insId][i].wallet == _walletAddress) {
                correctDepositsSize += 1;
            }
        }

        INSDeposit[] memory correctWalletDeposits = new INSDeposit[](
            correctDepositsSize
        );

        uint256 correctIndex = 0;
        for (uint256 i = 0; i < insDeposits[_insId].length; i++) {
            if (insDeposits[_insId][i].wallet == _walletAddress) {
                correctWalletDeposits[correctIndex] = insDeposits[_insId][i];
                correctIndex++;
            }
        }

        return correctWalletDeposits;
    }

    function getActiveInsTokenIds() public view returns (TokenIns[] memory) {
        uint256 correctArraySize = 0;

        for (uint256 i = 0; i < activeInsTokenIds.length; i++) {
            if (activeInsTokenIds[i].tokenId != 0) {
                correctArraySize += 1;
            }
        }

        TokenIns[] memory activeIns = new TokenIns[](correctArraySize);

        uint256 correctIndex = 0;
        for (uint256 i = 0; i < activeInsTokenIds.length; i++) {
            if (activeInsTokenIds[i].tokenId != 0) {
                activeIns[correctIndex] = activeInsTokenIds[i];
                correctIndex++;
            }
        }

        return activeIns;
    }

    function getFinishedInsTokenIds() public view returns (TokenIns[] memory) {
        uint256 correctArraySize = 0;

        for (uint256 i = 0; i < finishedInsTokenIds.length; i++) {
            if (finishedInsTokenIds[i].tokenId != 0) {
                correctArraySize += 1;
            }
        }

        TokenIns[] memory finishedIns = new TokenIns[](correctArraySize);

        uint256 correctIndex = 0;
        for (uint256 i = 0; i < finishedInsTokenIds.length; i++) {
            if (finishedInsTokenIds[i].tokenId != 0) {
                finishedIns[correctIndex] = finishedInsTokenIds[i];
                correctIndex++;
            }
        }

        return finishedIns;
    }

    function getCreatedInsIds() public view returns (uint256[] memory) {
        return createdInsIds;
    }

    function getAllAvailableIns()
        public
        view
        returns (INSConfiguration[] memory)
    {
        INSConfiguration[] memory availableInsList = new INSConfiguration[](
            createdInsIds.length
        );
        for (uint256 i = 0; i < createdInsIds.length; i++) {
            availableInsList[i] = availableIns[createdInsIds[i]];
        }
        return availableInsList;
    }

    function getBatchIns(uint256[] memory _insIds)
        public
        view
        returns (INSConfiguration[] memory)
    {
        INSConfiguration[] memory insConfigurations = new INSConfiguration[](
            _insIds.length
        );

        for (uint256 i = 0; i < _insIds.length; i++) {
            if (availableIns[_insIds[i]].tokenId == 0) {
                revert("One of given auctionIds does not exist");
            } else {
                insConfigurations[i] = availableIns[_insIds[i]];
            }
        }

        return insConfigurations;
    }

    function getTokenIns(uint256 _tokenId)
        public
        view
        returns (INSConfiguration[] memory)
    {
        uint256 correctArraySize = 0;

        for (uint256 i = 0; i < createdInsIds.length; i++) {
            if (availableIns[createdInsIds[i]].tokenId == _tokenId) {
                correctArraySize += 1;
            }
        }

        INSConfiguration[] memory tokenIns = new INSConfiguration[](
            correctArraySize
        );

        uint256 correctIndex = 0;
        for (uint256 i = 0; i < createdInsIds.length; i++) {
            if (availableIns[createdInsIds[i]].tokenId == _tokenId) {
                tokenIns[correctIndex] = availableIns[createdInsIds[i]];
                correctIndex++;
            }
        }

        return tokenIns;
    }

    function getInsTokenContractAddress(uint256 _insId)
        public
        view
        returns (address)
    {
        return insTokenContractAddress[_insId];
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        require(_fee < 2500, "INS: Fee can't be greater than 2,5%; 2500");
        treasuryFee = _fee;
        emit TreasuryFeeUpdated(_fee);
    }

    function setBusdAddress(address _newAddress) external onlyOwner {
        busd = IERC20(_newAddress);
        emit BUSDAddressUpdated(_newAddress);
    }

    function setTressuryAddress(address _newAddress) external onlyOwner {
        tressuryAddress = _newAddress;
        emit TressuryAddressUpdated(_newAddress);
    }

    function setReferralAddress(address _newAddress) external onlyOwner {
        referralAddress = _newAddress;
        metaproReferral = MetaproReferral(_newAddress);
        emit ReferralAddressUpdated(_newAddress);
    }

    function setRoyaltyAddress(address _newAddress) external onlyOwner {
        royaltyAddress = _newAddress;
        metaproRoyalty = MetaproRoyalty(_newAddress);
        emit RoyaltyAddressUpdated(_newAddress);
    }

    function depositOnReferrer(
        uint256 _auctionId,
        address _referrer,
        address _depositer,
        uint256 _amount,
        uint256 _referralFee,
        uint256 _tokenId,
        uint256 _level
    ) private returns (uint256) {
        uint256 referralFeeAmount = _amount.mul(_referralFee).div(10000);

        busd.transfer(_referrer, referralFeeAmount);

        metaproReferral.saveReferralDeposit(
            _referrer,
            address(this),
            _auctionId,
            _tokenId,
            _depositer,
            _level,
            referralFeeAmount
        );
        return referralFeeAmount;
    }

    function calculateReferralFee(
        Referral.ReferralFees memory _insFeesConfiguration,
        uint256 _amount,
        address _depositer
    ) private view returns (uint256) {
        uint256 fee = 0;
        address level1Referrer = metaproReferral.getReferral(_depositer);
        if (level1Referrer != address(0)) {
            // Level 1
            if (_insFeesConfiguration.level1ReferrerFee > 0) {
                fee += _amount.mul(_insFeesConfiguration.level1ReferrerFee).div(
                        10000
                    );
            }
            // Level 2
            address level2Referrer = metaproReferral.getReferral(
                level1Referrer
            );
            if (level2Referrer != address(0)) {
                if (_insFeesConfiguration.level2ReferrerFee > 0) {
                    fee += _amount
                        .mul(_insFeesConfiguration.level2ReferrerFee)
                        .div(10000);
                }

                // Level 3
                address level3Referrer = metaproReferral.getReferral(
                    level2Referrer
                );
                if (level3Referrer != address(0)) {
                    if (_insFeesConfiguration.level3ReferrerFee > 0) {
                        fee += _amount
                            .mul(_insFeesConfiguration.level3ReferrerFee)
                            .div(10000);
                    }
                }
            }
        }
        return fee;
    }

    function sendFeesToReferrers(
        INSConfiguration memory _insConfiguration,
        Referral.ReferralFees memory _insFeesConfiguration,
        uint256 _amount,
        address _depositer
    ) private returns (uint256) {
        uint256 fee = 0;
        address level1Referrer = metaproReferral.getReferral(_depositer);
        if (level1Referrer != address(0)) {
            // Level 1
            if (_insFeesConfiguration.level1ReferrerFee > 0) {
                uint256 level1Fee = depositOnReferrer(
                    _insConfiguration.insId,
                    level1Referrer,
                    _depositer,
                    _amount,
                    _insFeesConfiguration.level1ReferrerFee,
                    _insConfiguration.tokenId,
                    1
                );

                fee += level1Fee;
            }
            // Level 2
            address level2Referrer = metaproReferral.getReferral(
                level1Referrer
            );
            if (level2Referrer != address(0)) {
                if (_insFeesConfiguration.level2ReferrerFee > 0) {
                    uint256 level2Fee = depositOnReferrer(
                        _insConfiguration.insId,
                        level2Referrer,
                        _depositer,
                        _amount,
                        _insFeesConfiguration.level2ReferrerFee,
                        _insConfiguration.tokenId,
                        2
                    );

                    fee += level2Fee;
                }

                // Level 3
                address level3Referrer = metaproReferral.getReferral(
                    level2Referrer
                );
                if (level3Referrer != address(0)) {
                    if (_insFeesConfiguration.level3ReferrerFee > 0) {
                        uint256 level3Fee = depositOnReferrer(
                            _insConfiguration.insId,
                            level3Referrer,
                            _depositer,
                            _amount,
                            _insFeesConfiguration.level3ReferrerFee,
                            _insConfiguration.tokenId,
                            3
                        );
                        fee += level3Fee;
                    }
                }
            }
        }
        return fee;
    }

    function sendFeesToRoyaltyTeamMembers(
        INSConfiguration memory _insConfiguration,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fee = 0;
        Royalty.RoyaltyTeamMember[]
            storage royaltyTeamMembers = insRoyaltyTeamMembers[
                _insConfiguration.insId
            ];

        for (uint256 i = 0; i < royaltyTeamMembers.length; i++) {
            Royalty.RoyaltyTeamMember memory member = royaltyTeamMembers[i];
            uint256 royaltyFee = _amount.mul(member.royaltyFee).div(10000);
            busd.transfer(member.member, royaltyFee);
            fee += royaltyFee;
        }

        return fee;
    }

    function sendEarningsToOperator(
        INSConfiguration memory _insConfiguration,
        uint256 _depositsAmountWithFees
    ) private returns (uint256) {
        busd.transfer(_insConfiguration.operator, _depositsAmountWithFees);
        return _depositsAmountWithFees;
    }

    function processOperatorGiveBack(
        INSConfiguration memory _insConfiguration,
        bytes memory _data
    ) private {
        IERC1155(insTokenContractAddress[_insConfiguration.insId])
            .safeTransferFrom(
                address(this),
                _insConfiguration.operator,
                _insConfiguration.tokenId,
                insTokenQuantity[_insConfiguration.insId],
                _data
            );

        insTokenQuantity[_insConfiguration.insId] = 0;

        emit OperatorGiveBack(
            _insConfiguration.insId,
            msg.sender,
            insTokenQuantity[_insConfiguration.insId]
        );
    }

    function processOperatorWithdraw(
        INSConfiguration memory _insConfiguration,
        uint256 _insBalance,
        Referral.ReferralFees memory _insFeesConfiguration,
        INSDeposit[] memory _insDeposits,
        bytes memory _data
    ) private {
        require(
            !operatorWithdrawed[_insConfiguration.insId],
            "INS: Ins is already withdrawed by operator"
        );

        uint256 tokensLocked = 0;
        uint256 currentInsBusdBalance = _insBalance;
        for (uint256 i = 0; i < _insDeposits.length; i++) {
            INSDeposit memory singleWalletDeposit = _insDeposits[i];
            if (singleWalletDeposit.wallet != msg.sender) {
                // Calculate tokens locked by participants
                tokensLocked += singleWalletDeposit.amount.div(
                    _insConfiguration.pricePerToken
                );
                // Calculate referral fees from deposits
                if (!singleWalletDeposit.finished) {
                    currentInsBusdBalance -= calculateReferralFee(
                        _insFeesConfiguration,
                        singleWalletDeposit.amount,
                        singleWalletDeposit.wallet
                    );
                }
            }
        }

        // Calculate treasury fee
        uint256 treasuryFeeAmount = (
            _insConfiguration.currentCapInBusd.mul(treasuryFee)
        ).div(10000);

        // Send fee to the treasury address
        busd.transfer(tressuryAddress, treasuryFeeAmount);

        // Send fee to the royalty team
        uint256 royaltyFee = sendFeesToRoyaltyTeamMembers(
            _insConfiguration,
            _insConfiguration.currentCapInBusd
        );

        uint256 operatorTokens = _insConfiguration.maxCap - tokensLocked;
        // Give back operator tokens when is something left
        if (operatorTokens != 0) {
            IERC1155(insTokenContractAddress[_insConfiguration.insId])
                .safeTransferFrom(
                    address(this),
                    _insConfiguration.operator,
                    _insConfiguration.tokenId,
                    operatorTokens,
                    _data
                );
            // Subtract ins token quantity by sent tokens to operator
            insTokenQuantity[_insConfiguration.insId] -= operatorTokens;
        }
        // Send earning to operator subtracted by all fees
        uint256 operatorEarnings = sendEarningsToOperator(
            _insConfiguration,
            currentInsBusdBalance - royaltyFee - treasuryFeeAmount
        );

        uint256 amountSent = treasuryFeeAmount.add(royaltyFee).add(
            operatorEarnings
        );
        // Subtract ins balance by sent operator earnings with
        insBalance[_insConfiguration.insId] -= amountSent;
        operatorWithdrawed[_insConfiguration.insId] = true;

        emit OperatorWithdraw(
            _insConfiguration.insId,
            msg.sender,
            operatorEarnings,
            operatorTokens
        );
    }

    function finishAndgetDeposistAmount(uint256 _insId, address participant)
        private
        returns (uint256)
    {
        INSDeposit[] storage _insDeposits = insDeposits[_insId];
        require(
            _insDeposits.length > 0,
            "INS: Participant has now deposits on this ins"
        );
        uint256 depositsAmount = 0;
        // Calculate deposits amount for msg.sender
        for (uint256 i = 0; i < _insDeposits.length; i++) {
            if (
                _insDeposits[i].wallet == participant &&
                !_insDeposits[i].finished
            ) {
                depositsAmount += _insDeposits[i].amount;
                _insDeposits[i].finished = true;
            }
        }
        return depositsAmount;
    }

    // Distribution of funds to depositor
    function processDepositorGiveBack(INSConfiguration memory _insConfiguration)
        private
    {
        INSDeposit[] storage _insDeposits = insDeposits[
            _insConfiguration.insId
        ];
        require(
            _insDeposits.length > 0,
            "INS: Participant has now deposits on this ins"
        );
        // Calculate unfinished deposits amount and finish them
        uint256 depositsAmount = finishAndgetDeposistAmount(
            _insConfiguration.insId,
            msg.sender
        );

        require(
            insBalance[_insConfiguration.insId] > 0,
            "INS: Ins is already withdrawed"
        );

        if (depositsAmount == 0) {
            revert("INS: there is no deposits on the ins");
        } else {
            // Transfer transaction
            busd.transfer(msg.sender, depositsAmount);
            // Decrease ins balance by depositor deposits amount
            insBalance[_insConfiguration.insId] -= depositsAmount;
            emit DepositorGiveBack(
                _insConfiguration.insId,
                msg.sender,
                depositsAmount
            );
        }
    }

    // Distribution of tokens to depositor
    function processDepositorWithdraw(
        INSConfiguration memory _insConfiguration,
        Referral.ReferralFees memory _insFeesConfiguration,
        bytes memory _data
    ) private {
        INSDeposit[] storage _insDeposits = insDeposits[
            _insConfiguration.insId
        ];
        require(_insDeposits.length > 0, "INS: There is no valid deposits");
        // Calculate unfinished deposits amount and finish them
        uint256 depositsAmount = finishAndgetDeposistAmount(
            _insConfiguration.insId,
            msg.sender
        );
        if (depositsAmount == 0) {
            revert("INS: there are no deposits for given wallet address");
        } else {
            // Calculate referral fees from the calculated deposits amount
            uint256 referralFees = sendFeesToReferrers(
                _insConfiguration,
                _insFeesConfiguration,
                depositsAmount,
                msg.sender
            );
            // Calculate token quantity divided
            uint256 tokenQuantity = depositsAmount.div(
                _insConfiguration.pricePerToken
            );
            IERC1155(insTokenContractAddress[_insConfiguration.insId])
                .safeTransferFrom(
                    address(this),
                    msg.sender,
                    _insConfiguration.tokenId,
                    tokenQuantity,
                    _data
                );
            // Subtract ins balance by sent referral fees
            insBalance[_insConfiguration.insId] -= referralFees;
            // Subtract ins token quantity by sent tokens
            insTokenQuantity[_insConfiguration.insId] -= tokenQuantity;
        }
    }
}