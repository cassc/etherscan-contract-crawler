// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./AbstractRewards.sol";

abstract contract BasePool is ERC20, AbstractRewards {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    address public stakingToken;

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 indexed rewardAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingToken
    ) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(
            _stakingToken != address(0),
            "BasePool.constructor: staking token is not set"
        );

        stakingToken = _stakingToken;
    }

    function _mint(address _account, uint256 _amount)
        internal
        virtual
        override
    {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(address _account, uint256 _amount)
        internal
        virtual
        override
    {
        super._burn(_account, _amount);
        _correctPoints(_account, _amount.toInt256());
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._transfer(_from, _to, _value);
        _correctPointsForTransfer(_from, _to, _value);
    }
}