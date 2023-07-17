pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../iTrustVaultFactory.sol";
import "./../tokens/iTrustGovernanceToken.sol";
import "./Vault.sol";
import {
    BokkyPooBahsDateTimeLibrary as DateTimeLib
} from "./../3rdParty/BokkyPooBahsDateTimeLibrary.sol";

contract GovernanceDistribution is Initializable, ContextUpgradeable
{
    using SafeMathUpgradeable for uint;

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;

    uint8 internal _locked;
    uint internal _tokenPerHour;
    address internal _iTrustFactoryAddress;
    uint[] internal _totalSupplyKeys;
    mapping (uint => uint) internal _totalSupplyHistory;
    mapping (address => uint[]) internal _totalStakedKeys;
    mapping (address => mapping (uint => uint)) internal _totalStakedHistory;
    mapping (address => uint) internal _lastClaimedTimes;
    mapping(address => mapping(string => bool)) _UsedNonces;

    function initialize(
        address iTrustFactoryAddress,
        uint tokenPerDay
    ) 
        initializer 
        external 
    {
        _iTrustFactoryAddress = iTrustFactoryAddress;
        _tokenPerHour = tokenPerDay.div(24);
    }

    /**
     * Public functions
     */

     function totalStaked(address account) external view returns(uint) {
         _onlyAdmin();

         if(_totalStakedKeys[account].length == 0){
             return 0;
         }

        return _totalStakedHistory[account][_totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)]];
    }

    function totalSupply() external view returns(uint) {
         _onlyAdmin();

         if(_totalSupplyKeys.length == 0){
             return 0;
         }

        return _totalSupplyHistory[_totalSupplyKeys[_totalSupplyKeys.length.sub(1)]];
    }

    function calculateRewards() external view returns(uint amount, uint claimedUntil) {
        (amount, claimedUntil) = _calculateRewards(_msgSender());
        return(amount, claimedUntil);
    }

    function calculateRewardsForAccount(address account) external view returns(uint amount, uint claimedUntil) {
        _isTrustedSigner(_msgSender());
        (amount, claimedUntil) = _calculateRewards(account);
        return(amount, claimedUntil);
    }

    function removeStake(address account, uint value) external {
        _validateStakingDataAddress();
        require(_totalStakedKeys[account].length != 0);
        uint currentTime = _getStartOfHourTimeStamp(block.timestamp);
        uint lastStakedIndex = _totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)];
        if(lastStakedIndex > currentTime){
            if(_totalStakedKeys[account].length == 1 || _totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)] != currentTime){
                _totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)] = currentTime;
                _totalStakedHistory[account][currentTime] = _totalStakedKeys[account].length == 1 ? 0 : _totalStakedHistory[account][_totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)]];
                _totalStakedKeys[account].push(lastStakedIndex);
            }
            _totalStakedHistory[account][lastStakedIndex] = _totalStakedHistory[account][lastStakedIndex].sub(value);
            lastStakedIndex = _totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)];
        }
        require(value <= _totalStakedHistory[account][lastStakedIndex]);
        uint newValue = _totalStakedHistory[account][lastStakedIndex].sub(value);
        if(lastStakedIndex != currentTime){
            _totalStakedKeys[account].push(currentTime);
        }
        _totalStakedHistory[account][currentTime] = newValue;
        require(_totalSupplyKeys.length != 0);
        uint lastSupplyIndex = _totalSupplyKeys[_totalSupplyKeys.length.sub(1)];
        if(lastSupplyIndex > currentTime){
            if(_totalSupplyKeys.length == 1 || _totalSupplyKeys[_totalSupplyKeys.length.sub(2)] != currentTime){
                _totalSupplyKeys[_totalSupplyKeys.length.sub(1)] = currentTime;
                _totalSupplyHistory[currentTime] = _totalSupplyKeys.length == 1 ? 0 : _totalSupplyHistory[_totalSupplyKeys[_totalSupplyKeys.length.sub(2)]];
                _totalSupplyKeys.push(lastSupplyIndex);
            }
            
            _totalSupplyHistory[lastSupplyIndex] = _totalSupplyHistory[lastSupplyIndex].sub(value);
            lastSupplyIndex = _totalSupplyKeys[_totalSupplyKeys.length.sub(2)];
        }
        if(lastSupplyIndex != currentTime){
            _totalSupplyKeys.push(currentTime);
        }
        _totalSupplyHistory[currentTime] = _totalSupplyHistory[lastSupplyIndex].sub(value);
    }

    function addStake(address account, uint value) external {
        _validateStakingDataAddress();
        uint currentTime = _getStartOfNextHourTimeStamp(block.timestamp);

        if(_totalStakedKeys[account].length == 0){
            _totalStakedKeys[account].push(currentTime);
            _totalStakedHistory[account][currentTime] = value;
        } else {
            uint lastStakedIndex = _totalStakedKeys[account].length.sub(1);
            uint lastTimestamp = _totalStakedKeys[account][lastStakedIndex];

            if(lastTimestamp != currentTime){
                _totalStakedKeys[account].push(currentTime);
            }

            _totalStakedHistory[account][currentTime] = _totalStakedHistory[account][lastTimestamp].add(value);
        }

        if(_totalSupplyKeys.length == 0){
            _totalSupplyKeys.push(currentTime);
            _totalSupplyHistory[currentTime] = value;
        } else {
            uint lastSupplyIndex = _totalSupplyKeys.length.sub(1);
            uint lastSupplyTimestamp = _totalSupplyKeys[lastSupplyIndex];

            if(lastSupplyTimestamp != currentTime){
                _totalSupplyKeys.push(currentTime);
            }

            _totalSupplyHistory[currentTime] = _totalSupplyHistory[lastSupplyTimestamp].add(value);
        }
    }

    function withdrawTokens(uint amount, uint claimedUntil, string memory nonce, bytes memory sig) external {
        _nonReentrant();
        require(amount != 0);
        require(claimedUntil != 0);
        require(!_UsedNonces[_msgSender()][nonce]);
        _locked = TRUE;
        bytes32 abiBytes = keccak256(abi.encodePacked(_msgSender(), amount, claimedUntil, nonce, address(this)));
        bytes32 message = _prefixed(abiBytes);

        address signer = _recoverSigner(message, sig);
        _isTrustedSigner(signer);

        _lastClaimedTimes[_msgSender()] = claimedUntil;
        _UsedNonces[_msgSender()][nonce] = true;

        _getiTrustGovernanceToken().transfer(_msgSender(), amount);
        _locked = FALSE;
    }

    /**
     * Internal functions
     */

    function _calculateRewards(address account) internal view returns(uint, uint) {

        if(_totalStakedKeys[account].length == 0 || _totalSupplyKeys.length == 0){
            return (0, 0);
        }

        uint currentTime = _getStartOfHourTimeStamp(block.timestamp);
        uint claimedUntil = _getStartOfHourTimeStamp(block.timestamp);
        uint lastClaimedTimestamp = _lastClaimedTimes[account];

        // if 0 they have never staked go back to the first stake
        if(lastClaimedTimestamp == 0){
            lastClaimedTimestamp = _totalStakedKeys[account][0];
        }

        uint totalRewards = 0;
        uint stakedStartingIndex = _totalStakedKeys[account].length.sub(1);
        uint supplyStartingIndex = _totalSupplyKeys.length.sub(1);
        uint hourReward = 0;

        while(currentTime > lastClaimedTimestamp) {
            (hourReward, stakedStartingIndex, supplyStartingIndex) = _getTotalRewardHour(account, currentTime, stakedStartingIndex, supplyStartingIndex);
            totalRewards = totalRewards.add(hourReward);
            currentTime = DateTimeLib.subHours(currentTime, 1);
        }

        return (totalRewards, claimedUntil);
    }

    function _getTotalRewardHour(address account, uint hourTimestamp, uint stakedStartingIndex, uint supplyStartingIndex) internal view returns(uint, uint, uint) {

        (uint totalStakedForHour, uint returnedStakedStartingIndex) =  _getTotalStakedForHour(account, hourTimestamp, stakedStartingIndex);
        (uint totalSupplyForHour, uint returnedSupplyStartingIndex) =  _getTotalSupplyForHour(hourTimestamp, supplyStartingIndex);
        uint reward = 0;
        
        if(totalSupplyForHour > 0 && totalStakedForHour > 0){
            uint govTokenPerTokenPerHour = _divider(_tokenPerHour, totalSupplyForHour, 18); // _tokenPerHour.div(totalSupplyForHour);
            reward = reward.add(totalStakedForHour.mul(govTokenPerTokenPerHour).div(1e18)); 
        }

        return (reward, returnedStakedStartingIndex, returnedSupplyStartingIndex);
    }

    function _getTotalStakedForHour(address account, uint hourTimestamp, uint startingIndex) internal view returns(uint, uint) {

        while(startingIndex != 0 && hourTimestamp <= _totalStakedKeys[account][startingIndex]) {
            startingIndex = startingIndex.sub(1);
        }

        // We never got far enough back before hitting 0, meaning we staked after the hour we are looking up
        if(hourTimestamp < _totalStakedKeys[account][startingIndex]){
            return (0, startingIndex);
        }

        return (_totalStakedHistory[account][_totalStakedKeys[account][startingIndex]], startingIndex);
    }

    function _getTotalSupplyForHour(uint hourTimestamp, uint startingIndex) internal view returns(uint, uint) {

        

        while(startingIndex != 0 && hourTimestamp <= _totalSupplyKeys[startingIndex]) {
            startingIndex = startingIndex.sub(1);
        }

        // We never got far enough back before hitting 0, meaning we staked after the hour we are looking up
        if(hourTimestamp < _totalSupplyKeys[startingIndex]){
            return (0, startingIndex);
        }

        return (_totalSupplyHistory[_totalSupplyKeys[startingIndex]], startingIndex);
    }

    function _getStartOfHourTimeStamp(uint nowDateTime) internal pure returns (uint) {
        (uint year, uint month, uint day, uint hour, ,) = DateTimeLib.timestampToDateTime(nowDateTime);
        return DateTimeLib.timestampFromDateTime(year, month, day, hour, 0, 0);
    }

    function _getStartOfNextHourTimeStamp(uint nowDateTime) internal pure returns (uint) {
        (uint year, uint month, uint day, uint hour, ,) = DateTimeLib.timestampToDateTime(nowDateTime);
        return DateTimeLib.timestampFromDateTime(year, month, day, hour.add(1), 0, 0);
    }

    function _getITrustVaultFactory() internal view returns(ITrustVaultFactory) {
        return ITrustVaultFactory(_iTrustFactoryAddress);
    }

    function _governanceTokenAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getGovernanceTokenAddress();
    }

    function _getiTrustGovernanceToken() internal view returns(iTrustGovernanceToken) {
        return iTrustGovernanceToken(_governanceTokenAddress());
    }

    function _divider(uint numerator, uint denominator, uint precision) internal pure returns(uint) {        
        return numerator*(uint(10)**uint(precision))/denominator;
    }

    /**
     * Validate functions
     */

     function _nonReentrant() internal view {
        require(_locked == FALSE);  
    }

    function _onlyAdmin() internal view {
        require(
            _getITrustVaultFactory().isAddressAdmin(_msgSender()),
            "Not admin"
        );
    }

    function _isTrustedSigner(address signer) internal view {
        require(
            _getITrustVaultFactory().isTrustedSignerAddress(signer),
            "Not trusted signer"
        );
    }

    function _validateStakingDataAddress() internal view {
        _validateStakingDataAddress(_msgSender());
    }

    function _validateStakingDataAddress(address contractAddress) internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isStakingDataAddress(contractAddress));
    }

    function _splitSignature(bytes memory sig)
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

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}