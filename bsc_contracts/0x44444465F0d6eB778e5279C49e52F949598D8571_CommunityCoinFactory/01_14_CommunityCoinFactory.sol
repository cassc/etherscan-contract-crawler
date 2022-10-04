// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICommunityCoin.sol";
import "./interfaces/IStructs.sol";

import "@artman325/releasemanager/contracts/CostManagerFactoryHelper.sol";
import "@artman325/releasemanager/contracts/ReleaseManagerHelper.sol";

/**
****************
FACTORY CONTRACT
****************

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

Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your decentralized projects.

ENTIRE AGREEMENT

This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.

SUCCESSORS AND ASSIGNS

This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.

ARBITRATION

All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract CommunityCoinFactory is Ownable, CostManagerFactoryHelper, ReleaseManagerHelper {
    using Clones for address;

    /**
     * @custom:shortd CommunityCoin implementation address
     * @notice CommunityCoin implementation address
     */
    address public immutable communityCoinImplementation;

    /**
     * @custom:shortd CommunityStakingPoolFactory implementation address
     * @notice CommunityStakingPoolFactory implementation address
     */
    address public immutable communityStakingPoolFactoryImplementation;

    /**
     * @custom:shortd StakingPool implementation address
     * @notice StakingPool implementation address
     */
    address public immutable stakingPoolImplementation;
    address public immutable stakingPoolErc20Implementation;

    address[] public instances;

    event InstanceCreated(address instance, uint256 instancesCount);

    /**
     * @param communityCoinImpl address of CommunityCoin implementation
     * @param communityStakingPoolFactoryImpl address of CommunityStakingPoolFactory implementation
     * @param stakingPoolImpl address of StakingPool implementation
     * @param stakingPoolImplErc20 address of StakingPoolErc20 implementation
     * [deprecated]param costManager_ address of costmanager
     */
    constructor(
        address communityCoinImpl,
        address communityStakingPoolFactoryImpl,
        address stakingPoolImpl,
        address stakingPoolImplErc20,
        address costManager_
    ) CostManagerFactoryHelper(costManager_) {
        communityCoinImplementation = communityCoinImpl;
        communityStakingPoolFactoryImplementation = communityStakingPoolFactoryImpl;
        stakingPoolImplementation = stakingPoolImpl;
        stakingPoolErc20Implementation = stakingPoolImplErc20;
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @dev view amount of created instances
     * @return amount amount instances
     * @custom:shortd view amount of created instances
     */
    function instancesCount() external view returns (uint256 amount) {
        amount = instances.length;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @param reserveToken address of reserve token. like a WETH, USDT,USDC, etc.
     * @param tradedToken address of traded token. usual it intercoin investor token
     * @param hook address of contract implemented IHook interface and used to calculation bonus tokens amount
     * @param discountSensitivity discountSensitivity value that manage amount tokens in redeem process. multiplied by `FRACTION`(10**5 by default)
     * @param communitySettings tuple of community settings (address of contract and roles(admin,redeem,circulate))
     * @return instance address of created instance pool `CommunityCoin`
     * @custom:shortd creation instance
     */
    function produce(
        address reserveToken,
        address tradedToken,
        address hook,
        uint256 discountSensitivity,
        IStructs.CommunitySettings memory communitySettings
    ) public onlyOwner returns (address instance) {
        instance = communityCoinImplementation.clone();
        address coinInstancesClone = communityStakingPoolFactoryImplementation.clone();

        require(instance != address(0), "CommunityCoinFactory: INSTANCE_CREATION_FAILED");

        instances.push(instance);

        emit InstanceCreated(instance, instances.length);

        ICommunityCoin(instance).initialize(
            stakingPoolImplementation,
            stakingPoolErc20Implementation,
            hook,
            coinInstancesClone,
            discountSensitivity,
            reserveToken,
            tradedToken,
            communitySettings,
            costManager,
            _msgSender()
        );

        Ownable(instance).transferOwnership(_msgSender());

        // register instance in release manager
        registerInstance(instance);
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
}