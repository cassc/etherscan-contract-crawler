// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

import { IStaking } from "./IStaking.sol";

/**************************************

    Staking interface

 **************************************/

abstract contract ITholosStaking is IStaking {

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /**************************************

        Unstake request struct

        ------------------------------

        @param amount number of tokens which is desired to be unstaked
        @param deadline deadline before which request can't be executed

     **************************************/

    struct UnstakeRequest {
        uint64 deadline;
        uint96 amount;
    }

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    // errors
    error InvalidDeposit();
    error NotEnoughAllowance(address sender, uint96 amount);
    error NotEnoughNFTAllowance(address sender);
    error InvalidWithdrawal(); // 0xc945242d
    error BalanceSmallerThanAmount(address sender, uint96 balance, uint96 amount); // 0xaa991ed1
    error MissingNFT(address sender, uint256 tokenId); // 0x1f8cc0fb
    error TooManyUnstakeRequested(address sender);
    error NothingToUnstake();

    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    // events
    event TholPerNftUpdated(uint96 value);
    event MaxRewardForNftsUpdated(uint96 value);
    event UnstakeClaimed(address indexed sender, uint96 totalAmount);

    // -----------------------------------------------------------------------
    //                              External
    // -----------------------------------------------------------------------

    /**************************************

        Set $THOL per NFT

    **************************************/

    function setTholPerNft(uint96 _tholPerNft) external virtual;

    /**************************************

        Set max reward cap for NFT

    **************************************/

    function setMaxNftRewardCap(uint96 _value) external virtual;

}