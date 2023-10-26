// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "../../../core/emission/libraries/MiningPool.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";

contract ERC1155BurnMiningV1 is MiningPool, ERC1155Holder {
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _burned;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        virtual
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155BurnMiningV1(0).burn.selector);
        _registerInterface(ERC1155BurnMiningV1(0).exit.selector);
        _registerInterface(ERC1155BurnMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector);
    }

    function burn(uint256 tokenId, uint256 amount) public virtual {
        _dispatch(msg.sender, tokenId, amount);
        ERC1155Burnable(baseToken()).burn(msg.sender, tokenId, amount);
    }

    function exit(uint256 tokenId) public virtual {
        // transfer vision token
        _mine();
        uint256 burnedAmount = _burned[msg.sender][tokenId];
        _burned[msg.sender][tokenId] = 0;
        // withdraw all miners for the given token id
        uint256 minersToWithdraw =
            dispatchableMiners(tokenId).mul(burnedAmount);
        _withdrawMiners(minersToWithdraw);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        _dispatch(from, id, value);
        ERC1155Burnable(baseToken()).burn(address(this), id, value);
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
            _dispatch(from, ids[i], values[i]);
            ERC1155Burnable(baseToken()).burn(address(this), ids[i], values[i]);
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

    function erc1155BurnMiningV1() external pure returns (bool) {
        return true;
    }

    function _dispatch(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        uint256 minersToDispatch = dispatchableMiners(tokenId).mul(amount);
        _dispatchMiners(account, minersToDispatch);
        _burned[account][tokenId] = _burned[account][tokenId].add(amount);
    }
}