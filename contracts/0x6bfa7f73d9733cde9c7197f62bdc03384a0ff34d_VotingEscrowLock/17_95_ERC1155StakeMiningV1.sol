// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC1155StakeMiningV1 is MiningPool, ERC1155Holder {
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _staking;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155StakeMiningV1(0).stake.selector);
        _registerInterface(ERC1155StakeMiningV1(0).mine.selector);
        _registerInterface(ERC1155StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC1155StakeMiningV1(0).exit.selector);
        _registerInterface(ERC1155StakeMiningV1(0).dispatchableMiners.selector);
        _registerInterface(
            ERC1155StakeMiningV1(0).erc1155StakeMiningV1.selector
        );
    }

    function stake(uint256 id, uint256 amount) public {
        bytes memory zero;
        IERC1155(baseToken()).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            amount,
            zero
        );
    }

    function withdraw(uint256 tokenId, uint256 amount) public {
        uint256 staked = _staking[msg.sender][tokenId];
        require(staked >= amount, "Withdrawing more than staked.");
        _staking[msg.sender][tokenId] = staked - amount;
        uint256 miners = dispatchableMiners(tokenId).mul(amount);
        _withdrawMiners(miners);
        bytes memory zero;
        IERC1155(baseToken()).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            zero
        );
    }

    function mine() public {
        _mine();
    }

    function exit(uint256 tokenId) public {
        mine();
        withdraw(tokenId, _staking[msg.sender][tokenId]);
    }

    function _stake(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _staking[account][tokenId] = _staking[account][tokenId].add(amount);
        uint256 miners = dispatchableMiners(tokenId).mul(amount);
        _dispatchMiners(account, miners);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        _stake(from, id, value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(ids.length == values.length, "Not a valid input");
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(from, ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256)
        public
        view
        virtual
        returns (uint256 numOfMiner)
    {
        return 1;
    }

    function erc1155StakeMiningV1() external pure returns (bool) {
        return true;
    }
}