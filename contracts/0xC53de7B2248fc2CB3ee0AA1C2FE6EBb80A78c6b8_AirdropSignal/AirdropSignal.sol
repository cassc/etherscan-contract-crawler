/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/*
-----------------------------------------------
 __   __   __         ___ ___         __   __  
|__) |__) /  \  |\/| |__   |  |__| | /  \ /__` 
|    |  \ \__/  |  | |___  |  |  | | \__/ .__/ 
                                               
-----------------------------------------------
* AirdropSignal.sol
*/

/**
 * README Documentation
 * This Contract is to signal which chain users would like to receive their airdrop.
 * The airdrop itself will be calculated off-chain and deployed separately.
 * To receive the airdrop users **MUST** be on the snapshot **AND** call claimOn from their address.
 * ***No on can claim your airdrop address for you.***

 * To receive the referral bonus, a user must:
 *   1. Set a referralENS. It can be any valid ENS!
 *   2. The owner of the ENS must also set their preferred chain from the address that owns the ENS.
 *
 * Note: Both addresses must set their preferred chain for either to receive their bonus.
 *
 * Although the function is open for any address to call claimON, we will verify they are in the snapshot off-chain
 * and resolve the ENS owner's address before launch. We will deploy the airdrop separately.
 * 
 */

contract AirdropSignal {
    enum PreferredChain {
        None,
        Arbitrum,
        Optimism
    }

    struct Claimr {
        PreferredChain chain;
        string referralENS; //Any valid ENS
    }

    mapping(address => Claimr) public claimrs;

    event ClaimSet(address user, PreferredChain chain, string referralENS);

    /*
     *  Signal where you'd like to receive your airdrop.
     *   - PreferredChain = Arbitrum or Optimism
     *   - referralENS = The ENS you want to refer. It can be any valid ENS!
     *
     * Setting a referral ENS is optional to recieving your aidrop.
     */
    function claimOn(PreferredChain chain, string memory friendENS) external {
        claimrs[msg.sender].chain = chain;
        claimrs[msg.sender].referralENS = friendENS;

        emit ClaimSet(msg.sender, chain, friendENS);
    }

    /*
     * Set your preferred chain. You can call this again if you change your mind before launch.
     */
    function setChain(PreferredChain chain) external returns (bool success) {
        claimrs[msg.sender].chain = chain;

        emit ClaimSet(msg.sender, claimrs[msg.sender].chain, claimrs[msg.sender].referralENS);

        return true;
    }

    /*
     * Set a referralENS. Remember, they **MUST** also submit a claim from the address that owns that ENS.
     * We will resolve the ENS off chain before launch.
     */
    function setReferralENS(string memory friendENS) external returns (bool success) {
        claimrs[msg.sender].referralENS = friendENS;

        emit ClaimSet(msg.sender, claimrs[msg.sender].chain, claimrs[msg.sender].referralENS);

        return true;
    }
}

/* MIT License
 * ===========
 *
 * Copyright (c) 2023 Promethios
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */