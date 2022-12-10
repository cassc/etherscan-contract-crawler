// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";

/**
 * @title ERC721A token for DOTS
 * 
 * @dev DOTs redeemable through burning MintPassTwo tokens, earlier stage DOTS, or a combination of the two
 * 
 * @author Jack Chuma, NiftyDude
 */
contract DOTS is ERC721AQueryable, AccessControl, VRFConsumerBaseV2, OperatorFilterer {
    
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint8 constant NUM_BACKGROUND = 14;
    uint8 constant NUM_BACK = 12;
    uint8 constant NUM_PAINTJOB = 40;
    uint8 constant NUM_EYEWEAR = 31;
    uint8 constant NUM_MOUTHGEAR = 30;
    uint8 constant NUM_HEADGEAR = 40;
    uint8 constant NUM_CLOTHING = 40;
    uint8 constant NUM_EARGEAR = 20;
    uint16 constant BIT_MASK = 65535;

    IMintPassTwo immutable mintPassTwoContract;
    VRFCoordinatorV2Interface immutable COORDINATOR;

    string uri;
    bytes32 keyHash;
    uint64 subscriptionId;
    bool addApprovedContractsDisabled;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;

    mapping(uint256 => uint256[]) public currentEvoDots; // evo # => tokenIds
    mapping(uint256 => Evo) public evoData; // evo # => evo info
    mapping(uint256 => Metadata) metadata; // tokenId => Metadata
    mapping(uint256 => bool) randomEntropies; // traitset => rolled
    mapping(uint256 => AnomalyRoll) public anomalyRolls;
    mapping(address => bool) public approvedContracts;

    struct AnomalyRoll {
        uint64 evoStage;
        uint64 anomalyAmount;
    }

    struct Evo {
        uint8 numTokensNeeded;
        uint32 startWindow;
        uint32 endWindow;
    }

    struct Metadata {
        uint8 evoNum;
        uint64 genes;
        uint8 anomalyNum;
    }

    error ValueTooHigh();
    error LengthMismatch();
    error MintWindowClosed();
    error NotOwnedBySender();
    error CannotBurnPrimaryToken();
    error MustIncludeAmount();
    error MustUpgradeEvoStage();
    error MustIncludeDotsToUpgrade();
    error BurnedEvoStageHigherThanTargetEvo();
    error TokenDoesNotExist();
    error InsufficientBaseAmount();
    error AddPreapprovedContractDisabled();
    error EvoDoesNotExist();

    event UriUpdated(string uri);
    event KeyHashSet(bytes32 keyhash);
    event CallbackGasLimitSet(uint256 limit);
    event RequestConfirmationsSet(uint256 confirmations);
    event SubscriptionIdSet(uint256 id);
    event ContractApprovalUpdated(address contractToUpdate, bool enabled);
    event AddingPreapprovedContractsDisabled(bool isDisabled);
    event DOTUpgraded(
        uint256 indexed tokenId, 
        uint256 indexed newEvoNum,
        uint256[] tokenIdsBurned,
        uint256 mintPassTwoBurns
    );
    event DotsUpgraded(
        uint256[] tokenIds,
        uint256 indexed newEvoNum,
        uint256 mintPassTwoBurns,
        uint256[] tokenIdsBurned
    );
    event DOTMinted(
        uint256 indexed tokenId, 
        uint256 indexed evoNum, 
        uint256 genes,
        uint256 mintPassTwoBurns
    );
    event EvoDataBatchUpdated(
        uint256[] evoNum, 
        uint256[] numTokensNeeded, 
        uint256[] startWindows, 
        uint256[] endWindows
    );
    event AnomalyRolled(
        uint256 indexed tokenId,
        uint256 indexed anomalyNum
    );

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _uri,
        address _mintPassTwo,
        Evo[] memory _evoData,
        address adminWallet,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _registrant
    ) 
        ERC721A(_name, _symbol) 
        VRFConsumerBaseV2(_vrfCoordinator) 
        OperatorFilterer(_registrant, true) 
    {

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;

        uri = _uri;
        mintPassTwoContract = IMintPassTwo(_mintPassTwo);

        for (uint i=0; i<_evoData.length; ) {
            evoData[i + 1] = _evoData[i];
            unchecked { i++; }
        }

        _setupRole(DEFAULT_ADMIN_ROLE, adminWallet);
        _setupRole(ADMIN_ROLE, address(0xfd64b63D4A54e6b1a0Aa88e6623046c54F960D00));
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(ADMIN_ROLE) {
        keyHash = _keyHash;
        emit KeyHashSet(_keyHash);
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyRole(ADMIN_ROLE) {
        callbackGasLimit = _callbackGasLimit;
        emit CallbackGasLimitSet(_callbackGasLimit);
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyRole(ADMIN_ROLE) {
        requestConfirmations = _requestConfirmations;
        emit RequestConfirmationsSet(_requestConfirmations);
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyRole(ADMIN_ROLE) {
        subscriptionId = _subscriptionId;
        emit SubscriptionIdSet(_subscriptionId);
    }

    /**
     * @notice Called by contract admin to update stored data for a batch of EVO stages
     * @dev All input arrays must be arrays of same length
     * @param _evoNums Array of EVO stages to update data for
     * @param _numTokensNeeded Array representing new values for each edited EVO stage
     * @param _startWindows Array representing new startWindows for each edited EVO stage
     * @param _endWindows Array representing new endWindows for each edited EVO stage
     */
    function editEvoDataBatch(
        uint256[] calldata _evoNums,
        uint256[] calldata _numTokensNeeded,
        uint256[] calldata _startWindows,
        uint256[] calldata _endWindows
    ) external onlyRole(ADMIN_ROLE) {
        if (
            _evoNums.length != _numTokensNeeded.length || 
            _evoNums.length != _startWindows.length || 
            _evoNums.length != _endWindows.length
        ) revert LengthMismatch();

        for (uint i = 0; i < _evoNums.length; ) {
            evoData[_evoNums[i]] = Evo(uint8(_numTokensNeeded[i]), uint32(_startWindows[i]), uint32(_endWindows[i]));
            unchecked {  ++i; }
        }

        emit EvoDataBatchUpdated(_evoNums, _numTokensNeeded, _startWindows, _endWindows);
    }

    /**
     * @notice Called by contract admin to set a new base URI for DOTS
     */
    function setURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        uri = _uri;
        emit UriUpdated(_uri);
    }

    /**
     * @notice Called by contract admin to add / remove an approved contract
     * @param _approvedContract Contract address to add / remove
     * @param _enable Boolean value representing if contract should be enabled
     */
    function changeApprovedContract(
        address _approvedContract,
        bool _enable
    ) external onlyRole(ADMIN_ROLE) {
        if(addApprovedContractsDisabled && _enable) revert AddPreapprovedContractDisabled();
        approvedContracts[_approvedContract] = _enable;
        emit ContractApprovalUpdated(_approvedContract, _enable);
    } 

    /**
     * @notice Called by contact admin to disable adding new approved contracts
     */
    function irrevocablyDisableAddingPreapprovedContracts() external onlyRole(ADMIN_ROLE) {
        addApprovedContractsDisabled = true;
        emit AddingPreapprovedContractsDisabled(true);
    }

    /**
     * @notice admin function to initiate VRF transaction for anomaly distribution
     * @param _evoStage min evo stage for token to participate
     * @param _anomalyAmount amount of anomalies to distribute
     */
    function rollAnomalyDots(
        uint64 _evoStage,
        uint64 _anomalyAmount
    ) external onlyRole(ADMIN_ROLE) {
        if(currentEvoDots[_evoStage].length < _anomalyAmount) {
            revert InsufficientBaseAmount();
        }

        uint256 _requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          1
        );

        anomalyRolls[_requestId] = AnomalyRoll({
            evoStage: _evoStage,
            anomalyAmount: _anomalyAmount
        });
    }

    /**
     * @notice callback to retrieve random number for anomaly distribution
     * @param _requestId id of the request made by rollAnomalyDots
     * @param _randomWords the actual random number
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        AnomalyRoll memory anomalyRoll = anomalyRolls[_requestId];
        uint256[] memory _currentEvoIds = currentEvoDots[anomalyRoll.evoStage];

        uint256 _nonce;
        uint256 _numAssigned;
        uint256 _tempAnomalyToken;
        uint256 _hashForAnomalyNum;
        uint256 _anomalyNum;

        while (_numAssigned < anomalyRoll.anomalyAmount) {
            _tempAnomalyToken = _currentEvoIds[uint256(keccak256(abi.encodePacked(_randomWords[0], _nonce))) % _currentEvoIds.length];

            if(metadata[_tempAnomalyToken].anomalyNum == 0) {
                _hashForAnomalyNum = uint256(keccak256(abi.encodePacked(_randomWords[0], _tempAnomalyToken))) % 100;

                if (_hashForAnomalyNum < 10) _anomalyNum = 1;
                else if (_hashForAnomalyNum < 55) _anomalyNum = 2;
                else _anomalyNum = 3;

                metadata[_tempAnomalyToken].anomalyNum = uint8(_anomalyNum);

                unchecked { _numAssigned++; }

                emit AnomalyRolled(_tempAnomalyToken, _anomalyNum);
            }

            unchecked { _nonce++; }               
        }
    } 

    /**
     * @notice Function to mint any EVO stage solely from burning correct number of MintPassTwo's
     * @dev Must be during proper mint window
     * @dev User must have enough MintPassTwo's in their wallet for burn
     * @dev Generates traits for dot
     * @param _evoNum EVO # to mint
     * @param _numDots Number of DOTs to mint
     */
    function mint(
        uint256 _evoNum, 
        uint256 _numDots
    ) external {
        _internalMint(_evoNum, _numDots, msg.sender);
    }
    
    /**
     * @notice Admin function to mint dots to a specified address
     */
    function mintTo(
        address _to,
        uint256 _evoNum, 
        uint256 _numDots
    ) external onlyRole(ADMIN_ROLE) {
        _internalMint(_evoNum, _numDots, _to);
    }

    /**
     * @notice For upgrading a DOT to a later EVO stage
     * @dev User must own at least one DOT to call this
     * @dev Any combination of DOTs and MintPassTwo's can be used to sum to value required for target EVO stage
     * @param _primaryTokenId Token ID of DOT to upgrade
     * @param _targetEvoNum EVO stage to upgrade to
     * @param _tokenIds Array of DOT token IDs to burn as part of the upgrade
     */
    function upgrade(
        uint256 _primaryTokenId, 
        uint256 _targetEvoNum, 
        uint256[] calldata _tokenIds
    ) external {
        Evo memory _info = evoData[_targetEvoNum];
        uint256 _oldEvoNum = metadata[_primaryTokenId].evoNum;
        _checkMintWindow(_info.startWindow, _info.endWindow);
        if (ownerOf(_primaryTokenId) != msg.sender) revert NotOwnedBySender();
        if (_targetEvoNum <= _oldEvoNum) revert MustUpgradeEvoStage();

        currentEvoDots[_targetEvoNum].push(_primaryTokenId);

        uint256 _diff;
        uint256 _valueFromDots;
        unchecked { 
            _valueFromDots = evoData[_oldEvoNum].numTokensNeeded 
                + _burnDots(_primaryTokenId, _tokenIds); 
        }

        if (_valueFromDots > _info.numTokensNeeded) revert ValueTooHigh();
        unchecked { _diff = _info.numTokensNeeded - _valueFromDots; }
        if (_diff > 0) mintPassTwoContract.burnFromRedeem(msg.sender, _diff);

        metadata[_primaryTokenId].evoNum = uint8(_targetEvoNum);
        emit DOTUpgraded(_primaryTokenId, _targetEvoNum, _tokenIds, _diff);
    }

    /**
     * @notice For upgrading multiple DOTs in a single transaction
     * @param _primaryTokenIds Array of tokenIds of DOTs being upgraded
     * @param _targetEvoNum EVO stage that `_primaryTokenIds` are being upgraded to
     * @param _tokenIdsToBurn Array of tokenIds of DOTs being burned as part of upgrade
     */
    function upgradeMultiple(
        uint256[] calldata _primaryTokenIds,
        uint256 _targetEvoNum,
        uint256[] calldata _tokenIdsToBurn
    ) external {
        Evo memory _info = evoData[_targetEvoNum];
        _checkMintWindow(_info.startWindow, _info.endWindow);

        uint256 _diff;
        uint256 _valueFromDots;
        uint256 _totalValueNeeded;

        unchecked { 
            _totalValueNeeded = _info.numTokensNeeded * _primaryTokenIds.length;
            _valueFromDots = _validateAndUpgradePrimaryTokenIds(
                _primaryTokenIds,
                _targetEvoNum
            ) + _burnDotsUpgradeMultiple(_primaryTokenIds, _tokenIdsToBurn, _targetEvoNum);
        }

        if (_valueFromDots > _totalValueNeeded) revert ValueTooHigh();
        unchecked { _diff = _totalValueNeeded - _valueFromDots; }
        if (_diff > 0) mintPassTwoContract.burnFromRedeem(msg.sender, _diff);

        emit DotsUpgraded(
            _primaryTokenIds, 
            _targetEvoNum, 
            _diff,
            _tokenIdsToBurn 
        );
    }

    function burn(uint256 _tokenId) public {
        delete metadata[_tokenId];
        _burn(_tokenId, true);
    }

    function burnFromApprovedContract(
        uint256 _tokenId
    ) external {
        if(!approvedContracts[msg.sender]) revert TransferCallerNotOwnerNorApproved();

        delete metadata[_tokenId];
        _burn(_tokenId);
    }  

    function tokenURI(uint256 _id) public view override(ERC721A, IERC721A) returns (string memory) {
        return string(abi.encodePacked(uri, Strings.toString(_id)));
    }

    function getMetadata(uint256 tokenId) external view returns (Metadata memory _data) {
        _data = metadata[tokenId];
        if (_data.evoNum == 0) revert TokenDoesNotExist();
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721A, IERC721A, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || 
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721AQueryable).interfaceId ||
               interfaceId == type(IERC721A).interfaceId ||
               interfaceId == 0x80ac58cd ||
               interfaceId == 0x5b5e139f;     
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _internalMint(
        uint256 _evoNum, 
        uint256 _numDots,
        address _to
    ) private {
        if (_numDots == 0) revert MustIncludeAmount();
        Evo memory _info = evoData[_evoNum];
        _checkMintWindow(_info.startWindow, _info.endWindow);
        mintPassTwoContract.burnFromRedeem(msg.sender, _info.numTokensNeeded * _numDots);
        uint256 _tokenId = _nextTokenId();

        for (uint i=0; i<_numDots; ) {
            if (_evoNum > 1) currentEvoDots[_evoNum].push(_tokenId);
            uint256 _genes = _generateTraits();
            metadata[_tokenId] = Metadata(uint8(_evoNum), uint64(_genes), uint8(0));
            randomEntropies[_genes >> 8] = true;
            emit DOTMinted(_tokenId, _evoNum, _genes, _info.numTokensNeeded);
            unchecked { 
                i++; 
                _tokenId++;
            }
        }
        _mint(_to, _numDots);
    }

    function _normalize(
        uint256 _rand
    ) private pure returns (uint256 _normalized) {
        uint256 _traitNumSelector = _rand & uint256(BIT_MASK);
        uint256[8] memory _traitIds = [
            _getId(_rand, uint256(16), uint256(65534), NUM_BACKGROUND),
            _getId(_rand, uint256(32), uint256(65532), NUM_BACK),
            _getId(_rand, uint256(48), uint256(65520), NUM_PAINTJOB),
            _getId(_rand, uint256(64), uint256(65534), NUM_EYEWEAR),
            _getId(_rand, uint256(80), uint256(65520), NUM_MOUTHGEAR),
            _getId(_rand, uint256(96), uint256(65520), NUM_HEADGEAR),
            _getId(_rand, uint256(112), uint256(65520), NUM_CLOTHING),
            _getId(_rand, uint256(128), uint256(65520), NUM_EARGEAR)
        ];

        if (_traitIds[5] == 35) _traitIds[7] = 0;

        _normalized =
            (_traitIds[0] << 0 |
            _traitIds[1] << 8 |
            _traitIds[2] << 16 |
            _traitIds[3] << 24 |
            _traitIds[4] << 32 |
            _traitIds[5] << 40 |
            _traitIds[6] << 48 |
            _traitIds[7] << 56)
            & _generateMask(_traitNumSelector);
    }

    function _getId(
        uint256 _rand, 
        uint256 _offset,
        uint256 _cutoff,
        uint256 _options
    ) private pure returns (uint256 _id) {
        uint256 _slice = (_rand & (uint256(BIT_MASK) << _offset)) >> _offset;
        while (_slice >= _cutoff) {
            _slice = uint256(uint16(uint256(keccak256(abi.encodePacked(_slice)))));
        }
        unchecked { _id = _slice % _options + 1; }
    }

    function _generateMask(uint256 _selector) private pure returns (uint256 _mask) {
        uint256 _eightBitMask = uint256(255);
        _mask = uint256(4294967295);
        if (_selector > 1637) {
            if (_selector < 24575) {
                if (_selector < 9322) _mask = _mask | _eightBitMask << 48;
                else if (_selector < 16891) _mask = _mask | _eightBitMask << 40;
                else if (_selector < 24460) _mask = _mask | _eightBitMask << 32;
                else _mask = _mask | _eightBitMask << 56;
            } else if (_selector < 57343) {
                if (_selector < 37551) _mask = _mask | _eightBitMask << 40 | _eightBitMask << 48;
                else if (_selector < 53771) _mask = _mask | _eightBitMask << 32 | _eightBitMask << 48;
                else if (_selector < 54066)  _mask = _mask | _eightBitMask << 48 | _eightBitMask << 56;
                else if (_selector < 57277) _mask = _mask | _eightBitMask << 32 | _eightBitMask << 40;
                else if (_selector < 57306) _mask = _mask | _eightBitMask << 40 | _eightBitMask << 56;
                else _mask = _mask | _eightBitMask << 32 | _eightBitMask << 56;
            } else if (_selector < 63897) {
                if (_selector < 62974) _mask = _mask | _eightBitMask << 32 | _eightBitMask << 40 | _eightBitMask << 48;
                else if (_selector < 63257) _mask = _mask | _eightBitMask << 40 | _eightBitMask << 48 | _eightBitMask << 56;
                else if (_selector < 63568) _mask = _mask | _eightBitMask << 32 | _eightBitMask << 48 | _eightBitMask << 56;
                else _mask = _mask | _eightBitMask << 32 | _eightBitMask << 40 | _eightBitMask << 56;
            } else _mask = _mask | _mask << 32;
        }
    }

    function _burnDots(
        uint256 _primaryTokenId, 
        uint256[] calldata _tokenIdsToBurn
    ) private returns (uint256 _value) {
        for (uint i=0; i<_tokenIdsToBurn.length; ) {
            uint256 _tokenId = _tokenIdsToBurn[i];
            if (_tokenId == _primaryTokenId) revert CannotBurnPrimaryToken();
            unchecked { 
                _value += evoData[metadata[_tokenId].evoNum].numTokensNeeded;
                i++;
            }
            burn(_tokenId);
        }
    }

    function _burnDotsUpgradeMultiple(
        uint256[] calldata _primaryTokenIds, 
        uint256[] calldata _tokenIdsToBurn,
        uint256 _targetEvoNum
    ) private returns (uint256 _value) {
        if (_primaryTokenIds.length == 0) revert MustIncludeDotsToUpgrade();
        for (uint i=0; i<_tokenIdsToBurn.length; ) {
            uint256 _tokenId = _tokenIdsToBurn[i];
            uint256 _evoNum = metadata[_tokenId].evoNum;
            if (_valueInArray(_tokenId, _primaryTokenIds)) revert CannotBurnPrimaryToken();
            if (_evoNum >= _targetEvoNum) revert BurnedEvoStageHigherThanTargetEvo();
            burn(_tokenId);
            unchecked { 
                _value += evoData[_evoNum].numTokensNeeded;
                i++; 
            }
        }
    }

    function _valueInArray(
        uint256 _value, 
        uint256[] calldata _arr
    ) private pure returns (bool) {
        for (uint i=0; i<_arr.length; ) {
            if (_arr[i] == _value) return true;
            unchecked { i++; }
        }
        return false;
    }

    function _validateAndUpgradePrimaryTokenIds(
        uint256[] calldata _primaryTokenIds, 
        uint256 _targetEvoNum
    ) private returns (uint256 _value) {
        for (uint i=0; i<_primaryTokenIds.length; ) {
            uint256 _primaryTokenId = _primaryTokenIds[i];
            uint256 _oldEvoNum = metadata[_primaryTokenId].evoNum;
            if (ownerOf(_primaryTokenId) != msg.sender) revert NotOwnedBySender();
            if (_targetEvoNum <= _oldEvoNum) revert MustUpgradeEvoStage();
            currentEvoDots[_targetEvoNum].push(_primaryTokenId);
            metadata[_primaryTokenId].evoNum = uint8(_targetEvoNum);
            unchecked { 
                _value += evoData[_oldEvoNum].numTokensNeeded;
                i++; 
            }
        }
    }

    function _generateTraits() private view returns (uint256 _genes) {
        uint256 _rand;

        unchecked { 
            _rand = uint256(
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                msg.sender, tx.origin, gasleft(), block.timestamp, block.number, blockhash(block.number), blockhash(block.number-100)
                            )
                        )
                    )
                )
            );
        }

        while (true) {
            _genes = _normalize(_rand);
            if (!randomEntropies[_genes >> 8]) break;
            _rand = uint256(keccak256(abi.encodePacked(_rand)));
        }
    }

    function _checkMintWindow(uint256 _start, uint256 _end) private view {
        if (_end == 0) revert EvoDoesNotExist();
        if ((block.timestamp < _start || block.timestamp > _end) && !hasRole(ADMIN_ROLE, msg.sender)) revert MintWindowClosed();
    }
}

interface IMintPassTwo {
    function burnFromRedeem(address _account, uint256 _amount) external;
}