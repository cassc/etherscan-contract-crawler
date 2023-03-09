//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;


import "./Controller.sol";
import "./MinterManagerInterface.sol";
import {Ownable} from "../TokenContracts/Ownable.sol";

contract MintController is Controller {

    /*
     * @title MinterManagementInterface
     * @notice MintController calls the minterManager to execute/record minter
     * management tasks, as well as to query the status of a minter address.
     */
    MinterManagementInterface internal minterManager;
    mapping(address => uint256) internal minterAllowance;
    mapping(address => uint256) internal minterCap;

    event MinterManagerSet(
        address indexed _oldMinterManager,
        address indexed _newMinterManager
    );
    event MinterConfigured(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _allowance
    );
    event MinterRemoved(address indexed _msgSender, address indexed _minter);
    event MinterAllowanceIncremented(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _increment,
        uint256 _newAllowance
    );

    event MinterAllowanceDecremented(
        address indexed msgSender,
        address indexed minter,
        uint256 decrement,
        uint256 newAllowance
    );

    /*
     * @notice Initializes the minterManager.
     * @param _minterManager The address of the minterManager contract.
     */
    function initializeMintController(address _minterManager, uint256 _initMaxNumOfMinters) public initializer {
        Ownable.initialize(msg.sender);
        _maxNumOfMinters = _initMaxNumOfMinters;
        minterManager = MinterManagementInterface(_minterManager);
    }

    /*
     * @notice gets the minterManager
     */
    function getMinterManager()
        external
        view
        returns (MinterManagementInterface)
    {
        return minterManager;
    }

    // onlyOwner functions

    /**
     * @notice Sets the minterManager.
     * @param _newMinterManager The address of the new minterManager contract.
     */
    function setMinterManager(address _newMinterManager) external onlyOwner {
        emit MinterManagerSet(address(minterManager), _newMinterManager);
        minterManager = MinterManagementInterface(_newMinterManager);
    }

    // onlyController functions

    /**
     * @notice Removes the controller's own minter.
     */
    function removeMinter(address _minter)
        external
        onlyController
        returns (bool)
    {
        require(
            controllers[msg.sender].length != 0,
            "controller has no minters"
        );
        for (uint256 i; i < controllers[msg.sender].length; i++) {
            if (controllers[msg.sender][i] == _minter) {
                minterController[_minter] = address(0);
                controllers[msg.sender][i] = controllers[msg.sender][controllers[msg.sender].length-1];
                isMinter[_minter] = false;
                controllers[msg.sender].pop();
                emit MinterRemoved(msg.sender, _minter);
                return minterManager.removeMinter(_minter);
            }
        }
        return false;
    }

    /**
     * @notice Enables the minter and sets its allowance.
     * @param _newAllowance New allowance to be set for minter.
     */
    function configureMinter(
        address _minter,
        uint256 _newAllowance   
    ) external onlyController returns (bool) {
        require(_minter != address(0), "No zero addr");
        require(controllers[msg.sender].length <= _maxNumOfMinters, "number of minters for controller exceeded");
        //total minted vs allowance
        if (minterController[_minter] == address(0)) {
            minterController[_minter] = msg.sender;
            require(controllers[msg.sender].length + 1 <= _maxNumOfMinters, "number of minters for controller exceeded");



            controllers[msg.sender].push(_minter);
            
        }
        require(
            minterController[_minter] == msg.sender,
            "minter has controller"
        );
        isMinter[_minter] = true;
        minterAllowance[_minter] = _newAllowance;
        emit MinterConfigured(msg.sender, _minter, _newAllowance);
        return
            _setMinterAllowance(
                _minter,
                _newAllowance
            );
    }

    /**
     * @notice Increases the minter's allowance if and only if the minter is an
     * active minter.
     * @dev An minter is considered active if minterManager.isMinter(minter)
     * returns true.
     */
    function incrementMinterAllowance(
        uint256 _allowanceIncrement,
        address _minter
    ) external onlyController returns (bool) {
        require(_allowanceIncrement > 0, "increment too small");
        require(minterManager.isMinter(_minter), "only for minter allowance");

        uint256 currentAllowance = minterManager.getMinterAllowance(_minter);
        uint256 newAllowance = currentAllowance + _allowanceIncrement;

        emit MinterAllowanceIncremented(
            msg.sender,
            _minter,
            _allowanceIncrement,
            newAllowance
        );

        return
            _setMinterAllowance(
                _minter,
                newAllowance
            );
    }

    /**
     * @notice decreases the minter allowance if and only if the minter is
     * currently active. The controller can safely send a signed
     * decrementMinterAllowance() transaction to a minter and not worry
     * about it being used to undo a removeMinter() transaction.
     */
    function decrementMinterAllowance(
        uint256 _allowanceDecrement,
        address _minter
    ) external onlyController returns (bool) {
        require(_allowanceDecrement > 0, "allowance too small");
        require(
            minterController[_minter] == msg.sender,
            "not minter's controller"
        );
        require(minterManager.isMinter(_minter), "only for minter allowance");

        uint256 currentAllowance = minterManager.getMinterAllowance(_minter);

        uint256 actualAllowanceDecrement = (
            currentAllowance > _allowanceDecrement
                ? _allowanceDecrement
                : currentAllowance
        );

        uint256 newAllowance = currentAllowance - actualAllowanceDecrement;

        emit MinterAllowanceDecremented(
            msg.sender,
            _minter,
            actualAllowanceDecrement,
            newAllowance
        );
        return
            _setMinterAllowance(
                _minter,
                newAllowance
            );
    }

    // Internal functions

    /**
     * @notice Uses the MinterManagementInterface to enable the minter and
     * set its allowance.
     * @param _minter Minter to set new allowance of.
     * @param _newAllowance New allowance to be set for minter.
     */
    function _setMinterAllowance(
        address _minter,
        uint256 _newAllowance
    ) internal returns (bool) {
        return
            minterManager.configureMinter(
                _minter,
                _newAllowance
            );
    }
}