// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./BridgeUtilsUpgradeable.sol";

contract FeePoolUpgradeable is Initializable, OwnableUpgradeable {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;
    BridgeUpgradeable public bridgeUpgradeable;
    BridgeUtilsUpgradeable public bridgeUtilsUpgradeable;

    // tokenTicker => totalFees
    mapping(string => uint256) public totalFees;
    // tokenTicker => adminClaimedTillEpoch
    mapping(string => uint256) public adminClaimedTillEpoch;

    struct ConfirmedStartEpochFeeParams {
        string _tokenTicker;
        uint256 epochStartIndex;
        uint256 epochStartBlock;
        uint256 blockNo;
        uint256 depositedAmount;
        address _account;
        uint256 _index;
    }

    // tokenTicker => totalFees
    mapping(string => uint256) public feesInCurrentEpoch;

    event ClaimedRewards(
        uint256 indexed index,
        address indexed account,
        string tokenTicker,
        uint256 noOfTokens,
        uint256 claimTimestamp
    );

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable,
        BridgeUpgradeable _bridgeUpgradeable
    ) initializer public {
        __Ownable_init();
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        bridgeUpgradeable = _bridgeUpgradeable;
    }

    function _isBridgeActive(string memory _tokenTicker) internal view {
        require(tokenBridgeRegistryUpgradeable.isBridgeActive() 
            && bridgeUtilsUpgradeable.isTokenBridgeActive(_tokenTicker), "BRIDGE_DISABLED");
    }

    function updateTokenBridgeRegistryAddress(TokenBridgeRegistryUpgradeable _newInstance) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _newInstance;
    }

    function updateBridgeUpgradeableAddress(BridgeUpgradeable _newInstance) external onlyOwner {
        bridgeUpgradeable = _newInstance;
    }

    function updateBridgeUtilsUpgradeableAddress(BridgeUtilsUpgradeable _newInstance) external onlyOwner {
        bridgeUtilsUpgradeable = _newInstance;
    }

    function transferLpFee(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        // Calculate fee share
        uint256 feeShare = getUserConfirmedRewards(_tokenTicker, _account, _index);
        require(totalFees[_tokenTicker] >= feeShare, "INSUFFICIENT_FEES");

        uint8 feeType;
        (feeType, ) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        totalFees[_tokenTicker] -= feeShare;

        // Transfer Fees to LP user
        if(feeType == 0) {
            // fee in native chain token
            (bool success, ) = _account.call{value: feeShare}("");
            require(success, "TRANSFER_FAILED");
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_account, feeShare);
        }
        
    }

    // function getLPsFee(
    //     uint256 epochTotalFees,
    //     string memory tokenTicker,
    //     uint256 epochIndex
    // ) internal view returns (uint256) {
    //     uint256 totalBoostedUsers = bridgeUpgradeable.totalBoostedUsers(tokenTicker, epochIndex);
    //     uint256 noOfDepositors;
    //     uint256 epochsLength = bridgeUpgradeable.getEpochsLength(tokenTicker);
    //     // calculation for the first epoch or the current ongoing epoch
    //     if((epochIndex == 1 && epochsLength == 0) || epochIndex == epochsLength + 1) {
    //         noOfDepositors = bridgeUtilsUpgradeable.getNoOfDepositors(tokenTicker);
    //     } else {
    //         noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(tokenTicker, epochIndex);
    //     }

    //     uint256 perUserFee = epochTotalFees / (2 * noOfDepositors);
        
    //     uint256 normalFees = (noOfDepositors - totalBoostedUsers) * perUserFee;
    //     uint256 extraBoostedFees = totalBoostedUsers * perUserFee * 3 / 2;
    //     return (extraBoostedFees + normalFees);
    // }

    // calculates (confirmed + unconfirmed) rewards
    function getUserUnconfirmedRewards(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount, 
            uint256 blockNo, 
            uint256 claimedTillEpochIndex, 
            uint256 epochStartIndex, 
            , 
            ,

        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 feeEarned;
        
        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        // user still in starting epoch
        if(epochsLength == epochStartIndex - 1) {
            return getUnconfirmedStartEpochFee(_tokenTicker, blockNo, depositedAmount, _account, _index, epochsLength);
        }

        // // starting epoch is over but user has claimed nothing
        // if(epochStartIndex - 1 == claimedTillEpochIndex 
        //     && epochsLength > epochStartIndex - 1
        // ) { 
        //     ConfirmedStartEpochFeeParams memory params = ConfirmedStartEpochFeeParams(
        //         _tokenTicker,
        //         epochStartIndex,
        //         epochStartBlock,
        //         blockNo,
        //         depositedAmount,
        //         _account,
        //         _index
        //     );
        //     feeEarned = getConfirmedStartEpochFee(params);
        //     claimedTillEpochIndex += 1;
        // }

        // // fees for all the completed epochs
        // for (uint256 liqIndex = claimedTillEpochIndex + 1; liqIndex <= epochsLength; liqIndex++) {
        //     feeEarned += getConfirmedEpochsFee(_tokenTicker, liqIndex, depositedAmount, _account, _index);
        //     claimedTillEpochIndex += 1;
        // }

        // fees for current ongoing epoch (not the starting epoch for user)
        if(epochsLength == claimedTillEpochIndex) {
            feeEarned += getUnconfirmedCurrentEpochFee(_tokenTicker, claimedTillEpochIndex, depositedAmount, _account, _index, epochsLength);
        }

        return feeEarned;
    }

    function getUnconfirmedStartEpochFee(
        string memory _tokenTicker,
        uint256 blockNo,
        uint256 depositedAmount,
        address _account,
        uint256 _index,
        uint256 epochsLength
    ) internal view returns (uint256) {
        uint256 totalFeeCollected = feesInCurrentEpoch[_tokenTicker];
        // uint256 lpsFee = getLPsFee(totalFeeCollected, _tokenTicker, epochsLength + 1);
        uint256 epochLpFees = totalFeeCollected / 2;
        uint256 totalActiveLiquidity = bridgeUpgradeable.totalLpLiquidity(_tokenTicker);
        
        uint256 liquidityBlocks = block.number - blockNo;
        uint256 epochLength = bridgeUtilsUpgradeable.getEpochLength(_tokenTicker);
        uint256 feeEarned = (depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * epochLength);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, epochsLength + 1)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function getConfirmedStartEpochFee(
        ConfirmedStartEpochFeeParams memory params
    ) internal view returns (uint256) {
        (
            , 
            uint256 epochLength, 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            
        ) = bridgeUpgradeable.epochs(params._tokenTicker, params.epochStartIndex-1);
        uint256 liquidityBlocks = params.epochStartBlock + epochLength - params.blockNo;
        // uint256 lpsFee = getLPsFee(totalFeesCollected, params._tokenTicker, params.epochStartIndex);
        uint256 epochLpFees = totalFeesCollected / 2;
        uint256 feeEarned = (params.depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * epochLength);
        if(bridgeUpgradeable.hasBooster(params._tokenTicker, params._account, params._index, params.epochStartIndex)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function getConfirmedEpochsFee(
        string memory _tokenTicker,
        uint256 liqIndex,
        uint256 depositedAmount,
        address _account,
        uint256 _index
    ) internal view returns (uint256) {
        (
            , 
            , 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, liqIndex-1);
        // uint256 lpsFee = getLPsFee(totalFeesCollected, _tokenTicker, liqIndex);
        uint256 epochLpFees = totalFeesCollected / 2;
        uint256 epochFee = (depositedAmount * epochLpFees / totalActiveLiquidity);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, liqIndex)) {
            epochFee = epochFee * 3 / 2;
        }
        return epochFee;
    }

    function getUnconfirmedCurrentEpochFee(
        string memory _tokenTicker,
        uint256 claimedTillEpochIndex,
        uint256 depositedAmount,
        address _account,
        uint256 _index,
        uint256 epochsLength
    ) internal view returns (uint256) {
        uint256 totalActiveLiquidity = bridgeUpgradeable.totalLpLiquidity(_tokenTicker);
        // uint256 lpsFee = getLPsFee(totalFees[_tokenTicker], _tokenTicker, claimedTillEpochIndex + 1);
        uint256 epochLpFees = feesInCurrentEpoch[_tokenTicker] / 2;

        (
            uint256 startBlock, 
            uint256 epochLength, 
            , 
            , 
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, claimedTillEpochIndex - 1);
        uint256 liquidityBlocks = block.number - (startBlock + epochLength);
        uint256 fixedEpochLength = bridgeUtilsUpgradeable.getEpochLength(_tokenTicker);
        uint256 feeEarned = (depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * fixedEpochLength);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, epochsLength + 1)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function getUserConfirmedRewards(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount, 
            uint256 blockNo, 
            uint256 claimedTillEpochIndex, 
            uint256 epochStartIndex, 
            uint256 epochStartBlock, 
            ,

        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        uint256 feeEarned;
                
        // user still in starting epoch
        if(epochsLength == epochStartIndex - 1) {
            return feeEarned;
        }

        // starting epoch is over but user has claimed nothing
        if(epochStartIndex - 1 == claimedTillEpochIndex 
            && epochsLength > epochStartIndex - 1
        ) {
            ConfirmedStartEpochFeeParams memory params = ConfirmedStartEpochFeeParams(
                _tokenTicker,
                epochStartIndex,
                epochStartBlock,
                blockNo,
                depositedAmount,
                _account,
                _index
            );
            feeEarned = getConfirmedStartEpochFee(params);
            claimedTillEpochIndex += 1;
        }

        // fees for all the completed epochs
        for (uint256 liqIndex = claimedTillEpochIndex + 1; liqIndex <= epochsLength; liqIndex++) {
            feeEarned += getConfirmedEpochsFee(_tokenTicker, liqIndex, depositedAmount, _account, _index);
            claimedTillEpochIndex += 1;
        }

        return feeEarned;
    }

    function claimFeeShare(
        string calldata _tokenTicker, 
        uint256 _index
    ) public {
        _isBridgeActive(_tokenTicker);

        // adding any passed epochs
        bridgeUpgradeable._addPassedEpochs(_tokenTicker);

        address _account = _msgSender();
        (
            uint256 depositedAmount, 
            , 
            uint256 claimedTillEpochIndex, 
            , 
            , 
            ,
            
        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 startEpoch = claimedTillEpochIndex + 1;
        uint256 feeEarned = getUserConfirmedRewards(_tokenTicker, _account, _index);
        require(feeEarned > 0, "NO_REWARD");
        require(totalFees[_tokenTicker] >= feeEarned, "INSUFFICIENT_FEES");
        bridgeUpgradeable.updateRewardClaimedTillIndex(_tokenTicker, _account, _index);

        uint256 endEpoch = bridgeUpgradeable.getEpochsLength(_tokenTicker);
        for (uint256 epochIndex = startEpoch; epochIndex <= endEpoch; epochIndex++) {
            bridgeUpgradeable.deleteHasBoosterMapping(_tokenTicker, _account, _index, epochIndex);
        }

        transferFee(_tokenTicker, _account, feeEarned);

        emit ClaimedRewards(_index, _account, _tokenTicker, feeEarned, block.timestamp);
    }

    function transferFee(
        string memory _tokenTicker,
        address _account,
        uint256 feeEarned
    ) internal {
        uint8 feeType;
        uint256 feeInBips;
        (feeType, feeInBips) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        totalFees[_tokenTicker] -= feeEarned;

        // fee in native chain token
        if(feeType == 0) {
            (bool success, ) = _account.call{value: feeEarned}("");
            require(success, "CLAIM_FEE_FAILED");
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_account, feeEarned);
        }
    }

    function getLastEpochLpFees(
        string memory _tokenTicker
    ) public view returns (uint256) {
        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);
        if(epochsLength == 0)
            return 0;
        
        // uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochsLength);
        (
            , 
            , 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            uint256 noOfDepositors
        ) = bridgeUpgradeable.epochs(_tokenTicker, epochsLength-1);

        // for child token bridges
        if(noOfDepositors == 0) {
            return 0;
        }
        uint256 totalBoostedLiquidity = bridgeUpgradeable.totalBoostedLiquidity(_tokenTicker, epochsLength);
        uint256 totalNormalLiquidity = totalActiveLiquidity - totalBoostedLiquidity;

        uint256 boostedFees = (totalBoostedLiquidity * totalFeesCollected * 3) / (totalActiveLiquidity * 4);
        uint256 normalFees = (totalNormalLiquidity * totalFeesCollected) / (totalActiveLiquidity * 2);

        return (normalFees + boostedFees);
    }

    // function getAdminTokenFees(
    //     string memory _tokenTicker
    // ) public view onlyOwner returns (uint256) {
    //     uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

    //     uint256 adminFees;
    //     for (uint256 epochIndex = adminClaimedTillEpoch[_tokenTicker] + 1; epochIndex <= epochsLength; epochIndex++) {
    //         uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochIndex);
    //         if(noOfDepositors == 0) {
    //             continue;
    //         }
    //         uint256 epochTotalFees = bridgeUtilsUpgradeable.getEpochTotalFees(_tokenTicker, epochIndex);
    //         uint256 totalBoostedUsers = bridgeUpgradeable.totalBoostedUsers(_tokenTicker, epochIndex);

    //         // uint256 perUserFee = epochTotalFees / (2 * noOfDepositors);
            
    //         // uint256 normalFees = (noOfDepositors - totalBoostedUsers) * perUserFee;
    //         // uint256 extraBoostedFees = totalBoostedUsers * perUserFee * 3 / 2;
    //         uint256 normalFees = (noOfDepositors - totalBoostedUsers) * epochTotalFees / (2 * noOfDepositors);
    //         uint256 extraBoostedFees = totalBoostedUsers * epochTotalFees * 3 / (4 * noOfDepositors);
    //         adminFees += epochTotalFees - normalFees - extraBoostedFees;
    //     }

    //     return adminFees;
    // }

    function getAdminTokenFees(
        string memory _tokenTicker
    ) public view onlyOwner returns (uint256) {
        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        uint256 adminFees;
        for (uint256 epochIndex = adminClaimedTillEpoch[_tokenTicker] + 1; epochIndex <= epochsLength; epochIndex++) {
            // uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochIndex);
            // uint256 epochTotalFees = bridgeUtilsUpgradeable.getEpochTotalFees(_tokenTicker, epochIndex);
            (
                , 
                , 
                uint256 totalFeesCollected, 
                uint256 totalActiveLiquidity, 
                uint256 noOfDepositors
            ) = bridgeUpgradeable.epochs(_tokenTicker, epochIndex-1);

            // for child token bridges
            if(noOfDepositors == 0) {
                adminFees += totalFeesCollected;
                continue;
            }
            uint256 totalBoostedLiquidity = bridgeUpgradeable.totalBoostedLiquidity(_tokenTicker, epochIndex);
            uint256 totalNormalLiquidity = totalActiveLiquidity - totalBoostedLiquidity;

            uint256 boostedFees = (totalBoostedLiquidity * totalFeesCollected * 3) / (totalActiveLiquidity * 4);
            uint256 normalFees = (totalNormalLiquidity * totalFeesCollected) / (totalActiveLiquidity * 2);

            adminFees += totalFeesCollected - normalFees - boostedFees;
        }

        return adminFees;
    }

    function withdrawAdminTokenFees(
        string memory _tokenTicker
    ) public onlyOwner {
        // adding any passed epochs
        bridgeUpgradeable._addPassedEpochs(_tokenTicker);
        
        uint256 adminFees = getAdminTokenFees(_tokenTicker);
        totalFees[_tokenTicker] -= adminFees;
        adminClaimedTillEpoch[_tokenTicker] = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        uint8 feeType;
        (feeType, ) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        
        // fee in native chain token
        if(feeType == 0) {
            (bool success, ) = _msgSender().call{value: adminFees}("");
            require(success, "CLAIM_FEE_FAILED");
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_msgSender(), adminFees);
        }
    }

    function withdrawAdminAllTokenFees() public onlyOwner {
        string[] memory tokenBridges = tokenBridgeRegistryUpgradeable.getAllTokenBridges();

        for (uint256 index = 0; index < tokenBridges.length; index++) {
            withdrawAdminTokenFees(tokenBridges[index]);
        }
    }

    function updateTotalFees(
        string calldata _tokenTicker,
        uint256 feesEarned,
        bool _isAddingFees
    ) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        if(_isAddingFees) {
            totalFees[_tokenTicker] += feesEarned;
            feesInCurrentEpoch[_tokenTicker] += feesEarned;
        }
        else {
            totalFees[_tokenTicker] -= feesEarned;
        }
    }

    function resetFeesInCurrentEpoch(string calldata _tokenTicker) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        feesInCurrentEpoch[_tokenTicker] = 0;
    }

    receive() external payable {}

}