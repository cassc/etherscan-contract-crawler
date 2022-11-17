// SPDX-License-Identifier: BSL
pragma solidity ^0.8.17;

/**
*   [BSL License]
*   @title CM Proxy contract implementation.
*   @notice Individual contract is created after proposal has been sent to the partner. 
    ETH stake will be deposited to this newly created contract.
*   @dev The proxy uses Diamond Pattern for modularity. Relevant code was borrowed from  
    Nick Mudge <[email protected]>. 
*   Reimbursement of sponsored TXFee through 
    MinimalForwarder, amounts to full estimated TX Costs of relevant 
    functions.   
*   @author Ismailov Altynbek <[email protected]>
*/

import "@gnus.ai/contracts-upgradeable-diamond/proxy/utils/Initializable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/security/ReentrancyGuardUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/metatx/ERC2771ContextUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/metatx/MinimalForwarderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./handlers/SecuredTokenTransfer.sol";
import "./handlers/DefaultCallbackHandler.sol";

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {VoteProposalLib} from "./libraries/VotingStatusLib.sol";

/*Interface for the Main Contract*/
interface WaverContract {
    function burn(address _to, uint256 _amount) external;

    function addFamilyMember(address, uint256) external;

    function cancel(uint256) external;

    function deleteFamilyMember(address, uint) external;

    function divorceUpdate(uint256 _id) external;

    function addressNFTSplit() external returns (address);
    
    function promoDays() external returns (uint);
}

/*Interface for the NFT Split Contract*/

interface nftSplitInstance {
    function splitNFT(
        address _nft_Address,
        uint256 _tokenID,
        string memory image,
        address waver,
        address proposed,
        address _implementationAddr,
        uint shareDivide
    ) external;
}

contract WaverIDiamond is
    Initializable,
    SecuredTokenTransfer,
    DefaultCallbackHandler,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    string public constant VERSION = "1.0.1";
    address immutable diamondcut;
    /*Constructor to connect Forwarder Address*/
    constructor(MinimalForwarderUpgradeable forwarder, address _diamondcut)
        initializer
        ERC2771ContextUpgradeable(address(forwarder))
    {diamondcut = _diamondcut;}

    /**
     * @notice Initialization function of the proxy contract
     * @dev Initialization params are passed from the main contract.
     * @param _addressWaveContract Address of the main contract.
     * @param _id Marriage ID assigned by the main contract.
     * @param _proposer Address of the prpoposer.
     * @param _proposer Address of the proposed.
     * @param _policyDays Cooldown before dissolution
     * @param _cmFee CM fee, as a small percentage of incoming and outgoing transactions.
     * @param _divideShare the share that will be divided among partners upon dissolution.
     */

    function initialize(
        address payable _addressWaveContract,
        uint256 _id,
        address _proposer,
        address _proposed,
        uint256 _policyDays,
        uint256 _cmFee,
        uint256 _minimumDeadline,
        uint256 _divideShare,
        uint256 promoDays
    ) public initializer {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        unchecked {
            vt.voteid++;
        }
        vt.addressWaveContract = _addressWaveContract;
        vt.marriageStatus = VoteProposalLib.MarriageStatus.Proposed;
        vt.hasAccess[_proposer] = true;
        vt.id = _id;
        vt.proposer = _proposer;
        vt.proposed = _proposed;
        vt.cmFee = _cmFee;
        vt.policyDays = _policyDays;
        vt.setDeadline = _minimumDeadline;
        vt.divideShare = _divideShare;
        vt.promoDays = promoDays;

         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
         ds.waveAddress=_addressWaveContract;

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory functionSelectors = new bytes4[](1);

        functionSelectors[0] = IDiamondCut.diamondCut.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: diamondcut,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }

    /**
     *@notice Proposer can cancel access to the contract if response has not been reveived or accepted. 
      The ETH balance of the contract will be sent to the proposer.   
     *@dev Once trigerred the access to the proxy contract will not be possible from the CM Frontend. Access is preserved 
     from the custom fronted such as Remix.   
     */

    function cancel() external {
        VoteProposalLib.enforceNotYetMarried();
        VoteProposalLib.enforceUserHasAccess(_msgSender());

        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        vt.marriageStatus = VoteProposalLib.MarriageStatus.Cancelled;
        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);
        _wavercContract.cancel(vt.id);

        VoteProposalLib.processtxn(
            vt.addressWaveContract,
            (address(this).balance * vt.cmFee) / 10000
        );
        VoteProposalLib.processtxn(payable(vt.proposer), address(this).balance);
    }

    /**
     *@notice If the proposal is accepted, triggers this function to be added to the proxy contract.
     *@dev this function is called from the Main Contract.
     */

    function agreed() external {
        VoteProposalLib.enforceContractHasAccess();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        vt.marriageStatus = VoteProposalLib.MarriageStatus.Married;
        vt.marryDate = block.timestamp;
        vt.hasAccess[vt.proposed] = true;
        vt.familyMembers = 2;
    }

    /**
     *@notice If the proposal is declined, the status is changed accordingly.
     *@dev this function is called from the Main Contract.
     */

    function declined() external {
        VoteProposalLib.enforceContractHasAccess();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        vt.marriageStatus = VoteProposalLib.MarriageStatus.Declined;
    }

    error DISSOLUTION_COOLDOWN_NOT_PASSED(uint cooldown);
   
    /**
     * @notice Through this method proposals for voting is created. 
     * @dev All params are required. tokenID for the native currency is 0x0 address. To create proposals it is necessary to 
     have LOVE tokens as it will be used as backing of the proposal. 
     * @param _message String text on details of the proposal. 
     * @param _votetype Type of the proposal as it was listed in enum above. 
     * @param _voteends Timestamp on when the voting ends
     * @param _numTokens Number of LOVE tokens that is used to back this proposal. 
     * @param _receiver Address of the receiver who will be receiving indicated amounts. 
     * @param _tokenID Address of the ERC20, ERC721 or other tokens. 
     * @param _amount The amount of token that is being sent. Alternatively can be used as NFT ID. 
     */

    function createProposal(
        string calldata _message,
        uint8 _votetype,
        uint256 _voteends,
        uint256 _numTokens,
        address payable _receiver,
        address _tokenID,
        uint256 _amount
    ) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceUserHasAccess(msgSender_);
        VoteProposalLib.enforceMarried();


        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);
          
        if (_votetype == 4) {
             //Cooldown has to pass before divorce is proposed.
            if (vt.marryDate + vt.policyDays > block.timestamp) { revert DISSOLUTION_COOLDOWN_NOT_PASSED(vt.marryDate + vt.policyDays );}
           
            //Only partners can propose divorce
            VoteProposalLib.enforceOnlyPartners(msgSender_);
            vt.numTokenFor[vt.voteid] = 1e30;
            _voteends = block.timestamp + 10 days;
        } else {
            vt.numTokenFor[vt.voteid] = _numTokens;
            if (_voteends < block.timestamp + vt.setDeadline) {_voteends = block.timestamp + vt.setDeadline; } //Checking for too short notice
        }

        vt.voteProposalAttributes[vt.voteid] = VoteProposalLib.VoteProposal({
            id: vt.voteid,
            proposer: msgSender_,
            voteType: _votetype,
            tokenVoteQuantity: _numTokens,
            voteProposalText: _message,
            voteStatus: 1,
            voteends: _voteends,
            receiver: _receiver,
            tokenID: _tokenID,
            amount: _amount,
            votersLeft: vt.familyMembers - 1
        });

        vt.votingStatus[vt.voteid][msgSender_] = true;
        _wavercContract.burn(msgSender_, _numTokens);

       emit VoteProposalLib.VoteStatus(
            vt.voteid,
            msgSender_,
            1,
            block.timestamp
        ); 

        unchecked {
            vt.voteid++;
        }
        checkForwarder(vt);
    }

    /**
     * @notice Through this method, proposals are voted for/against.  
     * @dev A user cannot vote twice. User cannot vote on voting which has been already passed/declined. Token staked is burnt.
     There is no explicit ways of identifying votes for or against the vote. 
     * @param _id Vote ID, that is being voted for/against. 
     * @param _numTokens Number of LOVE tokens that is being backed within the vote. 
     * @param responsetype Voting response for/against
     */

    function voteResponse(
        uint24 _id,
        uint256 _numTokens,
        uint8 responsetype
    ) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceUserHasAccess(msgSender_);
        VoteProposalLib.enforceNotVoted(_id,msgSender_);
        VoteProposalLib.enforceProposedStatus(_id);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);

        vt.votingStatus[_id][msgSender_] = true;
        vt.voteProposalAttributes[_id].votersLeft -= 1;

        if (responsetype == 2) {
            vt.numTokenFor[_id] += _numTokens;
        } else {
            vt.numTokenAgainst[_id] += _numTokens;
        }

        if (vt.voteProposalAttributes[_id].votersLeft == 0) {
            if (vt.numTokenFor[_id] < vt.numTokenAgainst[_id]) {
                vt.voteProposalAttributes[_id].voteStatus = 3;
            } else {
                vt.voteProposalAttributes[_id].voteStatus = 2;
            }
        }

        _wavercContract.burn(msgSender_, _numTokens);
         emit VoteProposalLib.VoteStatus(
            _id,
            msgSender_,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        );  
        checkForwarder(vt);
    }

    /**
     * @notice The vote can be cancelled by the proposer if it has not been passed.
     * @dev once cancelled the proposal cannot be voted or executed.
     * @param _id Vote ID, that is being voted for/against.
     */

    function cancelVoting(uint24 _id) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceProposedStatus(_id);
        VoteProposalLib.enforceOnlyProposer(_id, msgSender_);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        vt.voteProposalAttributes[_id].voteStatus = 4;

       emit VoteProposalLib.VoteStatus(
            _id,
            msgSender_,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        ); 
        checkForwarder(vt);
    }

    /**
     * @notice The vote can be processed if deadline has been passed.
     * @dev voteend is compounded. The status of the vote proposal depends on number of Tokens voted for/against.
     * @param _id Vote ID, that is being voted for/against.
     */

    function endVotingByTime(uint24 _id) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceOnlyPartners(msgSender_);
        VoteProposalLib.enforceProposedStatus(_id);
        VoteProposalLib.enforceDeadlinePassed(_id);

        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        if (vt.numTokenFor[_id] < vt.numTokenAgainst[_id]) {
            vt.voteProposalAttributes[_id].voteStatus = 3;
        } else {
            vt.voteProposalAttributes[_id].voteStatus = 7;
        }

      emit VoteProposalLib.VoteStatus(
            _id,
            msgSender_ ,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        ); 
        checkForwarder(vt);
    }

error VOTE_ID_NOT_FOUND();
    /**
     * @notice If the proposal has been passed, depending on vote type, the proposal is executed.
     * @dev  Two external protocols are used Uniswap and Compound.
     * @param _id Vote ID, that is being voted for/against.
     */

    function executeVoting(uint24 _id) external nonReentrant {
        VoteProposalLib.enforceMarried();
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        VoteProposalLib.enforceAcceptedStatus(_id);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);
        //A small fee for the protocol is deducted here
        uint256 _amount = (vt.voteProposalAttributes[_id].amount *
            (10000 - vt.cmFee)) / 10000;
        uint256 _cmfees = vt.voteProposalAttributes[_id].amount - _amount;

        // Sending ETH from the contract
        if (vt.voteProposalAttributes[_id].voteType == 3) {
            vt.voteProposalAttributes[_id].voteStatus = 5;
            VoteProposalLib.processtxn(vt.addressWaveContract, _cmfees);
            VoteProposalLib.processtxn(
                payable(vt.voteProposalAttributes[_id].receiver),
                _amount
            );
            
        }
        //Sending ERC20 tokens owned by the contract
        else if (vt.voteProposalAttributes[_id].voteType == 2) {
            vt.voteProposalAttributes[_id].voteStatus = 5;
            require(
                transferToken(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                ),"I101"
            );
            require(
                transferToken(
                    vt.voteProposalAttributes[_id].tokenID,
                    payable(vt.voteProposalAttributes[_id].receiver),
                    _amount
                ),"I101"
            );
            
        }
         else if (vt.voteProposalAttributes[_id].voteType == 3) {
            VoteProposalLib.processtxn(vt.addressWaveContract, _cmfees);
            VoteProposalLib.processtxn(payable(vt.voteProposalAttributes[_id].receiver), _amount);
        
            vt.voteProposalAttributes[_id].voteStatus = 5;
        }
        //This is if two sides decide to divorce, funds are split between partners
        else if (vt.voteProposalAttributes[_id].voteType == 4) {
            vt.marriageStatus = VoteProposalLib.MarriageStatus.Divorced;
            vt.voteProposalAttributes[_id].voteStatus = 6;

            VoteProposalLib.processtxn(
                vt.addressWaveContract,
                (address(this).balance * vt.cmFee) / 10000
            );

            uint256 shareProposer = address(this).balance * vt.divideShare/10;
            uint256 shareProposed = address(this).balance - shareProposer;

            VoteProposalLib.processtxn(payable(vt.proposer), shareProposer);
            VoteProposalLib.processtxn(payable(vt.proposed), shareProposed);

            _wavercContract.divorceUpdate(vt.id);

            //Sending ERC721 tokens owned by the contract
        } else if (vt.voteProposalAttributes[_id].voteType == 5) {
            vt.voteProposalAttributes[_id].voteStatus = 10;
            IERC721(vt.voteProposalAttributes[_id].tokenID).safeTransferFrom(
                address(this),
                vt.voteProposalAttributes[_id].receiver,
                vt.voteProposalAttributes[_id].amount
            );
            
        } else if (vt.voteProposalAttributes[_id].voteType == 6) {
            vt.voteProposalAttributes[_id].voteStatus = 11;
            vt.setDeadline = vt.voteProposalAttributes[_id].amount;
        } else {
            revert VOTE_ID_NOT_FOUND();
        }
       emit VoteProposalLib.VoteStatus(
            _id,
            msg.sender,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        ); 
    }

    /**
     * @notice Function to reimburse transactions costs of relayers. 
     * @dev 1050000 is a max gas limit put by the OZ relaying platform. 2400 is .call gas cost that was not taken into account.
     * @param vt is a storage parameter to process payment.      
     */

    function checkForwarder(
        VoteProposalLib.VoteTracking storage vt
    ) internal {
        if (isTrustedForwarder(msg.sender)) {
            uint Gasleft = (1050000- gasleft() + 2400)* tx.gasprice;
            VoteProposalLib.processtxn(
                vt.addressWaveContract,
                Gasleft
            );
        }
    }
      /**
     * @notice A view function to monitor balance
     */

    function balance() external view returns (uint ETHBalance) {
       return address(this).balance;
    }

    error TOO_MANY_MEMBERS();
    /**
     * @notice Through this method a family member can be invited. Once added, the user needs to accept invitation.
     * @dev Only partners can add new family member. Partners cannot add their current addresses.
     * @param _member The address who are being invited to the proxy.
     */

    function addFamilyMember(address _member) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceOnlyPartners(msgSender_);
        VoteProposalLib.enforceNotPartnerAddr(_member);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        if (vt.familyMembers > 50) {revert TOO_MANY_MEMBERS();}
       
        WaverContract _waverContract = WaverContract(vt.addressWaveContract);
        _waverContract.addFamilyMember(_member, vt.id);
        checkForwarder(vt);
    }

    /**
     * @notice Through this method a family member is added once invitation is accepted.
     * @dev This method is called by the main contract.
     * @param _member The address that is being added.
     */

    function _addFamilyMember(address _member) external {
        VoteProposalLib.enforceContractHasAccess();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        vt.hasAccess[_member] = true;
        vt.familyMembers += 1;
    }

    /**
     * @notice Through this method a family member can be deleted. Member can be deleted by partners or by the members own address.
     * @dev Member looses access and will not be able to access to the proxy contract from the front end. Member address cannot be that of partners'.
     * @param _member The address who are being deleted.
     */

    function deleteFamilyMember(address _member) external {
        address msgSender_ = _msgSender();
        VoteProposalLib.enforceOnlyPartners(msgSender_);
        VoteProposalLib.enforceNotPartnerAddr(_member);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        WaverContract _waverContract = WaverContract(vt.addressWaveContract);

        _waverContract.deleteFamilyMember(_member,vt.id);
        if (vt.hasAccess[_member] == true) {
        delete vt.hasAccess[_member];
        vt.familyMembers -= 1;}
        checkForwarder(vt);
    }

    /* Divorce settlement. Once Divorce is processed there are 
    other assets that have to be split*/

    /**
     * @notice Once divorced, partners can split ERC20 tokens owned by the proxy contract.
     * @dev Each partner/or other family member can call this function to transfer ERC20 to respective wallets.
     * @param _tokenID the address of the ERC20 token that is being split.
     */

    function withdrawERC20(address _tokenID) external {
        VoteProposalLib.enforceOnlyPartners(msg.sender);
        VoteProposalLib.enforceDivorced();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        uint256 amount = IERC20Upgradeable(_tokenID).balanceOf(address(this));
        uint256 amountFee = (amount * vt.cmFee) / 10000;

        require(
            transferToken(
                _tokenID,
                vt.addressWaveContract,
                amountFee
            ),"I101"
        );
         amount = (amount - amountFee);
        uint256 shareProposer = amount * vt.divideShare/10;
        uint256 shareProposed = amount - shareProposer;

        require(transferToken(_tokenID, vt.proposer, shareProposer),"I101");
        require(transferToken(_tokenID, vt.proposed, shareProposed),"I101");
    }

    /**
     * @notice Before partner user accepts invitiation, initiator can claim ERC20 tokens back.
     * @dev Only Initiator can claim ERC20 tokens
     * @param _tokenID the address of the ERC20 token.
     */

    function earlyWithdrawERC20(address _tokenID) external {
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        VoteProposalLib.enforceNotYetMarried();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        uint256 amount = IERC20Upgradeable(_tokenID).balanceOf(address(this));
        uint256 amountFee = (amount * vt.cmFee) / 10000;

        require(
            transferToken(
                _tokenID,
                vt.addressWaveContract,
                amountFee
            ),"I101"
        );
         amount = (amount - amountFee);

        require(transferToken(_tokenID, vt.proposer, amount),"I101");
    }
    /**
     * @notice Once divorced, partners can split ERC721 tokens owned by the proxy contract. 
     * @dev Each partner/or other family member can call this function to split ERC721 token between partners.
     Two identical copies of ERC721 will be created by the NFT Splitter contract creating a new ERC1155 token.
      The token will be marked as "Copy". 
     To retreive the original copy, the owner needs to have both copies of the NFT. 

     * @param _tokenAddr the address of the ERC721 token that is being split. 
     * @param _tokenID the ID of the ERC721 token that is being split
     * @param image the Image of the NFT 
     */

    function SplitNFT(
        address _tokenAddr,
        uint256 _tokenID,
        string calldata image
    ) external {
        VoteProposalLib.enforceOnlyPartners(msg.sender);
        VoteProposalLib.enforceDivorced();
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();

        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);
        address nftSplitAddr = _wavercContract.addressNFTSplit(); //gets NFT splitter address from the main contract
        nftSplitInstance nftSplit = nftSplitInstance(nftSplitAddr);
        nftSplit.splitNFT(
            _tokenAddr,
            _tokenID,
            image,
            vt.proposer,
            vt.proposed,
            address(this),
            vt.divideShare
        ); //A copy of the NFT is created by the NFT Splitter.
    }

    /**
     * @notice If partner acquires both copies of NFTs, the NFT can be redeemed by that partner through NFT Splitter contract. 
     NFT Splitter uses this function to implement transfer of the token. Only Splitter Contract can call this function. 
     * @param _tokenAddr the address of the ERC721 token that is being joined. 
     * @param _receipent the address of the ERC721 token that is being sent. 
     * @param _tokenID the ID of the ERC721 token that is being sent
     */

    function sendNft(
        address _tokenAddr,
        address _receipent,
        uint256 _tokenID
    ) external {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        WaverContract _wavercContract = WaverContract(vt.addressWaveContract);
        if (_wavercContract.addressNFTSplit() != msg.sender) {revert VoteProposalLib.CONTRACT_NOT_AUTHORIZED(msg.sender);}
        IERC721(_tokenAddr).safeTransferFrom(
            address(this),
            _receipent,
            _tokenID
        );
    }

    /* Checking and Querying the voting data*/

    /* This view function returns how many votes has been created*/
    function getVoteLength() external view returns (uint256) {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        return vt.voteid - 1;
    }

    /**
     * @notice This function is used to query votings.  
     * @dev Since there is no limit for the number of voting proposals, the proposals are paginated. 
     Web queries page number to get voting statuses. Each page has 20 vote proposals. 
     * @param _pagenumber A page number queried.   
     */

    function getVotingStatuses(uint24 _pagenumber)
        external
        view
        returns (VoteProposalLib.VoteProposal[] memory)
    {
        VoteProposalLib.enforceUserHasAccess(msg.sender);

        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        uint24 length = vt.voteid - 1;
        uint24 page = length / 20;
        uint24 size = 0;
        uint24 start = 0;
        if (_pagenumber * 20 > length) {
            size = length % 20;
            if (size == 0 && page != 0) {
                size = 20;
                page -= 1;
            }
            start = page * 20 + 1;
        } else if (_pagenumber * 20 <= length) {
            size = 20;
            start = (_pagenumber - 1) * 20 + 1;
        }

        VoteProposalLib.VoteProposal[]
            memory votings = new VoteProposalLib.VoteProposal[](size);

        for (uint24 i = 0; i < size; i++) {
            votings[i] = vt.voteProposalAttributes[start + i];
        }
        return votings;
    }
    /* Getter of Family Members Number*/
    function getFamilyMembersNumber() external view returns (uint256) {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        return vt.familyMembers;
    }

    /* Getter of Family Members Number*/
    function getCMfee() external view returns (uint256) {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        return vt.cmFee;
    }
  
      /* Getter of cooldown before divorce*/

    function getPolicies() external view 
    returns (uint policyDays, uint marryDate, uint divideShare, uint setDeadline, uint promoDays) 
    {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        return (vt.policyDays,
                vt.marryDate,
                vt.divideShare,
                vt.setDeadline,
                vt.promoDays);
    }

    error NOT_IN_PROMO();
    error PROMO_NOT_PASSED();
    /**
     * @notice A user may have a promo period with zero comissions 
     * @dev a function may be called externally and triggered by bot to check whether promo period has passed.  
     */
    function resetFee() external {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        if (vt.cmFee>0) {revert NOT_IN_PROMO(); }
        if (vt.marryDate + vt.promoDays < block.timestamp) {
            vt.cmFee = 100;
         } else { revert PROMO_NOT_PASSED();} //add else and revert...    
    }

 /* Getter of marriage status*/
    function getMarriageStatus()
        external
        view
        returns (VoteProposalLib.MarriageStatus)
    {
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
        return vt.marriageStatus;
    }

    /* Checker of whether Module (Facet) is connected*/
    function checkAppConnected(address appAddress)
        external
        view
        returns (bool)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.connectedApps[appAddress];
    }

    error FACET_DOES_NOT_EXIST(address facet);
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds
            .facetAddressAndSelectorPosition[msg.sig]
            .facetAddress;
        if (facet == address(0)) {revert FACET_DOES_NOT_EXIST(facet);}
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice A fallback function that receives native currency.
     * @dev It is required that the status is not divorced so that funds are not locked.
     */
    receive() external payable {
        require(msg.value > 0);
        if (gasleft() > 2300) {
            VoteProposalLib.enforceNotDivorced();
            VoteProposalLib.VoteTracking storage vt = VoteProposalLib
                .VoteTrackingStorage();
            VoteProposalLib.processtxn(
                vt.addressWaveContract,
                (msg.value * vt.cmFee) / 10000
            );
            emit VoteProposalLib.AddStake(
                msg.sender,
                address(this),
                block.timestamp,
                msg.value
            ); 
        }
    }
}