// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@artman325/community/contracts/interfaces/ICommunity.sol";
import "@artman325/releasemanager/contracts/CostManagerHelper.sol";
import "@artman325/releasemanager/contracts/interfaces/IReleaseManager.sol";
import "./interfaces/IVotingContract.sol";

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
contract VotingContract is OwnableUpgradeable, ReentrancyGuardUpgradeable, IVotingContract, CostManagerHelper {
    using AddressUpgradeable for address;

    address internal _releaseManager;
    uint256 constant public N = 1e6;

    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_SET_WEIGHT = 0x1;
    uint8 internal constant OPERATION_VOTE = 0x2;

    address[] voters;
    Vote voteData;

    mapping(address => Voter) votersMap;
    mapping(uint8 => uint256) rolesWeight;
    mapping(address => uint256) lastEligibleBlock;

    //event PollStarted();
    event PollEmit(address voter, string methodName, VoterData[] data, uint256 weight);
    //event PollEnded();
    
    error VotingIsOutsideOfPeriod(uint256 startBlock, uint256 endBlock);
    error AlreadyVoted(address sender);
    error NotEligibleYet(address sender);
    error VotingIsOutsideWindow(address sender, uint256 voteWindowBlocks);
    error OutsideVotestantList(address sender);
    error ShouldBeRegisteredInReleaseManager(address contractAddress, address releaseManager);

    modifier canVote() {
        if ((voteData.startBlock <= block.number) && (voteData.endBlock >= block.number)) {
            // can vote
        } else {
            revert VotingIsOutsideOfPeriod(voteData.startBlock, voteData.endBlock);
        }
        _;
    }
    
    modifier hasVoted() {
        if (votersMap[msg.sender].alreadyVoted) {
            revert AlreadyVoted(msg.sender);
        }
        _;
    }

    modifier eligible(uint256 blockNumber) {
        if (wasEligible(msg.sender, blockNumber) == false) {
            revert NotEligibleYet(msg.sender);
        }
        
        if ((block.number - blockNumber) > voteData.voteWindowBlocks) {
            revert VotingIsOutsideWindow(msg.sender, voteData.voteWindowBlocks);
        }

        _;
    }
    
    modifier isVoters() {
        bool s = false;
        address[] memory addrs = new address[](1);
        addrs[0] = msg.sender;
        uint8[][] memory roles = ICommunity(voteData.communityAddress).getRoles(addrs);
        for (uint256 i=0; i< roles[0].length; i++) {
            for (uint256 j=0; j< voteData.communitySettings.length; j++) {
                if (voteData.communitySettings[j].communityRole == roles[0][i]) {
                    s = true;
                    break;
                }
            }
            if (s==true)  {
                break;
            }
        }
        if (s == false) {revert OutsideVotestantList(msg.sender); } 

        _;
    }
    
    /**
     * @param initSettings tuple of (voteTitle,blockNumberStart,blockNumberEnd,voteWindowBlocks). where
     *  voteTitle vote title
     *  blockNumberStart vote will start from `blockNumberStart`
     *  blockNumberEnd vote will end at `blockNumberEnd`
     *  voteWindowBlocks period in blocks then we check eligible
     * @param contractAddress contract's address which will call after user vote
     * @param communityAddress address community
     * @param communitySettings tuples of (communityRole,communityFraction,communityMinimum). where
     *  communityRole community role which allowance to vote
     *  communityFraction fraction mul by 1e6. setup if minimum/memberCount too low
     *  communityMinimum community minimum
     * @param releaseManager releaseManager's address
     * @param costManager costManager's address
     * @param producedBy address who produced(msg.sender here will be a factory address)
     */
    function init(
        InitSettings memory initSettings,
        address contractAddress,
        address communityAddress,
        CommunitySettings[] memory communitySettings,
        address releaseManager,
        address costManager,
        address producedBy
        
    ) 
        external 
        initializer
    {    
        _releaseManager = releaseManager;
        __CostManagerHelper_init(msg.sender);
        _setCostManager(costManager);

        __Ownable_init();
        __ReentrancyGuard_init();


        bool verify = IReleaseManager(_releaseManager).checkInstance(contractAddress);
        if (verify == false) {
            revert ShouldBeRegisteredInReleaseManager(contractAddress, _releaseManager);
        }
        
        voteData.voteTitle = initSettings.voteTitle;
        voteData.startBlock = initSettings.blockNumberStart;
        voteData.endBlock = initSettings.blockNumberEnd;
        voteData.voteWindowBlocks = initSettings.voteWindowBlocks;
        
        voteData.contractAddress = contractAddress;
        voteData.communityAddress = communityAddress;
        
        // --------
        // voteData.communitySettings = communitySettings;
        // UnimplementedFeatureError: Copying of type struct VotingContract.CommunitySettings memory[] from memory to storage not yet supported.
        // -------- so do it in cycle below by pushing every tuple

        for (uint256 i=0; i< communitySettings.length; i++) {
            voteData.communityRolesWeight[communitySettings[i].communityRole] = 1; // default weight
            voteData.communitySettings.push(communitySettings[i]);
        }
        
        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(producedBy)),
            0
        );
    }
    
    /**
     * setup weight for role which is
     */
    function setWeight(
        uint8 role, 
        uint256 weight
    ) 
        public 
        onlyOwner 
    {
        // TODO 0: should we recalculate weight for vote ?
        rolesWeight[role] = weight;

        _accountForOperation(
            OPERATION_SET_WEIGHT << OPERATION_SHIFT_BITS,
            uint256(role),
            weight
        );
        
    }
   
   /**
    * check user eligible
    */
   function wasEligible(
        address /*addr*/,
        uint256 blockNumber // user is eligle to vote from  blockNumber
    )
        public 
        view
        returns(bool)
    {
        bool was = false;
        //uint256 blocksLength;
        
        uint256 memberCount;
        
        if ((block.number - blockNumber)>256) {
            // hash of the given block - only works for 256 most recent blocks excluding current
            // see https://solidity.readthedocs.io/en/v0.4.18/units-and-global-variables.html
        
        } else {
            uint256 m;
            uint256 number  = getNumber(blockNumber, 1000000);
            for (uint256 i=0; i<voteData.communitySettings.length; i++) {
                
                memberCount = ICommunity(voteData.communityAddress).addressesCount(voteData.communitySettings[i].communityRole);
                m = (voteData.communitySettings[i].communityMinimum) * (N) / (memberCount);
            
                if (m < voteData.communitySettings[i].communityFraction) {
                    m = voteData.communitySettings[i].communityFraction;
                }
    
            
                if (number < m) {
                    was = true;
                }
            
                if (was == true) {
                    break;
                }
            }
        
        }
        return was;
    }

    /**
     * vote method
     */
    function vote(
        uint256 blockNumber,
        string memory methodName,
        VoterData[] memory voterData
    )
        public 
        hasVoted()
        isVoters()
        canVote()
        eligible(blockNumber)
        nonReentrant()
    {
        
        votersMap[msg.sender].contractAddress = voteData.contractAddress;
        votersMap[msg.sender].contractMethodName = methodName;
        votersMap[msg.sender].alreadyVoted = true;
        for (uint256 i=0; i<voterData.length; i++) {
            votersMap[msg.sender].voterData.push(VoterData(voterData[i].name,voterData[i].value));
        }
        
        voters.push(msg.sender);
        
        uint256 weight = getWeight(msg.sender);
      
        //"vote((string,uint256)[],uint256)":
        (bool success,) = voteData.contractAddress.call(
            abi.encodeWithSelector(
                bytes4(keccak256(abi.encodePacked(methodName,"((string,uint256)[],uint256)"))),
                //voterDataToSend, 
                voterData, 
                weight
            )
        );
        // todo 0:  require(success) ??
        
        _accountForOperation(
            OPERATION_VOTE << OPERATION_SHIFT_BITS,
            uint256(uint160(msg.sender)),
            blockNumber
        );

        emit PollEmit(msg.sender, methodName, voterData,  weight);
    }
    
    /**
     * get votestant votestant
     * @param addr votestant's address
     * @return Votestant tuple
     */
    function getVoterInfo(address addr) public view returns(Voter memory) {
        return votersMap[addr];
    }
    
    /**
     * return all votestant's addresses
     */
    function getVoters() public view returns(address[] memory) {
        return voters;
    }
    
    /**
     * findout max weight for sender role
     * @param addr sender's address
     * @return weight max weight from all allowed roles
     */
    function getWeight(address addr) internal view returns(uint256 weight) {
        weight = 1; // default minimum weight
        uint256 iWeight = weight;

        address[] memory addrs = new address[](1);
        addrs[0] = addr;
        uint8[][] memory roles = ICommunity(voteData.communityAddress).getRoles(addrs);
        for (uint256 i = 0; i < roles[0].length; i++) {
            for (uint256 j = 0; j < voteData.communitySettings.length; j++) {
                if (voteData.communitySettings[j].communityRole == roles[0][i]) {
                    iWeight = rolesWeight[roles[0][i]];
                    if (weight < iWeight) {
                        weight = iWeight;
                    }
                }
            }
        }
    }
    
    function getNumber(uint256 blockNumber, uint256 max) internal view returns(uint256 number) {
        bytes32 blockHash = blockhash(blockNumber);
        number = (uint256(keccak256(abi.encodePacked(blockHash, msg.sender))) % max);
    }
    
    
}