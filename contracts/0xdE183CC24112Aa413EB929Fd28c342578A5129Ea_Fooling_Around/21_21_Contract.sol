// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@thirdweb-dev/contracts/base/Staking721Base.sol";

contract Fooling_Around is Staking721Base {
    
    uint256 private nextConditionId;

    constructor(
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime,
        address _stakingToken,
        address _rewardToken,
        address _nativeTokenWrapper
    )
        Staking721Base(
            _timeUnit,
            _rewardsPerUnitTime,
            _stakingToken,
            _rewardToken,
            _nativeTokenWrapper
        )
    {}

    function returnStakersSnapshot() 
        public 
        view 
        returns(address[] memory)    
    {
        return stakersArray;
    }

    function returnTokensSnaphot()
        public
        view
        virtual
        returns (uint256[] memory)
    {
        address[] memory _stakersArray = stakersArray;
        uint256 stakersCount = _stakersArray.length;
        uint256[] memory stakersSnapshot = new uint256[](stakersCount);
        uint256 tokensStakedPosition = 0;

        for (uint256 i = 0; i < stakersCount; i++) {
            uint256[] memory _indexedTokens = indexedTokens;
            bool[] memory _isStakerToken = new bool[](_indexedTokens.length);
            uint256 indexedTokenCount = _indexedTokens.length;
            
            uint256 stakerTokenCount = 0;
            for (uint256 j = 0; j < indexedTokenCount; j++) {
                _isStakerToken[j] = stakerAddress[_indexedTokens[j]] == stakersArray[i];
                if (_isStakerToken[j]) stakerTokenCount += 1;
            }
            stakersSnapshot[tokensStakedPosition] = stakerTokenCount;
            tokensStakedPosition += 1;

        }
        
        return stakersSnapshot;
    }

    function returnRewardsSnapshot()
        public
        view
        virtual
        returns (uint256[] memory)
    {
        address[] memory _stakersArray = stakersArray;
        uint256 stakersCount = _stakersArray.length;
        uint256[] memory rewardsSnapshot = new uint256[](stakersCount);

        for (uint256 i = 0; i < stakersCount; i++) {            
            rewardsSnapshot[i] = _availableRewards(stakersArray[i]);
        }

        return rewardsSnapshot;
    }

}