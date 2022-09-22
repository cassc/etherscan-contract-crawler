// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./FeePoolUpgradeable.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalkUpgradeable.sol";
import "./BridgeStorage.sol";
import "./BridgeUtilsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeUpgradeable is Initializable, OwnableUpgradeable, RouterCrossTalkUpgradeable, BridgeStorage {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;

    FeePoolUpgradeable public feePoolUpgradeable;

    BridgeUtilsUpgradeable public bridgeUtilsUpgradeable;

    // struct LiquidityPosition {
    //     uint256 depositedAmount;
    //     uint256 blockNo;
    //     uint256 claimedTillEpochIndex;
    //     uint256 epochStartIndex;
    //     uint256 epochStartBlock;
    //     uint256 boosterEndEpochIndex;
    //     uint256 startTimestamp;
    // }

    // // tokenTicker => userAddress => index => LiquidityPosition
    // mapping(string => mapping(address => mapping(uint256 => LiquidityPosition))) public liquidityPosition;
    // // tokenTicker => userAddress => index => epochIndex => hasBooster
    // mapping(string => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public hasBooster;
    // // tokenTicker => userAddress => index
    // mapping(string => mapping(address => uint256)) public currentIndex;
    // // tokenTicker => totalLiquidity
    // mapping(string => uint256) public totalLiquidity;
    // // tokenTicker => epochIndex => totalBoostedUsers
    // mapping(string => mapping(uint256 => uint256)) public totalBoostedUsers;

    // // to create a mapping for verifying the cross chain transfer
    // // struct TransferMapping {
    // //     address userAddress;
    // //     uint256 noOfTokens;
    // // }
    // // tokenTicker => index => TransferMapping
    // // mapping(string => mapping(uint256 => TransferMapping)) public transferMapping;
    // // tokenTicker => userAddress => destChain => index => noOfTokens
    // mapping(string => mapping(address => mapping(uint8 => mapping(uint256 => uint256)))) public transferMapping;

    // // unique for each transfer mapping
    // // tokenTicker => userAddress => destChain => index
    // mapping(string => mapping(address => mapping(uint8 => uint256))) public currentTransferIndex;

    // struct Epoch {
    //     uint256 startBlock;
    //     uint256 epochLength;
    //     uint256 totalFeesCollected;
    //     uint256 totalActiveLiquidity;
    //     uint256 noOfDepositors;
    // }
    // // tokenTicker => Epoch[]
    // mapping(string => Epoch[]) public epochs;

    // // to recalculate the fees and totalLiquidity once epoch ends
    // // (updated on the first call after epoch ends)
    // // ticker => nextEpochBlock
    // mapping(string => uint256) public nextEpochBlock;

    // // mapping(string => uint256) public adminClaimedTillEpoch;

    // // minimum fee can be 0.1% (= 1 bip), so 100% = 1000bips (=maxBips)
    // uint256 public maxBips;

    // uint256 public crossChainGas;

    // struct BoosterConfig {
    //     // uint8 tokenType;
    //     address tokenAddress;
    //     uint256 price;
    //     string imageUrl;
    //     address adminAccount;
    // }
    // BoosterConfig public boosterConfig;

    // uint8 public chainId;

    event LiquidityAdded(
        uint256 indexed index,
        address indexed account,
        string tokenTicker,
        // string tokenName,
        // string imageUrl,
        uint256 noOfTokens
        // uint256 blockTimestamp
    );

    event LiquidityRemoved(
        uint256 indexed index,
        address indexed account,
        string tokenTicker
    );

    event BridgeTransactionInit(
        uint256 transferIndex,
        uint256 toChainId,
        address account,
        string tokenTicker,
        // string tokenName,
        // string imageUrl,
        uint256 noOfTokens
    );

    event BridgeTransactionEnd(
        uint256 transferIndex,
        uint256 fromChainId,
        uint256 toChainId,
        address account,
        string tokenTicker,
        uint8 status
    );

    modifier isBridgeActive(string memory _tokenTicker) {
        _isBridgeActive(_tokenTicker);
        _;
    }

    function _isBridgeActive(string memory _tokenTicker) internal view {
        require(tokenBridgeRegistryUpgradeable.isBridgeActive() 
            && bridgeUtilsUpgradeable.isTokenBridgeActive(_tokenTicker), "BRIDGE_DISABLED");
    }

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable,
        address _genericHandler,
        uint8 _chainId
    ) public initializer {
        __Ownable_init();
        __RouterCrossTalkUpgradeable_init(_genericHandler);
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        chainId = _chainId;
        maxBips = 1000;
        crossChainGas = 1000000;
    }

    function updateRegistryAddress(TokenBridgeRegistryUpgradeable _registryAddress) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _registryAddress;
    }
    
    function updateFeePoolAddress(FeePoolUpgradeable _feePoolAddress) external onlyOwner {
        feePoolUpgradeable = _feePoolAddress;
    }

    function updateBridgeUtilsAddress(BridgeUtilsUpgradeable _bridgeUtilsAddress) external onlyOwner {
        bridgeUtilsUpgradeable = _bridgeUtilsAddress;
    }

    function updateMaxBips(uint256 _newMaxBips) external onlyOwner {
        maxBips = _newMaxBips;
    }

    function updateCrossChainGas(uint256 _newGasAmount) external onlyOwner {
        crossChainGas = _newGasAmount;
    }

    function setLinker(address _linker) external onlyOwner  {
        setLink(_linker);
    }
 
    function setFeeTokenAddress(address _feeAddress) external onlyOwner {
        setFeeToken(_feeAddress);
    }

    function approveRouterFee(address _feeToken, uint256 _value) external onlyOwner  {
        approveFees(_feeToken, _value);
    }

    function getToken(string memory _tokenTicker) public view returns (TokenUpgradeable) {
        address tokenAddress = bridgeUtilsUpgradeable.getTokenAddress(_tokenTicker);
        require(tokenAddress != address(0), "INVALID_TOKEN");
        TokenUpgradeable token = TokenUpgradeable(tokenAddress);
        return token;
    }

    // function getTokenTotalLiquidity(string calldata tokenTicker) public view returns (uint256) {
    //     return totalLiquidity[tokenTicker];
    // }

    // function getUserTotalDeposit(
    //     string calldata tokenTicker,
    //     address account,
    //     uint256 index
    // ) public view returns (uint256) {
    //     return liquidityPosition[tokenTicker][account][index].depositedAmount;
    // }

    function updateBoosterConfig(
        address _adminAccount,
        address _boosterToken,
        uint256 _perBoosterPrice,
        string calldata _imageUrl
    ) external onlyOwner {
        boosterConfig = BoosterConfig({
            tokenAddress: _boosterToken,
            price: _perBoosterPrice,
            imageUrl: _imageUrl,
            adminAccount: _adminAccount
        });
    }

    function buyBoosterPacks(
        string calldata _tokenTicker,
        uint256 _index,
        uint256 _quantity
    ) public isBridgeActive(_tokenTicker) {
        TokenUpgradeable boosterToken = TokenUpgradeable(boosterConfig.tokenAddress);
        boosterToken.transferFrom(_msgSender(), boosterConfig.adminAccount, boosterConfig.price * _quantity);

        // adding any passed epochs
        addPassedEpochs(_tokenTicker);

        uint256 currentEpochIndex = epochs[_tokenTicker].length + 1;
        LiquidityPosition storage position = liquidityPosition[_tokenTicker][_msgSender()][_index];
        if(position.boosterEndEpochIndex >= currentEpochIndex) {
            updateBoosterMapping(_tokenTicker, _index, _quantity, position.boosterEndEpochIndex + 1, position.depositedAmount, true);
            position.boosterEndEpochIndex += _quantity;
        }
        else {
            updateBoosterMapping(_tokenTicker, _index, _quantity, currentEpochIndex, position.depositedAmount, true);
            position.boosterEndEpochIndex = currentEpochIndex + _quantity - 1;
        }
    }

    // function addBoosterMapping(
    //     string calldata _tokenTicker,
    //     uint256 _index,
    //     uint256 _quantity,
    //     uint256 epoch
    // ) internal {
    //     for (uint256 epochIndex = epoch ; epochIndex <= epoch + _quantity - 1; epochIndex++) {
    //         hasBooster[_tokenTicker][_msgSender()][_index][epochIndex] = true;
    //         ++totalBoostedUsers[_tokenTicker][epochIndex];
    //     }
    // }

    function updateBoosterMapping(
        string calldata _tokenTicker,
        uint256 _index,
        uint256 _quantity,
        uint256 epoch,
        uint256 _tokenAmount,
        bool _isAddingLiquidity
    ) internal {
        for (uint256 epochIndex = epoch ; epochIndex <= epoch + _quantity - 1; epochIndex++) {
            if(_isAddingLiquidity) {
                hasBooster[_tokenTicker][_msgSender()][_index][epochIndex] = true;
                totalBoostedLiquidity[_tokenTicker][epochIndex] += _tokenAmount;
            }
            else {
                delete hasBooster[_tokenTicker][_msgSender()][_index][epochIndex];
                totalBoostedLiquidity[_tokenTicker][epochIndex] -= _tokenAmount;
            }
        }
    }

    function initNextEpochBlock(
        string memory _tokenTicker,
        uint256 epochLength
    ) public {
        require(_msgSender() == address(tokenBridgeRegistryUpgradeable), "ONLY_REGISTRY");
        nextEpochBlock[_tokenTicker] = block.number + epochLength - 1;
    }

    function calculatePassedEpoch(string memory _tokenTicker) internal returns (uint256, uint256) {
        uint256 passedEpochs;
        uint256 nextEpochStartBlock;
        if(block.number > nextEpochBlock[_tokenTicker]) {

            uint256 epochStartBlock;
            uint epochLength;
            (epochStartBlock, epochLength) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);

            if(epochs[_tokenTicker].length > 0) {
                Epoch memory epoch = epochs[_tokenTicker][epochs[_tokenTicker].length - 1];
                nextEpochStartBlock = epoch.startBlock + epoch.epochLength;
                passedEpochs = (block.number - nextEpochStartBlock) / epochLength;
                // nextEpochBlock[_tokenTicker] += passedEpochs * epochLength;
            } else {
                passedEpochs = (block.number - epochStartBlock) / epochLength;
                nextEpochStartBlock = epochStartBlock;
                // nextEpochBlock[_tokenTicker] = epochStartBlock + passedEpochs * epochLength - 1;
            }
            nextEpochBlock[_tokenTicker] += passedEpochs * epochLength;
        }
        return (passedEpochs, nextEpochStartBlock);
    }

    function addPassedEpochs(
        string memory _tokenTicker
    ) internal {
        (uint256 passedEpochs, uint256 nextEpochStartBlock) = calculatePassedEpoch(_tokenTicker);
        if(passedEpochs == 0)
            return;

        uint256 epochLength;
        (, epochLength) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
        
        // uint256 totalFeesCollected = feePoolUpgradeable.totalFees(_tokenTicker);
        // uint256 feesInLastEpoch = epochs[_tokenTicker][epochs[_tokenTicker].length - 1].totalFeesCollected;
        uint256 totalActiveLiquidity = totalLpLiquidity[_tokenTicker];

        // uint256 noOfDepositors;
        // if(epochs[_tokenTicker].length > 0) {
        //     noOfDepositors = epochs[_tokenTicker][epochs[_tokenTicker].length - 1].noOfDepositors;
        // }
        uint256 noOfDepositors = bridgeUtilsUpgradeable.getNoOfDepositors(_tokenTicker);
        // (, , , epochLength, , totalFeesCollected, totalActiveLiquidity, ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);

        uint256 index;
        for (index = 0; index < passedEpochs - 1; index++) {
            Epoch memory epoch = Epoch({
                startBlock: nextEpochStartBlock + (index * epochLength),
                epochLength: epochLength,
                totalFeesCollected: 0, 
                totalActiveLiquidity: totalActiveLiquidity,
                noOfDepositors: noOfDepositors
            });
            epochs[_tokenTicker].push(epoch);
        }

        // pushing the last epoch
        uint256 feesInCurrentEpoch = feePoolUpgradeable.feesInCurrentEpoch(_tokenTicker);
        Epoch memory lastEpoch = Epoch({
            startBlock: nextEpochStartBlock + (index * epochLength),
            epochLength: epochLength,
            totalFeesCollected: feesInCurrentEpoch, 
            totalActiveLiquidity: totalActiveLiquidity,
            noOfDepositors: noOfDepositors
        });
        epochs[_tokenTicker].push(lastEpoch);

        feePoolUpgradeable.resetFeesInCurrentEpoch(_tokenTicker);
    }

    function _addPassedEpochs(
        string memory _tokenTicker
    ) external {
        require(_msgSender() == address(feePoolUpgradeable));
        addPassedEpochs(_tokenTicker);
    }

    function addLiquidity(
        string calldata _tokenTicker,
        uint256 _noOfTokens,
        uint256 _noOfBoosters
    ) public isBridgeActive(_tokenTicker) {
        require(_noOfTokens > 0, "NO_OF_TOKENS > 0");
        // adding any passed epochs
        addPassedEpochs(_tokenTicker);

        uint256 epochStartIndex = 1;
        uint256 epochStartBlock;

        if(epochs[_tokenTicker].length > 0) {
            Epoch memory epoch = epochs[_tokenTicker][epochs[_tokenTicker].length - 1];
            epochStartIndex = epochs[_tokenTicker].length + 1;
            epochStartBlock = epoch.startBlock + epoch.epochLength;
        } else {
            // uint epochLength;
            // (epochStartBlock, epochLength) = tokenBridgeRegistryUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
            // epochStartBlock = block.number - ((block.number - epochStartBlock) % epochLength);
            (epochStartBlock, ) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
        }

        // Add new liquidity position
        LiquidityPosition memory position = LiquidityPosition({
            depositedAmount: _noOfTokens,
            blockNo: block.number,
            claimedTillEpochIndex: epochs[_tokenTicker].length,
            epochStartIndex: epochStartIndex,
            epochStartBlock: epochStartBlock,
            boosterEndEpochIndex: epochs[_tokenTicker].length,
            startTimestamp: block.timestamp
        });
        uint256 index = currentIndex[_tokenTicker][_msgSender()]++;
        liquidityPosition[_tokenTicker][_msgSender()][index] = position;

        totalLiquidity[_tokenTicker] += _noOfTokens; 
        totalLpLiquidity[_tokenTicker] += _noOfTokens; 
        tokenBridgeRegistryUpgradeable.updateNoOfDepositors(_tokenTicker, true);

        TokenUpgradeable token = getToken(_tokenTicker);
        token.transferFrom(_msgSender(), address(this), _noOfTokens);

        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        // setuToken.transfer(_msgSender(), _noOfTokens);
        setuToken.lockTokens(_msgSender(), _noOfTokens);

        // to buy boosters along with adding the liquidity
        if(_noOfBoosters > 0) {
            buyBoosterPacks(_tokenTicker, index, _noOfBoosters);
        }

        // (string memory name, string memory imageUrl, ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        emit LiquidityAdded(index, _msgSender(), _tokenTicker, _noOfTokens);
    }

    function concatenate(
        string memory a, 
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function removeLiquidity(
        uint256 _index,
        string calldata _tokenTicker
    ) public isBridgeActive(_tokenTicker) {
        // adding any passed epochs
        addPassedEpochs(_tokenTicker);

        LiquidityPosition memory position = liquidityPosition[_tokenTicker][_msgSender()][_index];
        require(position.depositedAmount > 0, "INVALID_POSITION");
        
        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.unlockToken(_msgSender(), position.depositedAmount);
        // setuToken.transfer(_msgSender(), position.depositedAmount);

        // // Calculate fee share
        // uint256 feeShare = feePoolUpgradeable.getUserConfirmedRewards(_tokenTicker, _msgSender(), _index);
        
        // // Transfer Fees to LP user
        // // fees token - same as the deposited token OR chain native token
        // TokenUpgradeable token = getToken(_tokenTicker);
        // token.transferFrom(address(this), _msgSender(), feeShare);
        
        feePoolUpgradeable.transferLpFee(_tokenTicker, _msgSender(), _index);

        // Withdraw liquidity
        withdrawLiquidity(_index, _tokenTicker);

        emit LiquidityRemoved(_index, _msgSender(), _tokenTicker);
    }

    function withdrawLiquidity(
        uint256 _index,
        string calldata _tokenTicker
    ) internal {
        uint256 currentLiquidity = totalLiquidity[_tokenTicker];
        LiquidityPosition storage liquidityPos = liquidityPosition[_tokenTicker][_msgSender()][_index];
        uint256 noOfTokens = liquidityPos.depositedAmount;
        totalLpLiquidity[_tokenTicker] -= noOfTokens;
        uint256 currentEpochIndex = epochs[_tokenTicker].length + 1;
        if(liquidityPos.boosterEndEpochIndex >= currentEpochIndex) {
            updateBoosterMapping(
                _tokenTicker,
                _index,
                liquidityPos.boosterEndEpochIndex - currentEpochIndex + 1,
                currentEpochIndex,
                noOfTokens,
                false
            );
        }

        // pool has less liquidity
        if(currentLiquidity < noOfTokens) {
            noOfTokens = currentLiquidity;
        }
        
        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.burnTokens(_msgSender(), noOfTokens);
        
        totalLiquidity[_tokenTicker] -= noOfTokens;
        tokenBridgeRegistryUpgradeable.updateNoOfDepositors(_tokenTicker, false);

        TokenUpgradeable token = getToken(_tokenTicker);
        token.transfer(_msgSender(), noOfTokens);
        // token.transferFrom(address(this), _msgSender(), noOfTokens);

        delete liquidityPosition[_tokenTicker][_msgSender()][_index];
    }

    // initiate bridge transaction on the source chain
    function transferIn(
        string calldata _tokenTicker,
        uint256 _noOfTokens,
        uint8 _toChainId,
        uint256 _gasPrice
    ) public isBridgeActive(_tokenTicker) returns (bool, uint256) {
        TokenUpgradeable token = getToken(_tokenTicker);
        token.transferFrom(_msgSender(), address(this), _noOfTokens);
        
        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        
        uint8 bridgeType = bridgeUtilsUpgradeable.getBridgeType(_tokenTicker);
        if(bridgeType == 0) {
            totalLiquidity[_tokenTicker] += _noOfTokens;
        }
        if(bridgeType == 1) {
            token.burnTokens(_msgSender(), _noOfTokens);
        }

        return crossChainTransferOut(_tokenTicker, _noOfTokens, _toChainId, _gasPrice);
    }

    function crossChainTransferOut(
        string memory _tokenTicker,
        uint256 _noOfTokens,
        uint8 _toChainId,
        uint256 _gasPrice
    ) public isBridgeActive(_tokenTicker) returns (bool, uint256) {
        // adding any passed epochs
        addPassedEpochs(_tokenTicker);

        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.burnTokens(_msgSender(), _noOfTokens);

        bytes32 key = keccak256(abi.encode(_tokenTicker, _msgSender(), chainId, _toChainId));
        uint256 transferIndex = currentTransferIndex[key];
        ++currentTransferIndex[key];
        // bytes4 _interface = bytes4(keccak256("createCrossChainTransferMapping(address,uint256,string,uint256,uint8)"));
        // bytes memory data = abi.encode(_msgSender(), _noOfTokens, _tokenTicker, transferIndex, chainId);
        // ChainID - Selector - Data - Gas Usage - Gas Price
        (bool success, ) = routerSend(
                            _toChainId, 
                            bytes4(keccak256("createCrossChainTransferMapping(address,uint256,string,uint256,uint8)")), 
                            abi.encode(_msgSender(), _noOfTokens, _tokenTicker, transferIndex, chainId), 
                            crossChainGas, 
                            _gasPrice
                        );
        require(success, "ROUTER_ERROR");

        // // ( , string memory imageUrl, ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        emit BridgeTransactionInit(transferIndex, _toChainId, _msgSender(), _tokenTicker, _noOfTokens);

        return (success, transferIndex);
        // addTransferMap(_tokenTicker, _noOfTokens, _toChainId);
        // return (true, transferIndex);
    }

    // function addTransferMap(string memory _tokenTicker, uint256 _noOfTokens, uint8 _toChainId) internal {
    //     // Create Transfer Mapping
    //     // TransferMapping memory transfer = TransferMapping({
    //     //     userAddress: _msgSender(),
    //     //     noOfTokens: _noOfTokens
    //     // });
    //     // transferMapping[_tokenTicker][currentTransferIndex[_tokenTicker][_msgSender()] - 1] = transfer;
    //     transferMapping[_tokenTicker][_msgSender()][chainId][currentTransferIndex[_tokenTicker][_msgSender()][_toChainId] - 1] = _noOfTokens;
    // }

    function _routerSyncHandler(
        bytes4 _interface,
        bytes memory _data
    ) internal virtual override  returns ( bool , bytes memory )
    {
        (address userAddress, uint256 noOfTokens, string memory tokenTicker, uint256 transferIndex, uint8 fromChain) = abi.decode(_data, (address, uint256, string, uint256, uint8));
        (bool success, bytes memory returnData) = 
            address(this).call( abi.encodeWithSelector(_interface, userAddress, noOfTokens, tokenTicker, transferIndex, fromChain));
        return (success, returnData);
    }

    function replayTransaction(
        bytes32 hash,
        uint256 _crossChainGasPrice
    ) external onlyOwner {
        routerReplay(
            hash,
            crossChainGas,
            _crossChainGasPrice
        );
    }

    function createCrossChainTransferMapping(
        address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker,
        uint256 _transferIndex,
        uint8 _fromChain
    ) external isSelf {
        bytes32 indexKey = keccak256(abi.encode(_tokenTicker, _userAddress, _fromChain, chainId));
        require(_transferIndex == currentTransferIndex[indexKey], "INVALID_TRANSFER_INDEX");
        
        // Create Transfer Mapping
        // TransferMapping memory transfer = TransferMapping({
        //     userAddress: _userAddress,
        //     noOfTokens: _noOfTokens
        // });
        // transferMapping[_tokenTicker][currentTransferIndex[_tokenTicker][_userAddress][chainId]++] = transfer;
        bytes32 key = keccak256(abi.encode(_tokenTicker, _userAddress, _fromChain, chainId, currentTransferIndex[indexKey]++));
        transferMapping[key] = _noOfTokens;
        // transferMapping[_tokenTicker][_userAddress][_fromChain][chainId][currentTransferIndex[_tokenTicker][_userAddress][_fromChain][chainId]++] = _noOfTokens;

        emit BridgeTransactionEnd(_transferIndex, _fromChain, chainId, _userAddress, _tokenTicker, 2);
    }

    function crossChainTransferIn(
        // address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker,
        uint256 _index,
        uint8 _fromChain
    ) public payable isBridgeActive(_tokenTicker) {
        // require(transferMapping[_tokenTicker][_index].userAddress != address(0), "TRANSFER_MAPPING_NOT_EXISTS");
        // require(transferMapping[_tokenTicker][_index].userAddress == _msgSender(), "NOT_OWNER");
        // require(_noOfTokens <= transferMapping[_tokenTicker][_index].noOfTokens, "EXCESS_TOKENS_REQUESTED");
        bytes32 key = keccak256(abi.encode(_tokenTicker, _msgSender(), _fromChain, chainId, _index));
        require(transferMapping[key] > 0, "TRANSFER_MAPPING_NOT_EXISTS");
        require(_noOfTokens <= transferMapping[key], "EXCESS_TOKENS_REQUESTED");

        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        
        // transferMapping[_tokenTicker][_index].noOfTokens -= _noOfTokens;
        // if(transferMapping[_tokenTicker][_index].noOfTokens == 0) {
        //     delete transferMapping[_tokenTicker][_index];
        // }
        transferMapping[key] -= _noOfTokens;
        if(transferMapping[key] == 0) {
            delete transferMapping[key];
        }

        transferOut(_noOfTokens, _tokenTicker);

        emit BridgeTransactionEnd(_index, _fromChain, chainId, _msgSender(), _tokenTicker, 3);
    }

    function transferOut(
        // address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker
    ) public payable isBridgeActive(_tokenTicker) {
        // adding any passed epochs
        addPassedEpochs(_tokenTicker);

        TokenUpgradeable setuToken = getToken(concatenate("setu", _tokenTicker));
        TokenUpgradeable token = getToken(_tokenTicker);
        
        uint8 bridgeType = bridgeUtilsUpgradeable.getBridgeType(_tokenTicker);
        
        uint256 currentLiquidity = totalLiquidity[_tokenTicker];
        uint256 noOfTokens = _noOfTokens;
        // pool has less liquidity
        if(currentLiquidity < _noOfTokens) {
            noOfTokens = currentLiquidity;
        }

        // 0 - liquidity bridge, 1 - child + liquidity bridge
        if(bridgeType == 0) {
            uint256 feesDeducted = calculateBridgingFees(_tokenTicker, noOfTokens);
            setuToken.burnTokens(_msgSender(), noOfTokens);
            totalLiquidity[_tokenTicker] -= noOfTokens;
            token.transfer(_msgSender(), noOfTokens - feesDeducted);
            if(feesDeducted > 0) {
                token.transfer(address(feePoolUpgradeable), feesDeducted);
            }
        } 
        else if(bridgeType == 1) {
            uint256 feesDeducted = calculateBridgingFees(_tokenTicker, _noOfTokens);
            setuToken.burnTokens(_msgSender(), _noOfTokens);
            totalLiquidity[_tokenTicker] -= noOfTokens;

            if(noOfTokens < feesDeducted) {
                // transfer the available tokens from the liquidity pool
                token.transfer(_msgSender(), noOfTokens);
                token.mintTokens(_msgSender(), _noOfTokens - noOfTokens - feesDeducted);
                if(feesDeducted > 0) {
                    token.mintTokens(address(feePoolUpgradeable), feesDeducted);
                }
            }
            else {
                if(feesDeducted > 0) {
                    token.transfer(address(feePoolUpgradeable), feesDeducted);
                }
                // transfer the available tokens from the liquidity pool
                token.transfer(_msgSender(), noOfTokens - feesDeducted);
                token.mintTokens(_msgSender(), _noOfTokens - noOfTokens);
            }
        }
    }

    function calculateBridgingFees(
        string calldata _tokenTicker,
        uint256 _noOfTokens
    ) internal returns (uint256) {
        uint8 feeType;
        uint256 feeInBips;
        uint256 fees;
        (feeType, feeInBips) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);

        // fee in native chain token
        if(feeType == 0) {
            require(msg.value >= feeInBips, "INSUFFICIENT_FEES");
            feePoolUpgradeable.updateTotalFees(_tokenTicker, feeInBips, true);
            (bool success, ) = address(feePoolUpgradeable).call{value: feeInBips}("");
            require(success, "POOL_TRANFER_FAILED");

            (success, ) = _msgSender().call{value: msg.value - feeInBips}("");
            require(success, "SENT_BACK_FAILED");
        }
        else if(feeType == 1) {
            fees = _noOfTokens * feeInBips / maxBips;
            feePoolUpgradeable.updateTotalFees(_tokenTicker, fees, true);
        }

        return fees;
    }

    function safeWithdrawLiquidity(
        string calldata _tokenTicker,
        uint256 _noOfTokens
    ) external onlyOwner {
        // require(_noOfTokens <= totalLiquidity[_tokenTicker], "AMOUNT_OVERFLOW");
        // totalLiquidity[_tokenTicker] -= _noOfTokens;

        TokenUpgradeable token = getToken(_tokenTicker);
        token.transfer(owner(), _noOfTokens);
    }

    function getEpochsLength(string memory _tokenTicker) public view returns (uint256) {
        return epochs[_tokenTicker].length;
    } 

    // function getEpochTotalDepositors(
    //     string memory _tokenTicker,
    //     uint256 _epochIndex
    // ) public view returns (uint256) {
    //     return epochs[_tokenTicker][_epochIndex - 1].noOfDepositors;
    // } 

    // function getEpochTotalFees(
    //     string memory _tokenTicker,
    //     uint256 _epochIndex
    // ) public view returns (uint256) {
    //     return epochs[_tokenTicker][_epochIndex-1].totalFeesCollected;
    // } 

    function deleteHasBoosterMapping(
        string memory _tokenTicker,
        address _account,
        uint256 _index,
        uint256 epochIndex
    ) public {
        require(_msgSender() == address(feePoolUpgradeable), "ONLY_FEE_POOL");
        delete hasBooster[_tokenTicker][_account][_index][epochIndex];
    }

    function updateRewardClaimedTillIndex(
        string memory _tokenTicker,
        address _account,
        uint256 _index
        // uint256 epochIndex
    ) public {
        require(_msgSender() == address(feePoolUpgradeable), "ONLY_FEE_POOL");
        liquidityPosition[_tokenTicker][_account][_index].claimedTillEpochIndex = epochs[_tokenTicker].length;
    }

    // function transferTokenOwnership1(address payable _newBridge, address _token) public onlyOwner {
    //     BridgeUpgradeable newBridge = BridgeUpgradeable(_newBridge);
    //     newBridge.transferTokenOwnership2(_token);
    // }

    // function transferTokenOwnership2(address token) public {
    //     TokenUpgradeable setuToken = TokenUpgradeable(token);
    //     setuToken.transferOwnership(address(this));
    // }

    function getBackTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function getBackNativeTokens() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

    receive() external payable {}

    uint256[100] private __gap;
}