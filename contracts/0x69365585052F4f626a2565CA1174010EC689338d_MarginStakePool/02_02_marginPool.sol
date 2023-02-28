// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract MarginStakePool is Configurable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //bytes32 internal constant _DOTC_            = 'DOTC';

    uint256 private _entered;
    modifier nonReentrant() {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    address public stakingToken;
    address public dotcAddr;

    mapping(address => uint256) public balanceOf;

    function __TradingStakePool_init(
        address _governor,
        address _stakingToken,
        address _dotcAddr
    ) public initializer {
        __Governable_init_unchained(_governor);
        __TradingStakePool_init_unchained(_stakingToken, _dotcAddr);
    }

    function __TradingStakePool_init_unchained(
        address _stakingToken,
        address _dotcAddr
    ) internal governance initializer {
        stakingToken = _stakingToken;
        dotcAddr = _dotcAddr;
    }

    function setDOTCAddr(address _dotcAddr) external governance {
        dotcAddr = _dotcAddr;
    }

    function punish(
        address from,
        address to,
        uint256 vol
    ) external virtual nonReentrant {
        require(msg.sender == dotcAddr, "only DOTC");
        uint256 amt = balanceOf[from];
        require(amt >= vol, "stake must GT punish vol");
        balanceOf[from] = amt.sub(vol);
        IERC20(stakingToken).safeTransferFrom(address(this), to, vol);
        emit Punish(from, to, vol);
    }

    event Punish(address from, address to, uint256 amt);

    function stake(address account, uint256 amount)
        external
        virtual
        nonReentrant
    {
        require(msg.sender == dotcAddr, "only DOTC");
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        balanceOf[account] = balanceOf[account].add(amount);
        emit Stake(account, amount);
    }

    event Stake(address account, uint256 amount);

    function withdraw(address account, uint256 amount)
        external
        virtual
        nonReentrant
    {
        require(msg.sender == dotcAddr, "only DOTC");
        IERC20(stakingToken).safeTransfer(account, amount);
        balanceOf[account] = balanceOf[account].sub(amount);
        Withdraw(account, amount);
    }

    event Withdraw(address account, uint256 amount);

    // Reserved storage space to allow for layout changes in the future.
    uint256[47] private ______gap;
}