// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract TradingStakePool is Configurable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant _limit_ = "limit";
    bytes32 internal constant _DOTC_ = "DOTC";
    bytes32 internal constant _punishTo_ = "punishTo";
    bytes32 internal constant _expiry_ = "expiry";
    address public stakingToken;

    mapping(address => uint256) stakeTimes;

    uint256 private _entered;
    modifier nonReentrant() {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    mapping(address => uint256) public balanceOf;

    function __TradingStakePool_init(
        address _governor,
        address _stakingToken,
        uint256 limit_,
        address DOTC_,
        address punishTo_,
        uint256 expiry_
    ) public initializer {
        __Governable_init_unchained(_governor);
        __TradingStakePool_init_unchained(
            _stakingToken,
            limit_,
            DOTC_,
            punishTo_,
            expiry_
        );
    }

    function limit() public view virtual returns (uint256) {
        return config[_limit_];
    }

    function enough(address buyer) external view virtual returns (bool) {
        return balanceOf[buyer] >= limit();
    }

    function __TradingStakePool_init_unchained(
        address _stakingToken,
        uint256 limit_,
        address DOTC_,
        address punishTo_,
        uint256 expiry_
    ) internal governance initializer {
        stakingToken = _stakingToken;
        config[_limit_] = limit_;
        config[_DOTC_] = uint256(DOTC_);
        config[_punishTo_] = uint256(punishTo_);
        config[_expiry_] = expiry_; //now.add(expiry_);
    }

    function punish(address buyer, uint256 vol) external virtual nonReentrant {
        require(msg.sender == address(config[_DOTC_]), "only DOTC");
        address punishTo = address(config[_punishTo_]);
        uint256 amt = balanceOf[buyer];
        require(amt >= vol, "stake must GT punish vol");
        balanceOf[buyer] = amt.sub(vol);
        balanceOf[punishTo] = balanceOf[punishTo].add(vol);
        IERC20(stakingToken).safeTransferFrom(address(this), punishTo, vol);
        emit Punish(buyer, vol);
    }

    event Punish(address buyer, uint256 amt);

    function stake(uint256 amount) external virtual nonReentrant {
        amount;
        require(balanceOf[msg.sender] < config[_limit_], "already");
        uint256 realAmount = config[_limit_].sub(balanceOf[msg.sender]);
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            realAmount
        );
        stakeTimes[msg.sender] = now;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(realAmount);
        emit Stake(msg.sender, realAmount);
    }

    event Stake(address account, uint256 amount);

    function withdrawEnable(address account) public view returns (bool) {
        return ((now > stakeTimes[account].add(config[_expiry_])) &&
            (IDOTC(address(config[_DOTC_])).biddingN(account) == 0) &&
            (balanceOf[account] > 0));
    }

    function withdraw(uint256 amount) external virtual nonReentrant {
        amount;
        require(
            now > stakeTimes[msg.sender].add(config[_expiry_]),
            "only expired"
        );
        require(
            IDOTC(address(config[_DOTC_])).biddingN(msg.sender) == 0,
            "bidding"
        );
        uint256 realAmount = balanceOf[msg.sender];
        require(realAmount > 0, "No Stake to withdraw");
        IERC20(stakingToken).safeTransfer(msg.sender, realAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(realAmount);
        Withdraw(msg.sender, realAmount);
    }

    event Withdraw(address account, uint256 amount);

    // Reserved storage space to allow for layout changes in the future.
    uint256[49] private ______gap;
}

interface IDOTC {
    function biddingN(address buyer) external view returns (uint256);
}