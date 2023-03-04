// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IEscrowContract.sol";
import "@artman325/releasemanager/contracts/CostManagerHelper.sol";

/**
*****************
TEMPLATE CONTRACT
*****************

Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.

To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.

Copyright (c) Intercoin Inc. All rights reserved.

ALLOWED USAGE.

Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.

Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:

DISCLAIMERS AND DISCLOSURES.

Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.

Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.

Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.

INDEMNIFICATION.

Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.

NO WARRANTY.

THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 

LIMITATION OF LIABILITY. 

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.

TRADEMARKS.

This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.

LINK REQUIREMENTS.

Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:

"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."

STAKING OR SPENDING REQUIREMENTS.

In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.

CUSTOM ARRANGEMENTS.

Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.

ENTIRE AGREEMENT

This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.

SUCCESSORS AND ASSIGNS

This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.

ARBITRATION

All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract EscrowContract is Initializable, /*OwnableUpgradeable,*/ ReentrancyGuardUpgradeable, IEscrowContract, CostManagerHelper {
    
    using AddressUpgradeable for address;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    struct EscrowBox {
        Participant[] participants;
        mapping(address => uint256) participantsIndex;
        Recipient[] recipients;
        mapping(address => uint256) recipientsIndex;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 duration;
        uint256 quorumCount;
        EnumerableMapUpgradeable.UintToAddressMap swapFrom;
        EnumerableMapUpgradeable.UintToAddressMap swapTo;
        bool swapBackAfterEscrow;
        bool lock;
        bool exists;
    }
    struct Participant {
        address addr;
        address token;
        uint256 min;
        uint256 balance;
        uint256 unlockedBalance;
        uint256 recipientCount;
        bool exists;
    }
    struct Recipient {
        address addr;
        //mapping(address => uint256) fundsAvailable; // token => Amount
        // moved to recipientsFundsAvailable
        
        bool exists;
    }
    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_DEPOSIT = 0x1;
    uint8 internal constant OPERATION_UNLOCK = 0x2;
    uint8 internal constant OPERATION_UNLOCKALL = 0x3;
    uint8 internal constant OPERATION_WITHDRAW = 0x4;

    // if one box
    //  recipientsIndex->address(token) => amount
    mapping(uint256 => mapping(address => uint256)) recipientsFundsAvailable;
   
    EscrowBox internal escrowBox;
    
    event EscrowCreated(address indexed addr);
    event EscrowStarted(address indexed participant);
    event EscrowLocked();
    //event EscrowEnded();
    
    /**
     * Started Escrow mechanism
     * 
     * @param participants array of participants (one of complex arrays participants/tokens/minimums)
     * @param tokens array of tokens (one of complex arrays participants/tokens/minimums)
     * @param minimums array of minimums (one of complex arrays participants/tokens/minimums)
     * @param duration duration of escrow in seconds. will start since locked up to expire
     * @param quorumCount count of participants (which deposit own minimum). After last will initiate locked up
     * @param swapFrom array of participants which resources swap from
     * @param swapTo array of participants which resources swap to
     * @param swapBackAfterEscrow if true, then: if withdraw is called after lock expired, and boxes still contain something, then SWAP BACK (swapTo->swapFrom) left resources
     * @param costManager costManager address
     * @param producedBy producedBy address
     */
    function init(
        address[] memory participants,
        address[] memory tokens,
        uint256[] memory minimums,
        uint256 duration,
        uint256 quorumCount,
        address[] memory swapFrom,
        address[] memory swapTo,
        bool swapBackAfterEscrow,
        address costManager,
        address producedBy
    ) 
        public 
        override
        initializer 
    {
        __CostManagerHelper_init(msg.sender);
        _setCostManager(costManager);
        //__Ownable_init();
        __ReentrancyGuard_init();
        
        emit EscrowCreated(msg.sender);
        
        require(participants.length > 0, "Participants list can not be empty");
        require(tokens.length > 0, "Tokens list can not be empty");
        require(minimums.length > 0, "Minimums list can not be empty");
        require(swapFrom.length > 0, "SwapFrom list can not be empty");
        require(swapTo.length > 0, "SwapTo list can not be empty");
        require((participants.length) >= quorumCount, "Wrong quorumCount");
        
        require((participants.length == tokens.length && tokens.length == minimums.length), "Parameters participants/tokens/minimums must be the same length");
        require((swapFrom.length == swapTo.length), "Parameters swapFrom/swapTo must be the same length");
        
        
        escrowBox.timeStart = 0;
        escrowBox.timeEnd = 0;
        escrowBox.duration = duration;
        escrowBox.swapBackAfterEscrow = swapBackAfterEscrow;
        escrowBox.lock = false;
        escrowBox.exists = true;

        escrowBox.quorumCount = (quorumCount == 0) ? participants.length : quorumCount;    
        
        for (uint256 i = 0; i < participants.length; i++) {
            escrowBox.participantsIndex[participants[i]] = i;
            
            escrowBox.participants.push(Participant({
                addr: participants[i],
                token: tokens[i],
                min:  minimums[i],
                balance: 0,
                unlockedBalance: 0,
                recipientCount: 0,
                exists: true
            }));
            
            //event
            emit EscrowStarted(participants[i]);
        }

        uint256 indexP;
        uint256 indexRtmpI;
        uint256 indexR = 0;
        
        
        escrowBox.recipients.push(Recipient({
            addr: address(swapTo[0]), 
            exists: true
        }));
        
        escrowBox.recipientsIndex[swapTo[0]] = indexR;
        indexR++;
        
        for (uint256 i = 0; i < swapFrom.length; i++) {

            indexP = escrowBox.participantsIndex[swapFrom[i]];

            escrowBox.participants[indexP].recipientCount++;
            

            // swapTo section
            indexRtmpI = escrowBox.recipientsIndex[swapTo[i]];
            
            if ((escrowBox.recipients[indexRtmpI].exists == true) && (escrowBox.recipients[indexRtmpI].addr == swapTo[i])) {
                // 
            } else {
                escrowBox.recipientsIndex[swapTo[i]] = indexR;
                escrowBox.recipients.push(Recipient({addr: address(swapTo[i]), exists: true}));
                
                indexR++;
            }
        }

        for (uint256 i = 0; i < swapFrom.length; i++) {
            require(!swapFrom[i].isContract(), "address in `swapFrom` can not be a contract");
            require(!swapTo[i].isContract(), "address in `swapTo` can not be a contract");
            escrowBox.swapFrom.set(i, swapFrom[i]);
            escrowBox.swapTo.set(i, swapTo[i]);
        }
        
        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(producedBy)),
            0
        );
    }
    
    /**
     * @dev Deposit token via approve the tokens on the exchange
     * @param token token's address 
     */
    function deposit(address token) public nonReentrant()  {
        require(escrowBox.exists == true, "Such Escrow does not exists");
        require(escrowBox.lock == false, "Such Escrow have already locked up");
        
        // index can be zero for non-exists participants. we will check attr exists in struct
        uint256 index = escrowBox.participantsIndex[msg.sender]; 
        require(
            escrowBox.participants[index].exists == true && escrowBox.participants[index].addr == msg.sender, 
            "Such participant does not exists in this escrow"
        );
        
        require(escrowBox.participants[index].token == token, "Such token does not exists for this participant ");
        
        
        uint256 _allowedAmount = IERC20Upgradeable(token).allowance(msg.sender, address(this));
        require((_allowedAmount > 0), "Amount exceeds allowed balance");
        // try to get
        bool success = IERC20Upgradeable(token).transferFrom(msg.sender, address(this), _allowedAmount);
        require(success == true, "Transfer tokens were failed"); 
        
        escrowBox.participants[index].balance += _allowedAmount;
        
        if (escrowBox.participants[index].min <= escrowBox.participants[index].balance) {
            tryToLockEscrow();
        }
        
        _accountForOperation(
            OPERATION_DEPOSIT << OPERATION_SHIFT_BITS,
            uint256(uint160(token)),
            uint256(uint160(msg.sender))
        );
    }
    
    /**
     * Method unlocked tokens (deposited before) for recipients
     * 
     * @param recipient token's address 
     * @param token token's address 
     * @param amount token's amount
     */
    function unlock(address recipient, address token, uint256 amount) public {
        require(escrowBox.exists == true, "Such Escrow does not exists");
        require(escrowBox.lock == true, "Such Escrow have not locked yet");
        // check exists sender in swap from
        // check exists recipient in swap to
        // also itis checked recipient as available 
        bool pairExists = false;
        for (uint256 i = 0; i < escrowBox.swapFrom.length(); i++) {
            if (
                escrowBox.swapFrom.get(i) == msg.sender &&
                escrowBox.swapTo.get(i) == recipient
            )  {
                pairExists = true;
            }
        }
        require(pairExists == true, "Such participant is not exists via recipient");
        
        // check sender exist
        uint256 indexP = escrowBox.participantsIndex[msg.sender]; 
        require(
            escrowBox.participants[indexP].exists == true && escrowBox.participants[indexP].addr == msg.sender, 
            "Such participant does not exists in this escrow"
        );
        
        
        uint256 indexR = escrowBox.recipientsIndex[recipient]; 
        
        // check correct token in sender
        require(escrowBox.participants[indexP].token == token, "Such token does not exists for this participant");
        
        // check Available amount tokens at sender (and unlockedBalance not more than available)
        require(
            escrowBox.participants[indexP].balance - escrowBox.participants[indexP].unlockedBalance >= amount, 
            "Amount exceeds balance available to unlock"
        );
        
        // write additional unlockedBalance at sender
        escrowBox.participants[indexP].unlockedBalance += amount;
        
        // write fundsAvailable at recipient
        //escrowBox.recipients[indexR].fundsAvailable[token] = (escrowBox.recipients[indexR].fundsAvailable[token]).add(amount);
        recipientsFundsAvailable[indexR][token] += amount;
        
        _accountForOperation(
            OPERATION_UNLOCK << OPERATION_SHIFT_BITS,
            uint256(uint160(msg.sender)),
            uint256(uint160(token))
        );
    }
    
    /**
     * Unlock all available tokens (deposited before) equally for recipents at `swap` pairs
     */
    function unlockAll() public {
        require(escrowBox.exists == true, "Such Escrow does not exists");
        require(escrowBox.lock == true, "Such Escrow have not locked yet");
        
        // check participant exist
        uint256 indexP = escrowBox.participantsIndex[msg.sender]; 
        require(
            escrowBox.participants[indexP].exists == true && escrowBox.participants[indexP].addr == msg.sender, 
            "Such participant does not exists in this escrow"
        );
        
        address recipient;
        address token;
        uint256 recipientCount = 0;
        uint256 amountLeft = 0;
        uint256 indexR;
        for (uint256 i = 0; i < escrowBox.swapFrom.length(); i++) {
            if (escrowBox.swapFrom.get(i) == msg.sender)  {
                if (recipientCount == 0) {
                    recipientCount = escrowBox.participants[indexP].recipientCount;
                }
                indexR = escrowBox.recipientsIndex[escrowBox.swapTo.get(i)]; 
                
                amountLeft = escrowBox.participants[indexP].balance - escrowBox.participants[indexP].unlockedBalance;
                
                recipient = escrowBox.swapTo.get(i);
                token = escrowBox.participants[indexP].token;
                
                escrowBox.participants[indexP].unlockedBalance += amountLeft/recipientCount;
                
                //escrowBox.recipients[indexR].fundsAvailable[token] = (escrowBox.recipients[indexR].fundsAvailable[token]).add(amountLeft.div(recipientCount));
                recipientsFundsAvailable[indexR][token] += amountLeft/recipientCount;
                
                recipientCount--;
                
            }
        }

        _accountForOperation(
            OPERATION_UNLOCKALL << OPERATION_SHIFT_BITS,
            uint256(uint160(msg.sender)),
            0
        );
    }
    
    /**
     * withdraw all tokens deposited and unlocked from other participants
     */
    function withdraw() public nonReentrant() {
        require(escrowBox.exists == true, "Such Escrow does not exists");
        
        // before locked up
        //// got own
        // in locked period
        //// got unlocked by other participants
        // after locked up expired
        //// got own left  
        uint256 amount;
        address token;
        uint256 indexP;
        uint256 indexR;
        bool success;
        if (escrowBox.lock == false) {
            indexP = escrowBox.participantsIndex[msg.sender]; 
            
            require(
                escrowBox.participants[indexP].exists == true && escrowBox.participants[indexP].addr == msg.sender, 
                "Such participant does not exists in this escrow"
            );
            amount = escrowBox.participants[indexP].balance;
            token = escrowBox.participants[indexP].token;
            escrowBox.participants[indexP].balance = 0;
            
            success = IERC20Upgradeable(token).transfer(msg.sender, amount);
            require(success == true, "Transfer tokens were failed");
    
    
        } else if (escrowBox.lock == true) {
            
            indexR = escrowBox.recipientsIndex[msg.sender];
            
            for (uint256 i = 0; i < escrowBox.swapTo.length(); i++) {
                if (escrowBox.swapTo.get(i) == msg.sender)  {
                    indexP = escrowBox.participantsIndex[escrowBox.swapFrom.get(i)];
                    token = escrowBox.participants[indexP].token;
                    //amount = escrowBox.recipients[indexR].fundsAvailable[token];
                    amount = recipientsFundsAvailable[indexR][token];
                    if (amount > 0) {
                        //escrowBox.recipients[indexR].fundsAvailable[token] = 0;
                        recipientsFundsAvailable[indexR][token] = 0;
                        
                        success = IERC20Upgradeable(token).transfer(msg.sender, amount);
                        require(success == true, "Transfer tokens were failed");
                    }
                }
            }
            
            
            // also if escrow expired sender can gow own funds 
            if (
                //escrowBox.lock == true && 
                escrowBox.swapBackAfterEscrow == true &&
                escrowBox.timeEnd <= block.timestamp
            ) {
                
                indexP = escrowBox.participantsIndex[msg.sender]; 
                
                require(
                    escrowBox.participants[indexP].exists == true && escrowBox.participants[indexP].addr == msg.sender, 
                    "Such participant does not exists in this escrow"
                );
                
                amount = escrowBox.participants[indexP].balance - escrowBox.participants[indexP].unlockedBalance;
                token = escrowBox.participants[indexP].token;
                escrowBox.participants[indexP].balance = 0;
                
                success = IERC20Upgradeable(token).transfer(msg.sender, amount);
                require(success == true, "Transfer tokens were failed");
                
            }
        }
    
        _accountForOperation(
            OPERATION_WITHDRAW << OPERATION_SHIFT_BITS,
            uint256(uint160(msg.sender)),
            0
        );
    }
    
    /**
     * triggered after each deposit if amoint more than minimum. if true, Escrow will be lock
     * 
     */
    function tryToLockEscrow() internal {
        require(escrowBox.lock == false, "Such Escrow have already locked up");
        uint256 quorum = 0;
        for (uint256 i = 0; i < escrowBox.participants.length; i++) {
            if (escrowBox.participants[i].min <= escrowBox.participants[i].balance) {
                quorum++;
            }
        }
        
        if (quorum >= escrowBox.quorumCount) {
            escrowBox.lock = true;
            escrowBox.timeStart = block.timestamp;
            escrowBox.timeEnd = block.timestamp + escrowBox.duration;
            emit EscrowLocked();
        }
    }
  
    
}