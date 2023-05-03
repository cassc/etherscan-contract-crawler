// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IScoreManager.sol";

contract ScoreManager is
    IScoreManager,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    uint32 public numberOfTypes;

    // bytes: indicate the type of the score (like the name of the promotion)
    // address: user wallet address
    // bytes32: a byte stream of user score + etc
    mapping(uint256 => mapping(address => uint256)) public scores;

    // bytes32: a byte stream of aggregated info of users' scores (e.g., total sum)
    mapping(uint256 => uint256) public totalScores;
    mapping(address => bool) public allowedCallers;
    mapping(uint256 => bytes) public scoreTypes;
    mapping(bytes => uint256) public typeIds;

    uint256[44] public __gap;

    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event ScoreSet(address indexed user, uint256 score_typeID, uint256 score);
    event NewTypeAdded(uint256 Id, bytes ScoreType);


    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initialize to set variables on deployment
    /// @dev Deploys NFT contracts internally to ensure ownership is set to this contract
    /// @dev AuctionManager contract must be deployed first
    function initialize() external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /// @notice sets the score of a user
    /// @dev will be called by approved contracts that can set reward totals
    /// @param _typeId the ID of the type of the score
    /// @param _user the user to fetch the score for
    /// @param _score the score the user will receive in bytes form
    function setScore(
        uint256 _typeId,
        address _user,
        uint256 _score
    ) external allowedCaller(msg.sender) nonZeroAddress(_user) {
        require(_typeId <= numberOfTypes, "Invalid score type");
        scores[_typeId][_user] = _score;
        totalScores[_typeId] += _score;
        emit ScoreSet(_user, _typeId, _score);
    }

    /// @notice updates the status of a caller
    /// @param _caller the address of the contract or EOA that is being updated
    /// @param _flag the bool value to update by
    function setCallerStatus(address _caller, bool _flag) external onlyOwner nonZeroAddress(_caller) {
        allowedCallers[_caller] = _flag;
    }

    /// @notice creates a new type of score
    /// @param _type the bytes value type being added
    function addNewScoreType(bytes memory _type) external onlyOwner returns (uint256) {
        scoreTypes[numberOfTypes] = _type;
        typeIds[_type] = numberOfTypes;

        emit NewTypeAdded(numberOfTypes, _type);

        numberOfTypes++;
        return numberOfTypes - 1;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //------------------------------------  GETTERS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier allowedCaller(address _caller) {
        require(allowedCallers[_caller], "Caller not permissioned");
        _;
    }

    modifier nonZeroAddress(address _user) {
        require(_user != address(0), "Cannot be address zero");
        _;
    }
}