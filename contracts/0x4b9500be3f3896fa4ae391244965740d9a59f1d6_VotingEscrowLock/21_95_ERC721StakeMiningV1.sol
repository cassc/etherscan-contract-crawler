// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC721StakeMiningV1 is MiningPool, ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(address => EnumerableSet.UintSet) private _stakedTokensOf;
    EnumerableMap.UintToAddressMap private _stakers;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC721StakeMiningV1(0).stake.selector);
        _registerInterface(ERC721StakeMiningV1(0).mine.selector);
        _registerInterface(ERC721StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC721StakeMiningV1(0).exit.selector);
        _registerInterface(ERC721StakeMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC721StakeMiningV1(0).erc721StakeMiningV1.selector);
    }

    function stake(uint256 id) public {
        IERC721(baseToken()).safeTransferFrom(msg.sender, address(this), id);
    }

    function withdraw(uint256 tokenId) public {
        require(
            _stakers.get(tokenId) == msg.sender,
            "Only staker can withdraw"
        );
        _stakedTokensOf[msg.sender].remove(tokenId);
        _stakers.remove(tokenId);
        uint256 miners = dispatchableMiners(tokenId);
        _withdrawMiners(miners);
        IERC721(baseToken()).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function mine() public {
        _mine();
    }

    function exit() public {
        mine();
        uint256 bal = _stakedTokensOf[msg.sender].length();
        for (uint256 i = 0; i < bal; i++) {
            uint256 tokenId = _stakedTokensOf[msg.sender].at(i);
            withdraw(tokenId);
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public override returns (bytes4) {
        _stake(from, tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256 tokenId)
        public
        view
        virtual
        returns (uint256 numOfMiner)
    {
        if (IERC721(baseToken()).ownerOf(tokenId) != address(0)) return 1;
        else return 0;
    }

    function erc721StakeMiningV1() external pure returns (bool) {
        return true;
    }

    function _stake(address from, uint256 tokenId) internal {
        uint256 miners = dispatchableMiners(tokenId);
        _stakedTokensOf[from].add(tokenId);
        _stakers.set(tokenId, from);
        _dispatchMiners(from, miners);
    }
}