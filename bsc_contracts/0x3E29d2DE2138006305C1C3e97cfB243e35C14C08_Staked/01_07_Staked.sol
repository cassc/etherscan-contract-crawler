//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./security/ReEntrancyGuard.sol";
import "./Stakeable.sol";

contract Staked is Context, Ownable, ReEntrancyGuard, Stakeable {
    IERC20 private BEB20Token;

    struct TypeStake {
        uint256 rewardRate;
        uint256 rewardPerMonth;
        uint256 day;
        bool status;
    }

    // @dev minimum tokens for staking
    uint256 public minStaked = 0; // 100 Token

    mapping(uint256 => TypeStake) _Stake;
    uint256 public _stakeCount;

    constructor(address _dlyTokenAddress) {
        BEB20Token = IERC20(_dlyTokenAddress);
        _stakeCount = 0;
    }

    // @dev  register staking types
    function registerStake(
        uint256 _rewardRate,
        uint256 _rewardPerMonth,
        uint256 _day,
        bool _status
    ) external onlyOwner {
        _Stake[_stakeCount] = TypeStake(
            _rewardRate,
            _rewardPerMonth,
            _day,
            _status
        );
        _stakeCount++;
    }

    // @dev we return all registered staking types
    function stakeList() external view returns (TypeStake[] memory) {
        unchecked {
            TypeStake[] memory stakes = new TypeStake[](_stakeCount);
            for (uint256 i = 0; i < _stakeCount; i++) {
                TypeStake storage s = _Stake[i];
                stakes[i] = s;
            }
            return stakes;
        }
    }

    // @dev we get the blocking days of a staking type
    function getDays(uint256 _day) public pure returns (uint256) {
        return _day * 1 days;
    }

    // we deactivate establishment
    function disableStake(uint256 id)
        external
        onlyOwner
        returns (bool success)
    {
        _Stake[id].status = false;
        return true;
    }

    // we deactivate establishment
    function enableStake(uint256 id) external onlyOwner returns (bool success) {
        _Stake[id].status = true;
        return true;
    }

    // ---------- STAKES ----------

    // @dev Add functionality like "burn" to the _stake afunction
    function stake(uint256 _amount, uint256 _idStake)
        external
        noReentrant
        returns (bool)
    {
        // @dev Make sure staker actually is good for it
        require(
            _amount < balanceOfdly(_msgSender()),
            "Cannot stake more than you own"
        );

        // @dev the initial amount must be greater than 100 token
        require(
            _amount >= minStaked,
            "the initial amount must be greater than 100 token"
        );

        // @dev
        TypeStake storage s = _Stake[_idStake];

        // @dev
        require(s.status, "not available");

        // "Burn" the amount of tokens on the sender
        require(BEB20Token.transferFrom(
            _msgSender(),
            address(this),
            _amount
        ), "Failed to transfer tokens from user to vendor");

        // @dev Add the stake to the stake array
        _stake(_amount, getDays(s.day), s.rewardRate, s.rewardPerMonth);

        return true;
    }

    // @dev  withdrawStake is used to withdraw stakes from the account holder
    function withdrawStake(uint256 amount, uint256 stake_index)
        external
        noReentrant
        returns (bool)
    {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);

        // Return staked tokens to user
        // Transfer token to the msg.sender
        bool sent = BEB20Token.transfer(_msgSender(), amount_to_mint);
        require(sent, "Failed to transfer token to user");

        return true;
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */

    function totalStakes() external view returns (uint256) {
        return _totalStakes();
    }

    /**
     * @dev change minimum purchase amount
     */
    function changeMinStaked(uint256 _minStaked)
        public
        onlyOwner
        returns (bool)
    {
        minStaked = _minStaked;
        return true;
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfdly(address _address) public view returns (uint256) {
        return BEB20Token.balanceOf(_address);
    }

    // @dev  we remove the liquidity of the contract
    function withdraw(uint256 amount)
        external
        onlyOwner
        noReentrant
        returns (bool)
    {
        // Transfer token to the msg.sender
        bool sent = BEB20Token.transfer(_msgSender(), amount);
        require(sent, "Failed to transfer token to user");
        return sent;
    }

    // This fallback/receive function
    // will keep all the Ether
    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}