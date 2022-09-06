// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./DataTypes.sol";

interface IKyoko {
    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    event SetPause(bool pause);

    event UpdateWhiteList(address indexed _address, bool _active);

    event SetFee(uint256 _fee);

    event Deposit(
        uint256 indexed _depositId,
        uint256 indexed _nftId,
        address indexed _nftAdr
    );

    event Modify(uint256 indexed _depositId, address _holder);

    event AddOffer(
        uint256 indexed _depositId,
        address indexed _lender,
        uint256 indexed _offerId
    );

    event CancelOffer(
        uint256 indexed _depositId,
        uint256 indexed _offerId,
        address indexed user
    );

    event AcceptOffer(address indexed offerUser, address indexed nftUser,uint256 indexed _depositId, uint256 _offerId);

    event Borrow(uint256 indexed _depositId);

    event Lend(address indexed lender, address indexed nftUser, uint256 indexed _depositId, uint256 _lTokenId);

    event Repay(uint256 indexed _depositId, uint256 _amount);

    event ClaimCollateral(uint256 indexed _depositId);

    event ClaimERC20(uint256 indexed _depositId);

    event ExecuteEmergency(uint256 indexed _depositId);

    event Liquidate(uint256 indexed _depositId);
}