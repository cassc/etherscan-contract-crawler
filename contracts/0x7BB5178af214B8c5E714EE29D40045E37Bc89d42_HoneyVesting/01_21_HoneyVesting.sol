// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VestingCalculator.sol";
import "./interfaces/IHoneyToken.sol";
import "./interfaces/IHoneyJars.sol";
import "./interfaces/IFancyBears.sol";
import "./tag.sol";

contract HoneyVesting is AccessControlEnumerable, VestingCalculator {

    using SafeMath for uint256;
    using SafeERC20 for IHoneyToken;

    IFancyBears public fancyBearsContract;
    IHoneyJars public honeyJarsContract;
    IHoneyToken public honeyContract;

    uint256 public honeyPerBear;
    uint256 public honeyPerJar;
    uint256 public spentHoneyBalance;

    bytes32 public constant HONEY_SPENDER_ROLE = keccak256("HONEY_SPENDER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    
    mapping(uint256 => uint256) public honeySpentByBearId;
    mapping(uint256 => uint256) public honeySpentByJarId;

    mapping(uint256 => uint256) public honeyReleasedByBearId;
    mapping(uint256 => uint256) public honeyReleasedByJarId;

    event HoneyReleasedFromBear(uint256 indexed _tokenId, uint256 _releasable, address _address);
    event HoneyReleasedFromJar(uint256 indexed _tokenId, uint256 _releasable, address _address);
    event HoneySpentFromBear(uint256 indexed _tokenId, uint256 _amount, address _address);
    event HoneySpentFromJar(uint256 indexed _tokenId, uint256 _amount, address _address);
    event HoneyWithdraw(uint256 _amount, address _caller, address _destination);

    constructor(
        IFancyBears _fancyBearsContractAddress, 
        IHoneyJars _honeyJarsContractAddress,
        IHoneyToken _honeyContractAddress,
        uint256 _rewardPeriodInSeconds, 
        uint256 _numberOfRewardPeriods, 
        uint256 _cliffPeriodInSeconds
    )
    VestingCalculator(
        _rewardPeriodInSeconds,
        _numberOfRewardPeriods,
        _cliffPeriodInSeconds
    )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fancyBearsContract = _fancyBearsContractAddress;
        honeyJarsContract = _honeyJarsContractAddress;
        honeyContract = _honeyContractAddress;

        honeyPerBear = 142000 ether;
        honeyPerJar = 71000 ether;
        spentHoneyBalance = 0;
    }

    function claimHoneyFromBear(uint256 _tokenId) public {
        require(fancyBearsContract.ownerOf(_tokenId)==msg.sender,"claimHoneyFromBear: caller does not own fancy bear token");
        (bool overflowFlag, uint256 releasable) = getReleasableHoneyFromBear(_tokenId, block.timestamp);
        require(overflowFlag, "claimHoneyFromBear: no vested honey due - ovfl");
        require(releasable!=0,"claimHoneyFromBear: no vested honey due - zero");
        honeyReleasedByBearId[_tokenId] += releasable;
        emit HoneyReleasedFromBear(_tokenId, releasable, msg.sender);

        honeyContract.safeTransfer(msg.sender, releasable);
    }

    function claimHoneyFromJar(uint256 _tokenId) public {
        require(honeyJarsContract.ownerOf(_tokenId)==msg.sender,"claimHoneyFromJar: caller does not own honey jar token");
        (bool overflowFlag, uint256 releasable) = getReleasableHoneyFromJar(_tokenId, block.timestamp);
        require(overflowFlag, "claimHoneyFromJar: no vested honey due - ovfl");
        require(releasable!=0,"claimHoneyFromJar: no vested honey due - zero");
        honeyReleasedByJarId[_tokenId] += releasable;
        emit HoneyReleasedFromJar(_tokenId, releasable, msg.sender);
        
        honeyContract.safeTransfer(msg.sender, releasable);
    }

    function claimAll(uint256[] memory _fancyBears, uint256[] memory _honeyJars) public {

        uint256 totalClaimableHoney;

        for(uint256 i = 0; i < _fancyBears.length; i++) {
            require(
                fancyBearsContract.ownerOf(_fancyBears[i]) == msg.sender,
                "claimAll: caller does not own fancy bear token"
            );
            (bool overflowFlag, uint256 releasable) = getReleasableHoneyFromBear(_fancyBears[i], block.timestamp);
            require(overflowFlag, "claimAll: no vested honey due - ovfl");
            require(releasable!=0,"claimAll: no vested honey due - zero");
            honeyReleasedByBearId[_fancyBears[i]] += releasable;
            totalClaimableHoney += releasable;
            emit HoneyReleasedFromBear(_fancyBears[i], releasable, msg.sender);
        }

        for(uint256 i = 0; i < _honeyJars.length; i++) {
            require(
                honeyJarsContract.ownerOf(_honeyJars[i]) == msg.sender,
                "claimAll: caller does not own honey jar token"
            );
            (bool overflowFlag, uint256 releasable) = getReleasableHoneyFromJar(_honeyJars[i], block.timestamp);
            require(overflowFlag, "claimAll: no vested honey due - ovfl");
            require(releasable!=0,"claimAll: no vested honey due - zero");
            honeyReleasedByJarId[_honeyJars[i]] += releasable;
            totalClaimableHoney += releasable;
            emit HoneyReleasedFromJar(_honeyJars[i], releasable, msg.sender);
        }

        require(totalClaimableHoney > 0, "claimAll: no vested honey due");

        honeyContract.safeTransfer(msg.sender, totalClaimableHoney);
    }

    function spendHoneyInBear(uint256 _tokenId, uint256 _amount) 
        external 
        cliffSet()
        onlyRole(HONEY_SPENDER_ROLE) 
    {

        require(
            _tokenId <= fancyBearsContract.totalSupply(), 
            "spendHoneyInBear: fancy bear token not valid"
        );

        require(
            honeySpentByBearId[_tokenId].add(_amount) <= honeyPerBear.sub(honeyReleasedByBearId[_tokenId]),
            "spendHoneyInBear: amount exceeds spend limit"
        ); 

        honeySpentByBearId[_tokenId] += _amount;
        spentHoneyBalance += _amount;

        emit HoneySpentFromBear(_tokenId, _amount, msg.sender);
    }

    function spendHoneyInJar(uint256 _tokenId, uint256 _amount) 
        external 
        cliffSet()
        onlyRole(HONEY_SPENDER_ROLE) 
    {
        require(
            _tokenId <= honeyJarsContract.totalSupply(), 
            "spendHoneyInJar: honey jar token not valid"
        );
        
        require(
            honeySpentByJarId[_tokenId].add(_amount) <= honeyPerJar.sub(honeyReleasedByJarId[_tokenId]),
            "spendHoneyInJar: amount exceeds spend limit"
        ); 

        honeySpentByJarId[_tokenId] += _amount;
        spentHoneyBalance += _amount;

        emit HoneySpentFromJar(_tokenId, _amount, msg.sender);
    }

    function spendHoney(
        uint256[] calldata _fancyBearTokens, 
        uint256[] calldata _amountPerFancyBearToken, 
        uint256[] calldata _honeyJarTokens,
        uint256[] calldata _amountPerHoneyJarToken
    )
        external
        cliffSet()
        onlyRole(HONEY_SPENDER_ROLE)
    {
        require(_fancyBearTokens.length == _amountPerFancyBearToken.length, "spendHoney: fancy bears token id array and amount array are different lengths");
        require(_honeyJarTokens.length == _amountPerHoneyJarToken.length, "spendHoney: honey jar token id array and amount array are different lengths");

        uint256 totalHoneySpent;

        for(uint256 i = 0; i < _fancyBearTokens.length; i++){
            require(
                honeySpentByBearId[_fancyBearTokens[i]].add(_amountPerFancyBearToken[i]) <= honeyPerBear.sub(honeyReleasedByBearId[_fancyBearTokens[i]]),
                "spendHoney: amount exceeds spend limit in fancy bear"
            ); 

            require(
                _amountPerFancyBearToken[i]!=0, 
                "spendHoney: amount must be greater than zero"
            );

            honeySpentByBearId[_fancyBearTokens[i]] += _amountPerFancyBearToken[i];
            totalHoneySpent += _amountPerFancyBearToken[i];
            emit HoneySpentFromBear(_fancyBearTokens[i], _amountPerFancyBearToken[i], msg.sender);
        }

        for(uint256 i = 0; i < _honeyJarTokens.length; i++){
            require(
                honeySpentByJarId[_honeyJarTokens[i]].add(_amountPerHoneyJarToken[i]) <= honeyPerJar.sub(honeyReleasedByJarId[_honeyJarTokens[i]]),
                "spendHoney: amount exceeds spend limit in honey jar"
            );

            require(
                _amountPerHoneyJarToken[i]!=0, 
                "spendHoney: amount must be greater than zero"
            );

            honeySpentByJarId[_honeyJarTokens[i]] += _amountPerHoneyJarToken[i]; 
            totalHoneySpent += _amountPerHoneyJarToken[i];
            emit HoneySpentFromJar(_honeyJarTokens[i], _amountPerHoneyJarToken[i], msg.sender);
        }

        spentHoneyBalance += totalHoneySpent;

    }

    function getVestingAmountRemainingInBearsByWallet(address _address) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tokenIds = fancyBearsContract.tokensInWallet(_address);
        uint256[] memory amounts = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++){
            amounts[i] = getVestingAmountRemainingInBearById(tokenIds[i]);
        }
        return (amounts, tokenIds);
    }

    function getVestingAmountRemainingInBearById(uint256 _tokenId) public view returns (uint256) {
        return honeyPerBear.sub(honeySpentByBearId[_tokenId]).sub(honeyReleasedByBearId[_tokenId]);
    }

    function getVestingAmountRemainingInJarsByWallet(address _address) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tokenIds = honeyJarsContract.tokensInWallet(_address);
        uint256[] memory amounts = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++){
            amounts[i] = getVestingAmountRemainingInJarById(tokenIds[i]);
        }
        return (amounts, tokenIds);
    }

    function getVestingAmountRemainingInJarById(uint256 _tokenId) public view returns (uint256) {
        return honeyPerJar.sub(honeySpentByJarId[_tokenId]).sub(honeyReleasedByJarId[_tokenId]);
    }

    function withdrawSpentHoney(uint256 _amount, address payable _destination) public onlyRole(WITHDRAW_ROLE) {
        
        require(
            _amount > 0,
            "withdrawSpentHoney: amount requested must be greater than 0"
        );
        
        require(
            _amount <= spentHoneyBalance, 
            "withdrawSpentHoney: not enough honey spent honey in vesting contract"
        );
        
        honeyContract.safeTransfer(_destination, _amount);
        spentHoneyBalance = spentHoneyBalance.sub(_amount);

        emit HoneyWithdraw(_amount, msg.sender, _destination);
    }

    function vestingScheduleForBear(uint256 _timestamp) public view returns (uint256) {
        return vestingSchedule(honeyPerBear, _timestamp);
    }

    function vestingScheduleForJar(uint256 _timestamp) public view returns (uint256) {
        return vestingSchedule(honeyPerJar, _timestamp);
    }

    function getReleasableHoneyFromBear(uint256 _tokenId, uint256 _timestamp) public view returns (bool, uint256) {
        return vestingScheduleForBear(_timestamp).trySub(honeyReleasedByBearId[_tokenId].add(honeySpentByBearId[_tokenId]));
    }

    function getReleasableHoneyFromJar(uint256 _tokenId, uint256 _timestamp) public view returns (bool, uint256) {
        return vestingScheduleForJar(_timestamp).trySub(honeyReleasedByJarId[_tokenId].add(honeySpentByJarId[_tokenId]));
    }

    function getBearStats(uint256 _tokenId, uint256 _timestamp) 
        public 
        view
        returns (uint256 releasable, uint256 released, uint256 spent, uint256 remaining) 
    {
        (,releasable) = getReleasableHoneyFromBear(_tokenId, _timestamp);
        released = honeyReleasedByBearId[_tokenId];
        spent = honeySpentByBearId[_tokenId];
        remaining = getVestingAmountRemainingInBearById(_tokenId);
    }

    function getJarStats(uint256 _tokenId, uint256 _timestamp) 
        public 
        view
        returns (uint256 releasable, uint256 released, uint256 spent, uint256 remaining) 
    {
        (,releasable) = getReleasableHoneyFromJar(_tokenId, _timestamp);
        released = honeyReleasedByJarId[_tokenId];
        spent = honeySpentByJarId[_tokenId];
        remaining = getVestingAmountRemainingInJarById(_tokenId);
    }

    function setCliffStart() public override(VestingCalculator) onlyRole(DEFAULT_ADMIN_ROLE) {
        super.setCliffStart();
    }

}