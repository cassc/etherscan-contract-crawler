// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "./CommunityStorage.sol";
import "./CommunityState.sol";
import "./CommunityView.sol";
import "./interfaces/ICommunity.sol";

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
contract Community is CommunityStorage, ICommunity {
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;


    CommunityState implCommunityState;
    CommunityView implCommunityView;

    /**
    * @notice initializes contract
    */
    function initialize(
        address implCommunityState_,
        address implCommunityView_,
        address hook,
        address costManager_,
        string memory name, 
        string memory symbol
    ) 
        public 
        override
        initializer 
    {

        implCommunityState = CommunityState(implCommunityState_);
        implCommunityView = CommunityView(implCommunityView_);

        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);
        
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.initialize.selector,
                hook, name, symbol
            )
            //msg.data
        );
        
        
        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(hook)),
            uint256(uint160(costManager_))
        );
    }


    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////

    /**
    * @notice the way to withdraw remaining ETH from the contract. called by owners only 
    * @custom:shortd the way to withdraw ETH from the contract.
    * @custom:calledby owners
    */
    function withdrawRemainingBalance(
    ) 
        public 
        nonReentrant()
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.withdrawRemainingBalance.selector
            // )
            msg.data
        );
    } 

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function grantRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    )
        public 
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.grantRoles.selector,
            //     accounts, roleIndexes
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }
    
    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function revokeRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        public 
    {

        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.revokeRoles.selector,
            //     accounts, roleIndexes
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }
    
    /**
     * @notice creating new role. can called owners role only
     * @custom:shortd creating new role. can called owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.createRole.selector,
            //     role
            // )
            msg.data
        );
        
        _accountForOperation(
            OPERATION_CREATE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );

    }
    
    /**
     * @notice allow account with byRole:
     * (if canGrantRole ==true) grant ofRole to another account if account has requireRole
     *          it can be available `maxAddresses` during `duration` time
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     * (if canRevokeRole ==true) revoke ofRole from account.
     */
    function manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    )
        public 
    {
        
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.manageRole.selector,
            //     byRole, ofRole, canGrantRole, canRevokeRole, requireRole, maxAddresses, duration
            // )
            msg.data
        );
        
        _accountForOperation(
            OPERATION_MANAGE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }
      
    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        override
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.setTrustedForwarder.selector,
            //     forwarder
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_SET_TRUSTED_FORWARDER << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice registering invite,. calling by relayers
     * @custom:shortd registering invite 
     * @param sSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        public 
        
        accummulateGasCost(sSig)
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.invitePrepare.selector,
            //     sSig, rSig
            // )
            msg.data
        );

        
        _accountForOperation(
            OPERATION_INVITE_PREPARE << OPERATION_SHIFT_BITS,
            0,
            0
        );

    }
    
    /**
     * @dev
     * @dev ==P==  
     * @dev format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  
     * @dev ==R==  
     * @dev format is "<address of R wallet>:<name of user>"  
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  
     * @notice accepting invite
     * @custom:shortd accepting invite
     * @param p invite message of admin whom generate messageHash and signed it
     * @param sSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function inviteAccept(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    )
        public 
        refundGasCost(sSig)
        nonReentrant()
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.inviteAccept.selector,
            //     p, sSig, rp, rSig
            // )
            msg.data
        );
        
        _accountForOperation(
            OPERATION_INVITE_ACCEPT << OPERATION_SHIFT_BITS,
            0,
            0
        );

    }

    /**
    * @notice setting tokenURI for role
    * @param roleIndex role index
    * @param roleURI token URI
    * @custom:shortd setting tokenURI for role
    * @custom:calledby any who can manage this role
    */
    function setRoleURI(
        uint8 roleIndex,
        string memory roleURI
    ) 
        public 
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.setRoleURI.selector,
            //     roleIndex, roleURI
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_SET_ROLE_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );

    }

    /**
    * @notice setting extra token URI for role
    * @param roleIndex role index
    * @param extraURI extra token URI
    * @notice setting extraURI for role.
    * @custom:calledby any who belong to role
    */
    function setExtraURI(
        uint8 roleIndex,
        string memory extraURI
    )
        public
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.setExtraURI.selector,
            //     roleIndex, extraURI
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_SET_EXTRA_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function transferOwnership(
        address newOwner
    ) 
        public 
        override
        onlyOwner 
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.setExtraURI.selector,
            //     roleIndex, extraURI
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_TRANSFEROWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            uint160(newOwner)
        );
    }

    function renounceOwnership(
    ) 
        public 
        override
        onlyOwner 
    {
        _functionDelegateCall(
            address(implCommunityState), 
            // abi.encodeWithSelector(
            //     CommunityState.setExtraURI.selector,
            //     roleIndex, extraURI
            // )
            msg.data
        );

        _accountForOperation(
            OPERATION_RENOUNCEOWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            0
        );
    }

    ///////////////////////////////////////////////////////////
    /// public (view)section
    ///////////////////////////////////////////////////////////
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses across all roles
     * @custom:shortd all addresses across all roles
     * @return two-dimensional array of addresses 
     */
    function getAddresses(
    ) 
        public 
        view
        returns(address[][] memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    bytes4(keccak256("getAddresses()"))
                ), 
                ""
            ), 
            (address[][])
        );  

    }
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param roleIndexes array of role's indexes
     * @return two-dimensional array of addresses 
     */
    function getAddresses(
        uint8[] calldata roleIndexes
    ) 
        public 
        view
        returns(address[][] memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.getAddresses.selector,
                    bytes4(keccak256("getAddresses(uint8[])")),
                    roleIndexes
                ), 
                ""
            ), 
            (address[][])
        );  

    }

    function getAddressesByRole(
        uint8 roleIndex, 
        uint256 offset, 
        uint256 limit
    ) 
        public 
        view
        returns(address[][] memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    CommunityView.getAddressesByRole.selector,
                    roleIndex, offset, limit
                ), 
                ""
            ), 
            (address[][])
        );  
    }
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param members member's addresses
     * @return l two-dimensional array of roles 
     */
    function getRoles(
        address[] memory members
    ) 
        public 
        view
        returns(uint8[][] memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.getRoles().selector,
                    bytes4(keccak256("getRoles(address[])")),
                    members
                ), 
                ""
            ), 
            (uint8[][])
        );  

    }
  
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles 
     * @custom:shortd all roles
     * @return arrays of (indexes, names, roleURIs)  
     */
    function getRoles(
    ) 
        public 
        view
        returns(uint8[] memory, string[] memory, string[] memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.getRoles.selector
                    bytes4(keccak256("getRoles()"))
                ), 
                ""
            ), 
            (uint8[], string[], string[])
        );  

    }
    
    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param roleIndex role index
     * @return count of members for that role
     */
    function addressesCount(
        uint8 roleIndex
    )
        public
        view
        returns(uint256)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.addressesCount.selector,
                    bytes4(keccak256("addressesCount(uint8)")),
                    roleIndex
                ), 
                ""
            ), 
            (uint256)
        );  

    }
        
    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all members count
     * @return count of members
     */
    function addressesCount(
    )
        public
        view
        returns(uint256)
    {
        return addressesCounter;
    }
    
    /**
     * @notice viewing invite by admin signature
     * @custom:shortd viewing invite by admin signature
     * @param sSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory sSig
    ) 
        public 
        view
        returns(inviteSignature memory)
    {
        return inviteSignatures[sSig];
    }
    
    

    /**
     * @notice is member has role
     * @custom:shortd checking is member belong to role
     * @param account user address
     * @param roleIndex role index
     * @return bool 
     */
    function hasRole(
        address account, 
        uint8 roleIndex
    ) 
        public 
        view 
        returns(bool) 
    {

        //require(_roles[rolename.stringToBytes32()] != 0, "Such role does not exists");
        return _rolesByAddress[account].contains(roleIndex);

    }

    /**
     * @notice return role index by name
     * @custom:shortd return role index by name
     * @param rolename role name in string
     * @return role index
     */
    function getRoleIndex(
        string memory rolename
    )
        public 
        view
        returns(uint8)
    {
        return _roles[rolename.stringToBytes32()];
    }
    
    /**
    * @notice getting balance of owner address
    * @param account user's address
    * @custom:shortd part of ERC721
    */
    function balanceOf(
        address account
    ) 
        external 
        view 
        override
        returns (uint256 balance) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    CommunityView.balanceOf.selector,
                    account
                ), 
                ""
            ), 
            (uint256)
        );  

    }

    /**
    * @notice getting owner of tokenId
    * @param tokenId tokenId
    * @custom:shortd part of ERC721
    */
    function ownerOf(
        uint256 tokenId
    ) 
        external 
        view 
        override
        returns (address) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    CommunityView.ownerOf.selector,
                    tokenId
                ), 
                ""
            ), 
            (address)
        );

    }
    
     /**
    * @notice getting tokenURI(part of ERC721)
    * @custom:shortd getting tokenURI
    * @param tokenId token ID
    * @return tokenuri
    */
    function tokenURI(
        uint256 tokenId
    ) 
        external 
        view 
        override 
        returns (string memory)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    CommunityView.tokenURI.selector,
                    tokenId
                ), 
                ""
            ), 
            (string)
        );
        
    }
  
 
  
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        //require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    function _functionDelegateCallView(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        //require(isContract(target), "Address: static call to non-contract");
        data = abi.encodePacked(target,data,msg.sender);    
        (bool success, bytes memory returndata) = address(this).staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    receive() external payable {}
    
    fallback() payable external {
        
        if (msg.sender == address(this)) {

            address implementationLogic;
            
            bytes memory msgData = msg.data;
            bytes memory msgDataPure;
            uint256 offsetnew;
            uint256 offsetold;
            uint256 i;
            
            // extract address implementation;
            assembly {
                implementationLogic:= mload(add(msgData,0x14))
            }
            
            msgDataPure = new bytes(msgData.length-20);
            uint256 max = msgData.length + 31;
            offsetold=20+32;        
            offsetnew=32;
            // extract keccak256 of methods's hash
            assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            
            // extract left data
            for (i=52+32; i<=max; i+=32) {
                offsetnew = i-20;
                offsetold = i;
                assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            }
            
            // finally make call
            (bool success, bytes memory data) = address(implementationLogic).delegatecall(msgDataPure);
            assembly {
                switch success
                    // delegatecall returns 0 on error.
                    case 0 { revert(add(data, 32), returndatasize()) }
                    default { return(add(data, 32), returndatasize()) }
            }
            
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}