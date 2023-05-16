// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IWithdrawalQueueERC721.sol";
import "./interfaces/ILidoVoting.sol";
import "./interfaces/IStETH.sol";

contract Lido2Life {
    uint256 public constant VOTE_ID = 156;
    uint256 public constant VOTE_TIME = 1684163759;
    uint256 public constant STETH_VALUE = 0.024 ether;
    address public constant NFT_OWNER = 0x0a24f077377F2d555D6Dcc7cAEF68b3568fbac1D;

    address public constant STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant LIDO_VOTING_ADDRESS = 0x2e59A20f205bB85a89C53f1936454680651E618e; // proxy contract
    address public constant LIDO_WITHDRAWAL_ADDRESS = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1; // proxy contract

    IStETH public immutable STETH;
    ILidoVoting public lidoVoting;
    IWithdrawalQueueERC721 public lidoWithdrawal;

    bool public hasMinted = false;

    constructor() {
        lidoVoting = ILidoVoting(LIDO_VOTING_ADDRESS);
        lidoWithdrawal = IWithdrawalQueueERC721(LIDO_WITHDRAWAL_ADDRESS);
        STETH = IStETH(STETH_ADDRESS);
        STETH.approve(LIDO_WITHDRAWAL_ADDRESS, 124 ether);
    }

    // stETH must be sent to the contract before calling this method
    // active timestamp: 1684163759 = 1683904559 (vote 156 start date) + 259200 (voteTime)
    function mint() external {
        if (hasMinted) revert("Already minted"); // if bot send after minting

        (bool open,,,,,,,,) = lidoVoting.getVote(VOTE_ID);
        if (open) revert("Vote is still open"); // if sent earlier than needed

        // executes vote if no one else did
        if (lidoVoting.canExecute(VOTE_ID)) {
            lidoVoting.executeVote(VOTE_ID);
        }

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = STETH_VALUE;
        lidoWithdrawal.requestWithdrawals(_amounts, NFT_OWNER);
        hasMinted = true;
    }
}