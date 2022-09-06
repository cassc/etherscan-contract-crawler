// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './PropyAuctionV2.sol';


contract PropyAuctionV2ERC20 is PropyAuctionV2 {
    using SafeERC20 for IERC20;

    IERC20 public immutable biddingToken;

    constructor(
        address _owner,
        address _configurator,
        address _finalizer,
        IWhitelist _whitelist,
        IERC20 _biddingToken
    ) PropyAuctionV2 (_owner, _configurator, _finalizer, _whitelist) {
        biddingToken = _biddingToken;
    }

    function bid(IERC721, uint, uint32) external payable override {
        revert('Auction: Native currency is not allowed');
    }

    function bidToken(IERC721 _nft, uint _nftId, uint32 _start, uint _amount) external {
        biddingToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _bid(_nft, _nftId, _start, _amount);
    }

    function recoverTokens(IERC20 _token, address _destination, uint _amount) public override {
        require(_token != biddingToken || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Auction: Could not recover bidding token');
        super.recoverTokens(_token, _destination, _amount);
    }

    function _pay(address _to, uint _amount) internal override {
        biddingToken.safeTransfer(_to, _amount);
    }
}