// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@artman325/community/contracts/interfaces/ICommunity.sol";
import "@artman325/releasemanager/contracts/CostManagerHelper.sol";
import "./interfaces/IControlContract.sol";
import "./lib/StringUtils.sol";
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
contract ControlContract is ERC721HolderUpgradeable, IERC777RecipientUpgradeable, IERC777SenderUpgradeable, IERC1155ReceiverUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IControlContract, CostManagerHelper {
    
    using AddressUpgradeable for address;
    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    using StringUtils for *;
    
    uint256 internal constant fractionDiv = 1e10;
    uint256 internal constant groupTimeoutActivity = 2_592_000; // 30 days

    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_INVOKE = 0x1;
    uint8 internal constant OPERATION_ENDORSE = 0x2;
    uint8 internal constant OPERATION_EXECUTE = 0x3;
    uint8 internal constant OPERATION_ADD_METHOD = 0x4;

    uint16 minimumDelay;

    address communityAddress;
    uint256 internal currentGroupIndex;
    uint256 private maxGroupIndex;
    uint256 private lastRoleIndex;
    
    mapping(uint256 => uint256) roleIDs;
    mapping(bytes32 => Method) methods;
    mapping(uint256 => Group) internal groups;
    
    error RoleDoesNotExist(uint8 roleID);
    error MethodAlreadyRegistered(string method, uint256 minimum, uint256 fraction);
    error UnknownInvokeId(uint256 invokeID);
    error UnknownMethod(address contractAddress, string method);
    error MissingInvokeRole(address sender);
    error MissingEndorseRole(address sender);
    error AlreadyEndorsed(address sender);
    error AlreadyExecuted(uint256 invokeID);
    error NotYetApproved(uint256 invokeID);
    error MinimumDelayMustElapse(uint256 invokeID);
    error EmptyCommunityAddress();
    error NoGroups();
    error RoleExistsOrInvokeEqualEndorse();
    error SenderIsNotInCurrentOwnerGroup(address sender, uint256 currentGroupIndex);

    //----------------------------------------------------
    // modifiers section 
    //----------------------------------------------------
    modifier canInvoke(
        address contractAddress, 
        string memory method, 
        address sender
    ) 
    {
        bool s = false;
        bytes32 k = keccak256(abi.encodePacked(contractAddress,method));
        address[] memory addrs = new address[](1);
        addrs[0] = sender;
        uint8[][] memory roles = ICommunity(communityAddress).getRoles(addrs);
        for (uint256 i = 0; i < roles[0].length; i++) {
            if (methods[k].invokeRolesAllowed.contains(roleIDs[roles[0][i]])) {
                s = true;
            }
        }
        if (s == false) {
            revert MissingInvokeRole(sender);
        }
        _;
    }
    
    //----------------------------------------------------
    // events section 
    //----------------------------------------------------
    event OperationInvoked(uint256 indexed invokeID, uint40 invokeIDWei,  address contractAddress, string method, string params);
    event OperationEndorsed(uint256 indexed invokeID, uint40 invokeIDWei);
    event OperationExecuted(uint256 indexed invokeID, uint40 invokeIDWei);
    event HeartBeat(uint256 groupIndex, uint256 time);
    event CurrentGroupIndexChanged(uint256 from, uint256 to, uint256 time);
  
    //----------------------------------------------------
    // external section 
    //----------------------------------------------------
    receive() external payable {
        heartbeat();
        uint256 invokeID = groups[currentGroupIndex].pairWeiInvokeId[uint40(msg.value)];
        _endorse(invokeID);
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external 
    {
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external
    {
    }

    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata/* data*/
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IControlContract).interfaceId;
    }

    
    //----------------------------------------------------
    // public section 
    //----------------------------------------------------
    /**
     * @dev here invokeRole can equal endorseRole withih one group but can't be in other groups
     * @param communityAddr community address
     * @param groupRoles tuples of GroupRolesSetting
     * @param costManager costManager address
     * @param minDelay minimum delay after last endorse, if minDelay = 0, operation executes immediately,
     *    otherwise it requires another call to execute() after minimumDelay passed
     * @param producedBy producedBy address
     * @custom:calledby factory
     * @custom:shortd initialize while factory produce
     */
    function init(
        address communityAddr,
        GroupRolesSetting[] memory groupRoles,
        uint16 minDelay,
        address costManager,
        address producedBy
    )
        public 
        initializer
    {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager);

        __Ownable_init();
        __ReentrancyGuard_init();
        
        communityAddress = communityAddr;
        lastRoleIndex = 0;
        minimumDelay = minDelay;
        
        /*
        [   //  invokeRole         endorseRole
            [Role#1Group#1,Role#5Group#1],
            [Role#2Group#2,Role#6Group#2],
            [Role#3Group#3,Role#7Group#3],
            [Role#4Group#4,Role#8Group#4]
        ]
        */
        if (
            (address(communityAddr) == address(0)) || ((address(communityAddr).isContract()) == false)
        ) {
            revert EmptyCommunityAddress();
        }
        if (groupRoles.length == 0) { 
            revert NoGroups();
        }
        
        currentGroupIndex = 0;
        maxGroupIndex = groupRoles.length;
        for (uint256 i = 0; i < groupRoles.length; i++) {
            
            if (
                (roleExists(groupRoles[i].invokeRole) == true) ||
                (roleExists(groupRoles[i].endorseRole) == true) ||
                (keccak256(abi.encodePacked(groupRoles[i].invokeRole)) == keccak256(abi.encodePacked(groupRoles[i].endorseRole)))
            ) {
                revert RoleExistsOrInvokeEqualEndorse();
            }

            groups[i].index = maxGroupIndex;
            groups[i].lastSeenTime = block.timestamp;
            groups[i].invokeRoles.add(roleAdd(groupRoles[i].invokeRole));
            groups[i].endorseRoles.add(roleAdd(groupRoles[i].endorseRole));
            
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(producedBy)),
            0
        );
    }
    
    /**
     * @param contractAddress address of external token
     * @param method method of external token that would be executed
     * @param params params of external token's method
     * @return invokeID result of previous call to invoke()
     * @custom:calledby persons with invoke roles
     * @custom:shortd invoke methods
     */
    function invoke(
        address contractAddress,
        string memory method,
        string memory params
    )
        public 
        canInvoke(contractAddress, method, _msgSender())
        returns(uint256 invokeID, uint40 invokeIDWei)
    {
        bytes32 k = keccak256(abi.encodePacked(contractAddress,method));
        if (methods[k].exists == false) {
            revert UnknownMethod(contractAddress, method);
        }
        
        heartbeat();
        
        invokeID = generateInvokeID();
        invokeIDWei = uint40(invokeID);
        
        groups[currentGroupIndex].pairWeiInvokeId[invokeIDWei] = invokeID;
        
        emit OperationInvoked(invokeID, invokeIDWei, contractAddress, method, params);
        
        groups[currentGroupIndex].operations[invokeID].addr = methods[k].addr;
        groups[currentGroupIndex].operations[invokeID].method = methods[k].method;
        groups[currentGroupIndex].operations[invokeID].params = params;
        groups[currentGroupIndex].operations[invokeID].minimum = methods[k].minimum;
        groups[currentGroupIndex].operations[invokeID].fraction = methods[k].fraction;
        
        groups[currentGroupIndex].operations[invokeID].exists = true;
        
        _accountForOperation(
            OPERATION_INVOKE << OPERATION_SHIFT_BITS,
            uint256(uint160(contractAddress)),
            0
        );
    }
    
    /**
     * @param invokeID result of previous call to invoke()
     * @custom:calledby persons with endorse roles
     * @custom:shortd endorse methods by invokeID
     */
    function endorse(
        uint256 invokeID
    ) 
        public
    {
        heartbeat();
        _endorse(invokeID);
    }

    /**
     * @param contractAddress token's address
     * @param method hexademical method's string
     * @param invokeRoleId invoke role id
     * @param endorseRoleId endorse role id
     * @param minimum  minimum
     * @param fraction fraction value mul by 1e10
     * @custom:calledby owner
     * @custom:shortd adding method to be able to invoke
     */
    function addMethod(
        address contractAddress,
        string memory method,
        uint8 invokeRoleId,
        uint8 endorseRoleId,
        uint256 minimum,
        uint256 fraction
    )
        public 
        onlyOwner 
    {
        bytes32 k = keccak256(abi.encodePacked(contractAddress,method));
        
        if (!roleExists(invokeRoleId)) {
            revert RoleDoesNotExist(invokeRoleId);
        }
        
        // require(methods[k].exists == false, "Such method has already registered");
        if (methods[k].exists == false) {

        } else {
            if ((methods[k].minimum == minimum) && (methods[k].fraction == fraction)) {
            } else {
                revert MethodAlreadyRegistered(method, minimum, fraction);
            }
        }
        
        methods[k].exists = true;
        methods[k].addr = contractAddress;
        methods[k].method = method;
        methods[k].minimum = minimum;
        methods[k].fraction = fraction;
        methods[k].invokeRolesAllowed.add(roleIDs[invokeRoleId]);
        methods[k].endorseRolesAllowed.add(roleIDs[endorseRoleId]);
        
        _accountForOperation(
            OPERATION_ADD_METHOD << OPERATION_SHIFT_BITS,
            uint256(uint160(contractAddress)),
            0
        );
    }

    /**
     * prolonging user current group ownership. 
     * or transferring to next if previous expired
     * or restore previous if user belong to group which index less then current
     * @custom:calledby anyone
     * @custom:shortd prolonging user current group ownership
     */
    function heartbeat(
    ) 
        public
    {
    
        uint256 len = 0;
        uint256 ii = 0;
        address[] memory addrs = new address[](1);
        addrs[0] = _msgSender();

        uint8[][] memory roles = ICommunity(communityAddress).getRoles(addrs);
        for (uint256 i = 0; i < maxGroupIndex; i++) {
            for (uint256 j = 0; j < roles[0].length; j++) {
                if (
                    groups[i].invokeRoles.contains(roleIDs[roles[0][j]]) ||
                    groups[i].endorseRoles.contains(roleIDs[roles[0][j]])
                ) {
                    len += 1;
                }
            }
        }
        
        uint256[] memory userRoleIndexes = new uint256[](len);
        for (uint256 i = 0; i < maxGroupIndex; i++) {
            for (uint256 j = 0; j < roles[0].length; j++) {
                if (
                    groups[i].invokeRoles.contains(roleIDs[roles[0][j]]) ||
                    groups[i].endorseRoles.contains(roleIDs[roles[0][j]])
                ) {
                    
                    userRoleIndexes[ii] = i;
                    ii += 1;
                }
            }
        }
        
        uint256 expectGroupIndex = _getExpectGroupIndex();

        bool isBreak = false;
        uint256 itGroupIndex;

        for (uint256 i = 0; i <= expectGroupIndex; i++) {
            for (uint256 j = 0; j < userRoleIndexes.length; j++) { 
                if (i == userRoleIndexes[j]) {
                    itGroupIndex = i;
                    isBreak = true;
                    break;
                }
            }
            if (isBreak) {
                break;
            }
        }

        if (!isBreak) {
            revert SenderIsNotInCurrentOwnerGroup(_msgSender(), currentGroupIndex);
        }
        
        if (currentGroupIndex != itGroupIndex) {
            emit CurrentGroupIndexChanged(currentGroupIndex, itGroupIndex, block.timestamp);
        }
        currentGroupIndex = itGroupIndex;
        groups[itGroupIndex].lastSeenTime = block.timestamp;
        
        emit HeartBeat(currentGroupIndex, block.timestamp);

    }
    
    /**
     * @return index expected groupIndex.
     * @custom:calledby anyone
     * @custom:shortd showing expected group index
     */
    function getExpectGroupIndex(
    ) 
        public 
        view 
        returns(uint256 index) 
    {
        return _getExpectGroupIndex();
    }

    //----------------------------------------------------
    // internal section 
    //----------------------------------------------------
    
    /**
    * @return index expected groupIndex.
    */
    function _getExpectGroupIndex(
    ) 
        internal
        view 
        returns(uint256 index) 
    {
        index = currentGroupIndex;
        if (groups[currentGroupIndex].lastSeenTime + groupTimeoutActivity < block.timestamp) {
            index = currentGroupIndex + (
                (block.timestamp - groups[currentGroupIndex].lastSeenTime) / groupTimeoutActivity
            );
            if (maxGroupIndex <= index) {
                index = maxGroupIndex-1;
            }
        }
    }

    /**
     * @param invokeID result of previous call to invoke()
     */
    function _endorse(
        uint256 invokeID
    ) 
        internal
        nonReentrant()
    {
        Operation storage operation = groups[currentGroupIndex].operations[invokeID];
        // note that `invokeID` can be zero if come from _receive !! and tx should be revert
        if (operation.exists == false) {revert UnknownInvokeId(invokeID);}

        uint8[] memory roles = getEndorsedRoles(operation.addr, operation.method, _msgSender());
        if (roles.length == 0) {
            revert MissingEndorseRole(_msgSender());
        }
        
        if (operation.endorsedAccounts.contains(_msgSender()) == true) {
            revert AlreadyEndorsed(_msgSender());
        }
        
        if (operation.executed == true) {
            revert AlreadyExecuted(invokeID);
        }
        
        operation.endorsedAccounts.add(_msgSender());
        
        emit OperationEndorsed(invokeID, uint40(invokeID));
        
        uint256 memberCount;
        for (uint256 i = 0; i < roles.length; i++) {
            memberCount = ICommunity(communityAddress).addressesCount(roles[i]);
            //---
            uint256 max;
            max = memberCount * (operation.fraction) / (fractionDiv);
            if (operation.minimum > max) {
                max = operation.minimum;
            }
            //---
            if (operation.endorsedAccounts.length() >= max) {

                operation.approvedTime = uint64(block.timestamp);

                if (minimumDelay == 0) {
                    _execute(invokeID);
                }
                break;
            }
            
        }

        _accountForOperation(
            OPERATION_ENDORSE << OPERATION_SHIFT_BITS,
            uint256(uint160(_msgSender())),
            uint256(uint160(operation.addr))
        );
    }
    /**
     * @param invokeID result of previous call to invoke()
     */
    function execute(
        uint256 invokeID
    )
        public
        nonReentrant()
    {
        _execute(invokeID);
    }
    
    function _execute(
        uint256 invokeID
    )
        internal
    {
        Operation storage operation = groups[currentGroupIndex].operations[invokeID];
        if (operation.approvedTime == 0) {
            revert NotYetApproved(invokeID);
        }
        if (operation.executed == true) {
            revert AlreadyExecuted(invokeID);
        }
        if (block.timestamp - operation.approvedTime < minimumDelay) {
            revert MinimumDelayMustElapse(invokeID);
        }
        (
            operation.success, 
            operation.msg
        ) = operation.addr.call(
            (
                string(abi.encodePacked(
                    operation.method, 
                    operation.params
                ))
            ).fromHex()
        );
        emit OperationExecuted(invokeID, uint40(invokeID));
    }
 
    
    /**
     * getting all endorse roles by sender's address and expected pair contract/method
     * 
     * @param contractAddress token's address
     * @param method hexademical method's string
     * @param sender sender address
     * @return endorse roles 
     */
    function getEndorsedRoles(
        address contractAddress, 
        string memory method, 
        address sender
    ) 
        internal 
        view 
        returns(uint8[] memory) 
    {
        address[] memory addrs = new address[](1);
        addrs[0] = sender;

        uint8[][] memory roles = ICommunity(communityAddress).getRoles(addrs);
        uint256 len;

        for (uint256 i = 0; i < roles.length; i++) {
            if (methods[keccak256(abi.encodePacked(contractAddress,method))].endorseRolesAllowed.contains(roleIDs[roles[0][i]])) {
                len += 1;
            }
        }
        uint8[] memory list = new uint8[](len);
        uint256 j = 0;
        for (uint256 i = 0; i < roles[0].length; i++) {
            if (methods[keccak256(abi.encodePacked(contractAddress,method))].endorseRolesAllowed.contains(roleIDs[roles[0][i]])) {
                list[j] = roles[0][i];
                j += 1;
            }
        }
        return list;
    }
    
    /**
     * adding role to general list
     * 
     * @param roleId roleid
     * 
     * @return index true if was added and false if already exists
     */
    function roleAdd(
        uint8 roleId
    ) 
        internal 
        returns(uint256 index) 
    {
        if (roleIDs[roleId] == 0) {
            lastRoleIndex += 1;
            roleIDs[roleId] = lastRoleIndex;
            index = lastRoleIndex;
        } else {
            index = roleIDs[roleId];
        }
    }
    
    /**
     * @param roleID role id
     * @return ret true if roleName exists in general list
     */
    function roleExists(
        uint8 roleID
    ) 
        internal 
        view
        returns(bool ret) 
    {
        ret = (roleIDs[roleID] == 0) ? false : true;
    }
    
    /**
     * generating pseudo-random id to be used as invokeID later
     * @return uint256 that can be used in other calls
     */
    function generateInvokeID(
    ) 
        internal 
        view 
        returns(uint256) 
    {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            block.difficulty, 
            msg.sender
        )));    
    }
    

}