// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {SafeMath} from "../lib/SafeMath.sol";

import {IMintableToken} from "../token/IMintableToken.sol";
import {BaseERC20} from "./BaseERC20.sol";

contract ArcxTokenV2 is BaseERC20, IMintableToken, Ownable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;

    /* ========== Variables ========== */

    address public pauseOperator;
    bool public isPaused;

    uint8 public version;
    BaseERC20 public oldArcxToken;

    /* ========== Events ========== */

    event Claimed(
        address _owner,
        uint256 _amount
    );

    event OtherOwnershipTransfered(
        address _targetContract,
        address _newOwner
    );

    event PauseStatusUpdated(bool _status);

    event PauseOperatorUpdated(
        address _pauseOperator
    );

    // ============ Modifiers ============

    modifier isNotPaused() {
        require (
            isPaused == false,
            "ArcxTokenV2: contract is paused"
        );
        _;
    }

    // ============ Constructor ============

    constructor(
        string memory name,
        string memory symbol,
        address _oldArcxToken
    )
        public
        BaseERC20(name, symbol, 18)
    {
        require(
            _oldArcxToken != address(0),
            "ArcxTokenV2: old ARCX token cannot be address 0"
        );

        oldArcxToken = BaseERC20(_oldArcxToken);
        version = 2;

        pauseOperator = msg.sender;
        isPaused = false;
    }

    // ============ Core Functions ============

    function mint(
        address to,
        uint256 value
    )
        external
        onlyOwner
    {
        _mint(to, value);
    }

    function burn(
        address to,
        uint256 value
    )
        external
        onlyOwner
    {
        _burn(to, value);
    }

    // ============ Migration Function ============

    /**
     * @dev Transfers the old tokens to the owner and
     *      mints the new tokens, respecting a 1 : 10,000 ratio.
     *
     * @notice Convert the old tokens from the old ARCX token to the new (this one).
     */
    function claim()
        external
        isNotPaused
    {
        uint256 balance = oldArcxToken.balanceOf(msg.sender);
        uint256 newBalance = balance.mul(10000);

        require(
            balance > 0,
            "ArcxTokenV2: user has 0 balance of old tokens"
        );

        // Burn old balance
        IMintableToken oldToken = IMintableToken(address(oldArcxToken));

        oldToken.burn(
            msg.sender,
            balance
        );

        // Mint new balance
        _mint(
            msg.sender,
            newBalance
        );

        emit Claimed(
            msg.sender,
            newBalance
        );
    }

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        isNotPaused
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        isNotPaused
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );

        return true;
    }

    // ============ Restricted Functions ============

    function transferOtherOwnership(
        address _targetContract,
        address _newOwner
    )
        external
        onlyOwner
    {
        Ownable ownableContract = Ownable(_targetContract);

        require(
            ownableContract.owner() == address(this),
            "ArcxTokenV2: this contract is not the owner of the target"
        );

        ownableContract.transferOwnership(_newOwner);

        emit OtherOwnershipTransfered(
            _targetContract,
            _newOwner
        );
    }

    function updatePauseOperator(
        address _newPauseOperator
    )
        external
        onlyOwner
    {
        pauseOperator = _newPauseOperator;

        emit PauseOperatorUpdated(_newPauseOperator);
    }

    function setPause(
        bool _pauseStatus
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "ArcxTokenV2: caller is not pause operator"
        );

        isPaused = _pauseStatus;

        emit PauseStatusUpdated(_pauseStatus);
    }
}