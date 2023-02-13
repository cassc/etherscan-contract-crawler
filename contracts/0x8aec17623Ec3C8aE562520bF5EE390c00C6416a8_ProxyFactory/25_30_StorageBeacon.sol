// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/ethereum/IStorageBeacon.sol';
import '../libraries/LibCommon.sol';
import './ozUpgradeableBeacon.sol';
import '../Errors.sol';


/**
 * @title Main storage contract for the L1 side of the system.
 * @notice It acts as a separate centralized beacon that functions query for state
 * variables. It can be upgraded into different versions while keeping the older ones.
 */
contract StorageBeacon is IStorageBeacon, Initializable, Ownable {

    EmergencyMode eMode;

    mapping(address => bool) tokenDatabase;
    mapping(address => AccData) userToData;
    mapping(bytes4 => bool) authorizedSelectors;

    address[] tokenDatabaseArray;

    uint gasPriceBid;

    ozUpgradeableBeacon beacon;

    bool isEmitter;

    event L2GasPriceChanged(uint newGasPriceBid);
    event NewToken(address token);
    event TokenRemoved(address token);

    /// @dev Checks -using RolesAuthority- if the sender can call certain method
    modifier hasRole(bytes4 functionSig_) {
        require(beacon.canCall(msg.sender, address(this), functionSig_));
        _;
    }


    constructor(
        EmergencyMode memory eMode_,
        address[] memory tokens_,
        bytes4[] memory selectors_,
        uint gasPriceBid_
    ) {
        eMode = EmergencyMode({
            swapRouter: ISwapRouter(eMode_.swapRouter),
            priceFeed: AggregatorV3Interface(eMode_.priceFeed),
            poolFee: eMode_.poolFee,
            tokenIn: eMode_.tokenIn,
            tokenOut: eMode_.tokenOut
        });

        uint length = tokens_.length;
        for (uint i=0; i < length;) {
            tokenDatabase[tokens_[i]] = true;
            tokenDatabaseArray.push(tokens_[i]);
            unchecked { ++i; }
        }

        for (uint i=0; i < selectors_.length;) {
            authorizedSelectors[selectors_[i]] = true;
            unchecked { ++i; }
        }

        gasPriceBid = gasPriceBid_;
    }


    /*///////////////////////////////////////////////////////////////
                        State-changing functions
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc IStorageBeacon
    function multiSave(
        bytes20 account_,
        AccountConfig calldata acc_,
        bytes32 taskId_
    ) external hasRole(0x0854b85f) { 
        address user = acc_.user;
        bytes32 acc_user = bytes32(bytes.concat(account_, bytes12(bytes20(user))));
        bytes memory task_name = bytes.concat(taskId_, bytes32(bytes(acc_.name)));

        if (userToData[user].accounts.length == 0) {
            AccData storage data = userToData[user];
            data.accounts.push(address(account_));
            data.acc_userToTask_name[acc_user] = task_name;
        } else {
            userToData[user].accounts.push(address(account_));
            userToData[user].acc_userToTask_name[acc_user] = task_name;
        }
    }

    //@inheritdoc IStorageBeacon
    function changeGasPriceBid(uint newGasPriceBid_) external onlyOwner {
        gasPriceBid = newGasPriceBid_;
        emit L2GasPriceChanged(newGasPriceBid_);
    }

    //@inheritdoc IStorageBeacon
    function addTokenToDatabase(address newToken_) external onlyOwner {
        if (queryTokenDatabase(newToken_)) revert TokenAlreadyInDatabase(newToken_);
        tokenDatabase[newToken_] = true;
        tokenDatabaseArray.push(newToken_);
        emit NewToken(newToken_);
    }

    //@inheritdoc IStorageBeacon
    function removeTokenFromDatabase(address toRemove_) external onlyOwner {
        if (!queryTokenDatabase(toRemove_)) revert TokenNotInDatabase(toRemove_);
        tokenDatabase[toRemove_] = false;
        LibCommon.remove(tokenDatabaseArray, toRemove_);
        emit TokenRemoved(toRemove_);
    }

    //@inheritdoc IStorageBeacon
    function storeBeacon(address beacon_) external initializer { 
        beacon = ozUpgradeableBeacon(beacon_);
    }

    //@inheritdoc IStorageBeacon
    function changeEmergencyMode(EmergencyMode calldata newEmode_) external onlyOwner {
        eMode = newEmode_;
    }

    //@inheritdoc IStorageBeacon
    function changeEmitterStatus(bool newStatus_) external onlyOwner {
        isEmitter = newStatus_;
    }

    //@inheritdoc IStorageBeacon
    function addAuthorizedSelector(bytes4 selector_) external onlyOwner {
        authorizedSelectors[selector_] = true;
    }


    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc IStorageBeacon
    function isSelectorAuthorized(bytes4 selector_) external view returns(bool) {
        return authorizedSelectors[selector_];
    }

    //@inheritdoc IStorageBeacon
    function getGasPriceBid() external view returns(uint) {
        return gasPriceBid; 
    }
    
    //@inheritdoc IStorageBeacon
    function getEmergencyMode() external view returns(EmergencyMode memory) {
        return eMode;
    }

    //@inheritdoc IStorageBeacon
    function getAccountsByUser(
        address user_
    ) external view returns(address[] memory, string[] memory) {
        AccData storage data = userToData[user_];
        address[] memory accounts = data.accounts;
        string[] memory names = new string[](accounts.length);

        for (uint i=0; i < accounts.length; i++) {
            bytes memory task_name = 
                _getTask_Name(accounts[i], user_, data.acc_userToTask_name);
            bytes32 nameBytes;

            assembly {
                nameBytes := mload(add(task_name, 64))
            }
            names[i] = string(bytes.concat(nameBytes));
        }

        return (accounts, names);
    }

    /**
     * @dev Gets the bytes array compounded of the Account's name and its Gelato's task id
     */
    function _getTask_Name(
        address account_, 
        address owner_,
        mapping(bytes32 => bytes) storage acc_userToTask_name_
    ) private view returns(bytes memory) {
        bytes32 acc_user = bytes32(bytes.concat(bytes20(account_), bytes12(bytes20(owner_))));
        bytes memory task_name = acc_userToTask_name_[acc_user];
        return task_name;
    }

    //@inheritdoc IStorageBeacon
    function getTaskID(address account_, address owner_) external view returns(bytes32) {
        AccData storage data = userToData[owner_];
        if (data.accounts.length == 0) revert UserNotInDatabase(owner_);

        bytes memory task_name = _getTask_Name(account_, owner_, data.acc_userToTask_name);
        bytes32 taskId;
        assembly {
            taskId := mload(add(task_name, 32))
        }

        if (taskId == bytes32(0)) revert NoTaskId();
        return taskId;
    }

    /// @dev If token_ exists in L1 database
    function queryTokenDatabase(address token_) public view returns(bool) {
        return tokenDatabase[token_];
    }
    
    //@inheritdoc IStorageBeacon
    function isUser(address user_) external view returns(bool) {
        return userToData[user_].accounts.length > 0;
    }

    //@inheritdoc IStorageBeacon
    function getEmitterStatus() external view returns(bool) {
        return isEmitter;
    }

    //@inheritdoc IStorageBeacon
    function getTokenDatabase() external view returns(address[] memory) {
        return tokenDatabaseArray;
    }

    //@inheritdoc IStorageBeacon
    function verify(address user_, bytes32 acc_user_) external view returns(bool) {
        AccData storage data = userToData[user_];
        bytes memory task_name = data.acc_userToTask_name[acc_user_];
        return bytes32(task_name) != bytes32(0);
    }
}