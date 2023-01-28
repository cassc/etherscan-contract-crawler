// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Flipping Club - flippingclub.xyz
/**
 *  ______ _ _             _                _____ _       _
 * |  ____| (_)           (_)              / ____| |     | |
 * | |__  | |_ _ __  _ __  _ _ __   __ _  | |    | |_   _| |__
 * |  __| | | | '_ \| '_ \| | '_ \ / _` | | |    | | | | | '_ \
 * | |    | | | |_) | |_) | | | | | (_| | | |____| | |_| | |_) |
 * |_|    |_|_| .__/| .__/|_|_| |_|\__, |  \_____|_|\__,_|_.__/
 *            | |   | |             __/ |
 *   _____ _  |_|   |_|  _         |___/  _____            _                  _
 *  / ____| |      | |  (_)              / ____|          | |                | |
 * | (___ | |_ __ _| | ___ _ __   __ _  | |     ___  _ __ | |_ _ __ __ _  ___| |_
 *  \___ \| __/ _` | |/ / | '_ \ / _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|
 *  ____) | || (_| |   <| | | | | (_| | | |___| (_) | | | | |_| | | (_| | (__| |_
 * |_____/ \__\__,_|_|\_\_|_| |_|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                __/ |
 *                               |___/
 *
 * @title Flipping Club Staking Contract v2.1 - flippingclub.xyz
 * @author Flipping Club Team
 * @dev Using v1 contract for burn function so a new Approval is not required.
 * @notice Direct interaction with this contract not recommended. Always use the frontend provided.
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./stakeable.sol";
import "./NFTContractFunctions.sol";
import "./burnFunctions.sol";

contract FlippingClubStakingContract is Stakeable, Pausable, Ownable {
    using SafeMath for uint256;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));
    address private __checkKeys;
    address private __burnKeys;
    address private __migratingContract;
    event Claimed(uint256 indexed amount, address indexed payee);
    NFTContractFunctions private ERC721KeyCards;
    burnFunctions private ERC721KeyBurn;
    migratingSourceFunctions private MigratingStakes;
    struct StakePackage {
        uint256 duration;
        uint256 reward;
        uint256 min;
        uint256 max;
        bytes32 token;
    }

    mapping(uint256 => StakePackage[]) private Packages;
    

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
        _grantRole(EXEC, _newAdmin);
    }

    receive() external payable {}

    function addPackage(
        uint256 _name,
        uint256 duration,
        uint256 reward,
        uint256 min,
        uint256 max
    ) external onlyRole(ADMIN) {
        Packages[_name].push(
            StakePackage(
                duration,
                reward,
                min,
                max,
                keccak256(abi.encodePacked(duration, reward, min, max))
            )
        );
    }

    function getPackage(uint256 packageName)
        private
        view
        returns (StakePackage memory)
    {
        require(Packages[packageName].length > 0, "No Package");
        StakePackage memory package = Packages[packageName][0];
        return package;
    }

    function deletePackage(uint256 packageName) external onlyRole(ADMIN){
        require(Packages[packageName].length > 0, "No Package");
        delete Packages[packageName];
    }



    function beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        bytes32 token,
        uint256 poolID
    ) external payable nonReentrant whenNotPaused {
        address _spender = msg.sender;
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;
        require(token == package.token, "Package is not authorized.");
        require(
            isValidAmount(_amount, _minStakeValue, _maxStakeValue),
            "Value not in range"
        );
        require(msg.value == _amount, "Invalid amount sent.");
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Not all Keys owned by address."
        );
        require(checkKey() >= 1, "Address have no Key.");

        require(
            hasEnoughKeys(_amount, _reward, _keysToBeUsed.length),
            "Not enough Keys."
        );

        burnKeys(_keysToBeUsed, _spender);

        _stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _keysToBeUsed.length,
            poolID
        );
    }

    function exec_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256 _startTime,
        address _spender,
        uint256 _numKeys,
        uint256 poolID
    ) external nonReentrant onlyRole(EXEC) whenNotPaused {
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;
        require(
            isValidAmount(_amount, _minStakeValue, _maxStakeValue),
            "Value not in range"
        );
        require(hasEnoughKeys(_amount, _reward, _numKeys), "Not enough Keys.");

        _admin_stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _startTime,
            _numKeys,
            poolID
        );
    }

    function migrateStakes(
        uint256 poolID,
        uint256 _securityAddedTime,
        uint256 index
    ) external nonReentrant whenNotPaused {
        (uint256 _amount, uint256 _startTime, uint256 _reward, uint256 _timePeriodInSeconds, uint256 _accReturn, uint256 _numKeys) = getMigratingStake(msg.sender, index); 
        _timePeriodInSeconds = _timePeriodInSeconds.add(_securityAddedTime);
        _migrateStake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _startTime,
            _numKeys,
            _accReturn,
            poolID
        );
    }

    function withdrawStake(bool all, uint256 index)
        external
        nonReentrant
        whenNotPaused
    {
        require(_hasStake(msg.sender, index), "No active positions.");
        _withdrawStake(all, index);
    }

    function admin_withdraw_close(
        uint256 stake_index,
        address payable _spender,
        bool refund
    ) external onlyRole(ADMIN) {
        require(_hasStake(_spender, stake_index), "Nothing available.");
        _admin_withdraw_close(stake_index, _spender, refund);
    }

    function hasEnoughKeys(
        uint256 _amount,
        uint256 _reward,
        uint256 _numKeys
    ) private view returns (bool) {
        if (_amount.mul(_reward).div(100) <= _numKeys.mul(maxAllowancePerKey)) {
            return true;
        }
        return false;
    }

    function isValidAmount(
        uint256 _amount,
        uint256 _minStakeValue,
        uint256 _maxStakeValue
    ) private pure returns (bool) {
        if (_amount >= _minStakeValue && _amount <= _maxStakeValue) {
            return true;
        }
        return false;
    }

    function checkTokens(uint256[] memory _tokenList, address _msgSender)
        private
        view
        returns (bool)
    {
        require(__checkKeys != address(0), "Key Contract not set.");
        for (uint256 i = 0; i < _tokenList.length; i++) {
            if (ERC721KeyCards.ownerOf(_tokenList[i]) != _msgSender) {
                return false;
            }
        }
        return true;
    }

    function burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        public
        whenNotPaused
    {
        require(__burnKeys != address(0), "Delegated Burn not set.");
        ERC721KeyBurn.burnKeys(_keysToBeUsed, _spender);
    }

    function checkKey() private view returns (uint256) {
        require(__checkKeys != address(0), "Key Contract not set.");
        return ERC721KeyCards.balanceOf(msg.sender);
    }

    function initPool(uint256 _amount, address _payee)
        external
        nonReentrant
        onlyRole(ADMIN)
    {
        payable(_payee).transfer(_amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setCheckKeysContractAddress(address KeysContract)
        external
        onlyRole(ADMIN)
    {
        __checkKeys = KeysContract;
        ERC721KeyCards = NFTContractFunctions(__checkKeys);
    }

    function setBurnContractAddress(address BurnContract)
        external
        onlyRole(ADMIN)
    {
        __burnKeys = BurnContract;
        ERC721KeyBurn = burnFunctions(__burnKeys);
    }

    function setmaxAllowancePerKey(uint256 _maxAllowancePerKey)
        external
        onlyRole(ADMIN)
    {
        maxAllowancePerKey = _maxAllowancePerKey;
    }

    function pause() external whenNotPaused onlyRole(ADMIN) {
        _pause();
    }

    function unPause() external whenPaused onlyRole(ADMIN) {
        _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
        function setMigratingSourceContractAddress(address migratingSourceContract)
        external
        onlyRole(ADMIN)
    {
        __migratingContract = migratingSourceContract;
        MigratingStakes = migratingSourceFunctions(__migratingContract);
    }

    function getMigratingStake(address _staker, uint256 index)
        private
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
        return MigratingStakes.getSingleStake(_staker, index);
    }
}