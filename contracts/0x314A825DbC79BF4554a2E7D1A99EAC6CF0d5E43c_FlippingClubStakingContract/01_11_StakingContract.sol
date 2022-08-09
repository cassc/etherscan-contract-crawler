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
 * @title Flipping Club Staking Contract v2.2 - flippingclub.xyz
 * @author Flipping Club Team
 * @dev Using v1 contract for burn function so a new Approval is not required. This version includes Minor improvements. 
 * @notice Direct interaction with this contract not recommended. Always use the frontend provided.
 */

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./stakeable.sol";
import "./IClaim.sol";
import "./NFTContractFunctions.sol";
import "./burnFunctions.sol";

contract FlippingClubStakingContract is Stakeable, Pausable, Ownable {
    using SafeMath for uint256;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));
    bool private delegateBurn = true;
    address private __checkKeys;
    address private __burnKeys;
    address private _claimContract;
    event LogDepositReceived(address indexed payee);
    event Claimed(uint256 indexed amount, address indexed payee);
    NFTContractFunctions private ERC721KeyCards;
    burnFunctions private ERC721KeyBurn;
    struct StakePackage {
        uint256 duration;
        uint256 reward;
        uint256 min;
        uint256 max;
    }
    mapping(uint256 => StakePackage[]) private Packages;

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
        _grantRole(EXEC, _newAdmin);
    }

    receive() external payable {
        emit LogDepositReceived(msg.sender);
    }

    function addPackage(
        uint256 _name,
        uint256 duration,
        uint256 reward,
        uint256 min,
        uint256 max
    ) public {
        Packages[_name].push(StakePackage(duration, reward, min, max));
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

    function beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed
    ) external payable nonReentrant whenNotPaused {
        _beginStake(_amount, _package, _keysToBeUsed, msg.sender);
    }

    function exec_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256 _startTime,
        address _spender,
        uint256 _numKeys
    ) external nonReentrant onlyRole(EXEC) whenNotPaused {
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;
        require(
            _amount >= _minStakeValue && _amount <= _maxStakeValue,
            "Value not in range"
        );
        require(
            _amount.mul(_reward).div(100) <= _numKeys.mul(maxAllowancePerKey),
            "Not enough Keys."
        );

        _admin_stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _startTime,
            _numKeys
        );
    }

    function _beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) private {
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;

        require(
            _amount >= _minStakeValue && _amount <= _maxStakeValue,
            "Stake value not in range"
        );
        require(msg.value == _amount, "Invalid amount sent.");
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Not all Keys owned by address."
        );
        require(checkKey() >= 1, "Address have no Key.");

        require(
            _amount.mul(_reward).div(100) <=
                _keysToBeUsed.length.mul(maxAllowancePerKey),
            "Not enough Keys."
        );
        delegateBurn
            ? burnKeys(_keysToBeUsed, _spender)
            : _burnKeys(_keysToBeUsed, _spender);

        _stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _keysToBeUsed.length
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
        
    {
        require(__burnKeys != address(0), "Delegated Burn not set.");
        ERC721KeyBurn.burnKeys(_keysToBeUsed, _spender);
    }

    function _burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        public
        
    {
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(_spender, address(this)) ==
                    true,
                "BurnKeys: Contract is not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                _spender,
                burnAddress,
                _keysToBeUsed[i]
            );
        }
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

    function initClaim(uint256 _amount, address _payee)
        external
        nonReentrant
        whenNotPaused
        onlyRole(CLAIM)
    {
        require(address(this).balance > _amount, "Not enough balance.");
        payable(_payee).transfer(_amount);
        emit Claimed(_amount, _payee);
    }

    function broadcastClaim(address payable _payee, uint256 _amount)
        external
        payable
        onlyRole(EXEC)
        nonReentrant
        whenNotPaused
    {
        require(_claimContract != address(0), "Claim Contract not set.");
        IClaim(_claimContract).initClaim{value: msg.value}(_payee, _amount);
        emit Claimed(_amount, _payee);
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

    function setClaimContract(address ClaimContract) external onlyRole(ADMIN) {
        _claimContract = ClaimContract;
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

    function setDelegateBurn(bool status) external {
        delegateBurn = status;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}