// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FireCatAccessControl} from "../src/utils/FireCatAccessControl.sol";
import {IFireCatReserves} from "../src/interfaces/IFireCatReserves.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";

/**
 * @title FireCat's Reserves Contract
 * @notice Add Reserves to this contract
 * @author FireCat Finance
 */
contract FireCatReserves is IFireCatReserves, FireCatTransfer, FireCatAccessControl {
    using SafeMath for uint256;

    event AddReserves(address user_, uint256 amount_, uint256 totalReserves_);
    event WithdrawReserves(address user_, uint256 amount_, uint256 totalReserves_);
    event SetReservesToken(address reservesToken_);
    
    address private _fireCatVault;
    address private  _reservesToken;
    uint private _totalReserves;

    /**
    * @dev Mapping from user address to reserves amount.
    */
    mapping(address => uint256) private _userReserves;

    function initialize(address token) initializer public {
        _reservesToken = token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);   
    }

    /// @inheritdoc IFireCatReserves
    function totalReserves() public view returns (uint256) {
        return _totalReserves;
    }

    /// @inheritdoc IFireCatReserves
    function reservesOf(address user) public view returns (uint256) {
        return _userReserves[user];
    }

    /// @inheritdoc IFireCatReserves
    function reservesToken() public view returns (address) {
        return _reservesToken;
    }

    /// @inheritdoc IFireCatReserves
    function addReserves(address user, uint256 addAmount) external onlyRole(FIRECAT_VAULT) returns (uint256) {
        require(IERC20(_reservesToken).balanceOf(msg.sender) >= addAmount, "RES:E01");
        uint totalReservesNew;
        uint actualAddAmount;

        actualAddAmount = doTransferIn(_reservesToken, msg.sender, addAmount);
        // totalReservesNew + actualAddAmount
        totalReservesNew = _totalReserves.add(actualAddAmount);

        /* Revert on overflow */
        require(totalReservesNew >= _totalReserves, "RES:E02");

        _totalReserves = totalReservesNew;
        _userReserves[user] = _userReserves[user].add(actualAddAmount);

        emit AddReserves(user, actualAddAmount, totalReservesNew);
        return actualAddAmount;
    }

    /// @inheritdoc IFireCatReserves
    function withdrawReserves(uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint) {
        require(amount <= _totalReserves, "RES:E01");
        uint totalReservesNew;
        uint actualSubAmount;

        actualSubAmount = doTransferOut(_reservesToken, msg.sender, amount);
        // totalReserves - actualSubAmount
        totalReservesNew = _totalReserves.sub(actualSubAmount);

        /* Revert on overflow */
        require(totalReservesNew <= _totalReserves, "RES:E03");
        _totalReserves = totalReservesNew;
        
        emit WithdrawReserves(msg.sender, actualSubAmount, totalReservesNew);
        return actualSubAmount;
    }

    /// @inheritdoc IFireCatReserves
    function withdrawRemaining(address token, address to, uint256 amount) external nonReentrant onlyRole(FIRECAT_VAULT) returns (uint) {
        require(token != _reservesToken, "RES:E04");
        return withdraw(token, to, amount);
    }

}