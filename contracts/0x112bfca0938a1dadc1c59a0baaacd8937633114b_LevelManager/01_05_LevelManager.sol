//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
import "./MultiSigOwner.sol";
import "./Manager.sol";
import "./interfaces/ICard.sol";
import "./libraries/SafeMath.sol";

contract LevelManager is MultiSigOwner, Manager {
    using SafeMath for uint256;
    // current user level of each user. 1~5 level enabled.
    mapping(address => uint256) public usersLevel;
    // the time okse amount is updated
    mapping(address => uint256) public usersOkseUpdatedTime;
    // this is validation period after user change his okse balance for this contract, normally is 30 days. we set 10 mnutes for testing.
    uint256 public levelValidationPeriod;
    // daily limit contants
    uint256 public constant MAX_LEVEL = 5;
    uint256[] public OkseStakeAmounts;
    event UserLevelChanged(address userAddr, uint256 newLevel);
    event OkseStakeAmountChanged(uint256 index, uint256 _amount);
    event LevelValidationPeriodChanged(uint256 levelValidationPeriod);

    constructor(address _cardContract) Manager(_cardContract) {
        levelValidationPeriod = 1 days;
        // levelValidationPeriod = 10 minutes; //for testing
        OkseStakeAmounts = [
            5000 ether,
            25000 ether,
            50000 ether,
            100000 ether,
            250000 ether
        ];
    }

    ////////////////////////// Read functions /////////////////////////////////////////////////////////////
    function getUserLevel(address userAddr) public view returns (uint256) {
        uint256 newLevel = getLevel(
            ICard(cardContract).getUserOkseBalance(userAddr)
        );
        if (newLevel < usersLevel[userAddr]) {
            return newLevel;
        } else {
            if (
                usersOkseUpdatedTime[userAddr].add(levelValidationPeriod) <
                block.timestamp
            ) {
                return newLevel;
            } else {
                // do something ...
            }
        }
        return usersLevel[userAddr];
    }

    /**
     * @notice Get user level from his okse balance
     * @param _okseAmount okse token amount
     * @return user's level, 0~5 , 0 => no level
     */
    // verified
    function getLevel(uint256 _okseAmount) public view returns (uint256) {
        if (_okseAmount < OkseStakeAmounts[0]) return 0;
        if (_okseAmount < OkseStakeAmounts[1]) return 1;
        if (_okseAmount < OkseStakeAmounts[2]) return 2;
        if (_okseAmount < OkseStakeAmounts[3]) return 3;
        if (_okseAmount < OkseStakeAmounts[4]) return 4;
        return 5;
    }

    ///////////////// CallBack functions from card contract //////////////////////////////////////////////
    function updateUserLevel(address userAddr, uint256 beforeAmount)
        external
        onlyFromCardContract
        returns (bool)
    {
        uint256 newLevel = getLevel(
            ICard(cardContract).getUserOkseBalance(userAddr)
        );
        if (
            usersOkseUpdatedTime[userAddr].add(levelValidationPeriod) <
            block.timestamp
        ) {
            usersLevel[userAddr] = getLevel(beforeAmount);
        }

        if (newLevel != usersLevel[userAddr])
            usersOkseUpdatedTime[userAddr] = block.timestamp;
        if (newLevel == usersLevel[userAddr]) return true;
        if (newLevel < usersLevel[userAddr]) {
            usersLevel[userAddr] = newLevel;
            emit UserLevelChanged(userAddr, newLevel);
        } else {
            if (
                usersOkseUpdatedTime[userAddr].add(levelValidationPeriod) <
                block.timestamp
            ) {
                usersLevel[userAddr] = newLevel;
                emit UserLevelChanged(userAddr, newLevel);
            } else {
                // do somrthing ...
            }
        }
        return false;
    }

    //////////////////// Owner functions ////////////////////////////////////////////////////////////////
    // verified
    function setLevelValidationPeriod(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "setLevelValidationPeriod") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        uint256 _newValue = abi.decode(params, (uint256));
        levelValidationPeriod = _newValue;
        emit LevelValidationPeriodChanged(levelValidationPeriod);
    }

    // verified
    function setOkseStakeAmount(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setOkseStakeAmount")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (uint256 index, uint256 _amount) = abi.decode(
            params,
            (uint256, uint256)
        );
        require(index < MAX_LEVEL, "level<5");
        OkseStakeAmounts[index] = _amount;
        emit OkseStakeAmountChanged(index, _amount);
    }
}