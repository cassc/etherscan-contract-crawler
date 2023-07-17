pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/math/SafeMath.sol";

library ITrustVaultLib {
    using SafeMath for uint;

    struct RewardTokenRoundData{
        address tokenAddress;
        uint amount;
        uint commissionAmount;
        uint tokenPerBlock; 
        uint totalSupply;
        bool ignoreUnstakes;
    }

    struct RewardTokenRound{
        mapping(address => RewardTokenRoundData) roundData;
        uint startBlock;
        uint endBlock;
    }

    struct AccountStaking {
        uint32 startRound;
        uint endDate;
        uint total;
        Staking[] stakes;
    }

    struct Staking {
        uint startTime;
        uint startBlock;
        uint amount;
        uint total;
    }

    struct UnStaking {
        address account; 
        uint amount;
        uint startDateTime;   
        uint startBlock;     
        uint endBlock;    
    }

    struct ClaimedReward {
        uint amount;
        uint lastClaimedRound;
    }

    function divider(uint numerator, uint denominator, uint precision) internal pure returns(uint) {        
        return numerator*(uint(10)**uint(precision))/denominator;
    }

    function getUnstakingsForBlockRange(
        UnStaking[] memory unStakes, 
        uint startBlock, 
        uint endBlock) internal pure returns (uint){
         // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || unStakes.length == 0 
            || unStakes[0].startBlock > endBlock)
        {         
            return 0;
        }

        uint lastIndex = unStakes.length - 1;
        uint diff = 0;
        uint stakeEnd;
        uint stakeStart;

        uint total;
        diff = 0;
        stakeEnd = 0; 
        stakeStart = 0;
        //last index should now be in our range so loop through until all block numbers are covered
      
        while(lastIndex >= 0) {  

            if( (unStakes[lastIndex].endBlock != 0 && unStakes[lastIndex].endBlock < startBlock)
                || unStakes[lastIndex].startBlock > endBlock) {
                if(lastIndex == 0){
                    break;
                } 
                lastIndex = lastIndex.sub(1);
                continue;
            }
            
            stakeEnd = unStakes[lastIndex].endBlock == 0 
                ? endBlock : unStakes[lastIndex].endBlock;

            stakeEnd = (stakeEnd >= endBlock ? endBlock : stakeEnd);

            stakeStart = unStakes[lastIndex].startBlock < startBlock 
                ? startBlock : unStakes[lastIndex].startBlock;
            
            diff = (stakeEnd == stakeStart ? 1 : stakeEnd.sub(stakeStart));

            total = total.add(unStakes[lastIndex].amount.mul(diff));

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }
 
        return total;
    }

function getHoldingsForBlockRange(
        Staking[] memory stakes,
        uint startBlock, 
        uint endBlock) internal pure returns (uint){
        
        // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || stakes.length == 0 
            || stakes[0].startBlock > endBlock){
            return 0;
        }
        uint lastIndex = stakes.length - 1;
    
        uint diff;
        // If the last total supply is before the start we are looking for we can take the last value
        if(stakes[lastIndex].startBlock <= startBlock){
            diff =  endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
            return stakes[lastIndex].total.mul(diff);
        }
 
        // working our way back we need to get the first index that falls into our range
        // This could be large so need to think of a better way to get here
        while(lastIndex > 0 && stakes[lastIndex].startBlock > endBlock){
            lastIndex = lastIndex.sub(1);
        }
 
        uint total;
        diff = 0;
        //last index should now be in our range so loop through until all block numbers are covered
        while(stakes[lastIndex].startBlock >= startBlock ) {  
            diff = 1;
            if(stakes[lastIndex].startBlock <= startBlock){
                diff = endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
                total = total.add(stakes[lastIndex].total.mul(diff));
                break;
            }
 
            diff = endBlock.sub(stakes[lastIndex].startBlock) == 0 
                            ? 1 
                            : endBlock.sub(stakes[lastIndex].startBlock);
            total = total.add(stakes[lastIndex].total.mul(diff));
            endBlock = stakes[lastIndex].startBlock;
 
            if(lastIndex == 0){
                break;
            } 
 
            lastIndex = lastIndex.sub(1); 
        }
 
        // If the last total supply is before the start we are looking for we can take the last value
        if(stakes[lastIndex].startBlock <= startBlock && startBlock <= endBlock){
            diff =  endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
            total = total.add(stakes[lastIndex].total.mul(diff));

        }
 
        return total;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}