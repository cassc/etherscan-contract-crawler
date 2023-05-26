//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libs/token/ERC20/IERC20.sol";
import "./libs/utils/ReentrancyGuard.sol";
import "./libs/utils/Utils.sol";
import "./libs/math/SafeMath.sol";

contract TokenSwap is ReentrancyGuard {
    using SafeMath for uint256;

    /// legacy zil address
    address private _address0;
    /// wrapped zil address
    address private _address1;

    address private _admin;

    address private _payer;

    event SwapEvent(
        address indexed sender,
        uint256 amount
    );

    constructor (address address0, address address1, address admin, address initPayer) {
        _address0 = address0;
        _address1 = address1;
        _admin = admin;
        _payer = initPayer;
    }

    function swap(
        uint256 _callAmount
    )
        external
        nonReentrant
        returns (bool)
    {
        IERC20 token0 = IERC20(_address0);
        bool burnt = token0.burnFrom(msg.sender, _callAmount);
        require(burnt, "burnt failed");
        IERC20 token1 = IERC20(_address1);
        bool transferred = token1.transferFrom(_payer, msg.sender,_callAmount);
        require(transferred, "transfer failed");
        emit SwapEvent(msg.sender, _callAmount);
        return true;
    }

    function changePayer(address newPayer) external nonReentrant returns (bool) {
        require(msg.sender == _admin,"sender should be admin");
        _payer = newPayer;
        return true;
    }

    function payer() public view returns (address) {
        return _payer;
    }
}