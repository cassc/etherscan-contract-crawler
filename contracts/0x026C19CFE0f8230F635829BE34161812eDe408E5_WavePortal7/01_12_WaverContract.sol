/// SPDX-License-Identifier: BSL

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
[BSL License]
@title CryptoMarry contract
@notice This is the main contract that sets rules for proxy contract creation, minting ERC20 LOVE tokens,
minting NFT certificates, and other policies for the proxy contract. Description of the methods are provided 
below. 
@author Ismailov Altynbek <[email protected]>
 */

/*Interface for a Proxy Contract Factory*/
interface WaverFactoryC {
    function newMarriage(
        address _addressWaveContract,
        uint256 id,
        address _waver,
        address _proposed,
        uint256 policyDays,
        uint256 cmFee,
        uint256 _minimumDeadline,
        uint256 _divideShare
    ) external returns (address);

    function MarriageID(uint256 id) external returns (address);
}

/*Interface for a NFT Certificate Factory Contract*/
interface NFTContract {
    function mintCertificate(
        address _proposer,
        uint8 _hasensWaver,
        address _proposed,
        uint8 _hasensProposed,
        address _marriageContract,
        uint256 _id,
        uint256 _heartPatternsID,
        uint256 _certBackgroundID,
        uint256 mainID
    ) external;

    function changeStatus(
        address _marriageContract,
        bool _status
    ) external;

    function nftHolder(
        address _marriageContract
    ) external returns(uint);

}

/*Interface for a NFT split contracts*/
interface nftSplitC {
    function addAddresses(address _addAddresses) external;
}

/*Interface for a Proxy contract */
interface waverImplementation1 {
    function _addFamilyMember(address _member) external;

    function agreed() external;

    function declined() external;

    function getFamilyMembersNumber() external view returns (uint);

    function getCMfee() external view returns (uint);
}


contract WavePortal7 is ERC20, ERC2771Context, Ownable {
   
    address public addressNFT; // Address of NFT certificate factory
    address public addressNFTSplit; // Address of NFT splitting contract
    address public waverFactoryAddress; // Address of Proxy contract factory
    address public withdrawaddress; //Address to where comissions are withdrawed/

    uint256 internal id; //IDs of a marriage
    

    uint256 public claimPolicyDays; //Cooldown for claiming LOVE tokens;
    uint256 public promoDays; //promoDays for free 
    uint256 public saleCap; //Maximum cap of a LOVE token Sale
    uint256 public minPricePolicy; //Minimum price for NFTs
    uint256 public cmFee; // Small percentage paid by users for incoming and outgoing transactions.
    uint256 public exchangeRate; // Exchange rate for LOVE tokens for 1 ETH


    //Structs

    enum Status {
        Declined,
        Proposed,
        Cancelled,
        Accepted,
        Processed,
        Divorced,
        WaitingConfirmation,
        MemberInvited,
        InvitationAccepted,
        InvitationDeclined,
        MemberDeleted,
        PartnerAddressChanged
    }

    struct Wave {
        uint256 id;
        uint256 stake;
        address proposer;
        address proposed;
        Status ProposalStatus;
        address marriageContract;
    }

    struct Pause {
        address ContractAddress;
        uint Status;
    }

    mapping(address => uint256) internal proposers; //Marriage ID of proposer partner
    mapping(address => uint256) internal proposedto; //Marriage ID of proposed partner
    mapping(address => mapping(uint8 => uint256)) public member; //Stores family member IDs
    mapping(address => uint8) internal hasensName; //Whether a partner wants to display ENS address within the NFT
    mapping(uint256 => Wave) internal proposalAttributes; //Attributes of the Proposal of each marriage
    mapping(address => string) public messages; //stores messages of CM users
    mapping(address => uint8) internal authrizedAddresses; //Tracks whether a proxy contract addresses is authorized to interact with this contract.
    mapping(address => address[]) internal familyMembers; // List of family members addresses
    mapping(address => uint256) public claimtimer; //maps addresses to when the last time LOVE tokens were claimed.
    mapping(address => string) public nameAddress; //For giving Names for addresses. 
    mapping(address => uint) public pauseAddresses; //Addresses that can be paused.
    mapping(address => uint) public rewardAddresses; //Addresses that may claim reward. 
    mapping(address => string) public contactDetails; //Details of contact to send notifications

    /* An event to track status changes of the contract*/
    event NewWave(
        uint256 id,
        address sender,
        address indexed marriageContract,
        Status vid
    );


    /* A contructor that sets initial conditions of the Contract*/
    constructor(
        MinimalForwarder forwarder,
        address _nftaddress,
        address _waveFactory,
        address _withdrawaddress
    ) payable ERC20("CryptoMarry", "LOVE") ERC2771Context(address(forwarder)) {
        claimPolicyDays = 30 days;
        addressNFT = _nftaddress;
        saleCap = 1e25;
        minPricePolicy = 1e16 ;
        waverFactoryAddress = _waveFactory;
        //cmFee = 100;
        exchangeRate = 1000;
        withdrawaddress = _withdrawaddress;
        promoDays = 60 days;
    }

    error CONTRACT_NOT_AUTHORIZED(address contractAddress);

    /*This modifier check whether an address is authorised proxy contract*/
    modifier onlyContract() {
        if (authrizedAddresses[msg.sender] != 1) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        _;
    }

    /*These two below functions are to reconcile minimal Forwarder and ERC20 contracts for MSGSENDER */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    /** Errors replated to propose function */
     error YOU_CANNOT_PROPOSE_YOURSELF(address proposed);
     error USER_ALREADY_EXISTS_IN_CM(address user);
     error INALID_SHARE_PROPORTION(uint share);
     error PLATFORM_TEMPORARILY_PAUSED();
    /**
     * @notice Proposal and separate contract is created with given params.
     * @dev Proxy contract is created for each proposal. Most functions of the proxy contract will be available if proposal is accepted.
     * @param _proposed Address of the one whom proposal is send.
     * @param _message String message that will be sent to the proposed Address
     * @param _hasensWaver preference whether Proposer wants to display ENS on the NFT certificate
     */

    function propose(
        address _proposed,
        string memory _message,
        uint8 _hasensWaver,
        uint _policyDays,
        uint _minimumDeadline,
        uint _divideShare
    ) public payable {
        id += 1;
        if (pauseAddresses[address(this)]==1) {revert PLATFORM_TEMPORARILY_PAUSED();}
        if (msg.sender == _proposed) {revert YOU_CANNOT_PROPOSE_YOURSELF(msg.sender);}
        if (isMember(_proposed) != 0){revert USER_ALREADY_EXISTS_IN_CM(_proposed);}
        if (isMember(msg.sender) != 0){revert USER_ALREADY_EXISTS_IN_CM(msg.sender);}
        if (_divideShare > 10) {revert INALID_SHARE_PROPORTION (_divideShare);}

        proposers[msg.sender] = id;
        proposedto[_proposed] = id;
    

        hasensName[msg.sender] = _hasensWaver;
        messages[msg.sender] = _message;

        WaverFactoryC factory = WaverFactoryC(waverFactoryAddress);

        address _newMarriageAddress;

        /*Creating proxy contract here */
        _newMarriageAddress = factory.newMarriage(
            address(this),
            id,
            msg.sender,
            _proposed,
            _policyDays,
            cmFee,
            _minimumDeadline,
            _divideShare
        );

    
        nftSplitC nftsplit = nftSplitC(addressNFTSplit);
        nftsplit.addAddresses(_newMarriageAddress);

        authrizedAddresses[_newMarriageAddress] = 1;

        proposalAttributes[id] = Wave({
            id: id,
            stake: msg.value,
            proposer: msg.sender,
            proposed: _proposed,
            ProposalStatus: Status.Proposed,
            marriageContract: _newMarriageAddress
        });

        processtxn(payable(_newMarriageAddress), msg.value);

        emit NewWave(id, msg.sender,_newMarriageAddress, Status.Proposed);
    }


    error PROPOSAL_STATUS_CHANGED();
    /**
     * @notice Response is given from the proposed Address.
     * @dev Updates are made to the proxy contract with respective response. ENS preferences will be checked onchain.
     * @param _agreed Response sent as uint. 1 - Agreed, anything else will trigger Declined status.
     * @param _hasensProposed preference whether Proposed wants to display ENS on the NFT certificate
     */

    function response(
        uint8 _agreed,
        uint8 _hasensProposed
    ) public {
        address msgSender_ = _msgSender();
        uint256 _id = proposedto[msgSender_];

        Wave storage waver = proposalAttributes[_id];
        if (waver.ProposalStatus != Status.Proposed) {revert PROPOSAL_STATUS_CHANGED();}
      
        waverImplementation1 waverImplementation = waverImplementation1(
            waver.marriageContract
        );

        if (_agreed == 1) {
            waver.ProposalStatus = Status.Processed;
            hasensName[msgSender_] = _hasensProposed;
            waverImplementation.agreed();
        } else {
            waver.ProposalStatus = Status.Declined;
            proposedto[msgSender_] = 0;
            waverImplementation.declined();
        }
        emit NewWave(_id, msgSender_, waver.marriageContract, waver.ProposalStatus);
    }

    /**
     * @notice Updates statuses from the main contract on the marriage status
     * @dev Helper function that is triggered from the proxy contract. Requirements are checked within the proxy.
     * @param _id The id of the partnership recorded within the main contract.
     */

    function cancel(uint256 _id) external onlyContract {
        Wave storage waver = proposalAttributes[_id];
        waver.ProposalStatus = Status.Cancelled;
        proposers[waver.proposer] = 0;
        proposedto[waver.proposed] = 0;
    emit NewWave(_id, tx.origin, msg.sender, Status.Cancelled);
    }

    error FAMILY_ACCOUNT_NOT_ESTABLISHED();
    error CLAIM_TIMOUT_NOT_PASSED();
    /**
     * @notice Users claim LOVE tokens depending on the proxy contract's balance and the number of family members.
     * @dev LOVE tokens are distributed once within policyDays defined by the owner.
     */

    function claimToken() external {
        (address msgSender_, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
        if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}

        if (claimtimer[msgSender_] + claimPolicyDays > block.timestamp) {revert CLAIM_TIMOUT_NOT_PASSED();}
        
          waverImplementation1 waverImplementation = waverImplementation1(
            waver.marriageContract
        );
        claimtimer[msgSender_] = block.timestamp;
        uint amount;
        uint fee = waverImplementation.getCMfee();
        if ( fee == 0) { amount = 5*1e18; } 
        else if (fee < 50 && fee>0) { 
            amount = (waver.marriageContract.balance * exchangeRate) / (20 * waverImplementation.getFamilyMembersNumber());
        } else if (fee>50) { amount = (waver.marriageContract.balance * exchangeRate) / (10 * waverImplementation.getFamilyMembersNumber());} 
        _mint(msgSender_, amount);
    }

    /**
     * @notice Users can buy LOVE tokens depending on the exchange rate. There is a cap for the Sales of the tokens.
     * @dev Only registered users within the proxy contracts can buy LOVE tokens. Sales Cap is universal for all users.
     */

    function buyLovToken() external payable {
        (address msgSender_, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
       if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        uint256 issued = msg.value * exchangeRate;
        saleCap -= issued;
        _mint(msgSender_, issued);
    }

    error PAYMENT_NOT_SUFFICIENT(uint requiredPayment);
    /**
     * @notice Users can mint tiered NFT certificates. 
     * @dev The tier of the NFT is identified by the passed params. The cost of mint depends on minPricePolicy. 
     depending on msg.value user also automatically mints LOVE tokens depending on the Exchange rate. 
     * @param logoID the ID of logo to be minted.
     * @param BackgroundID the ID of Background to be minted.
     * @param MainID the ID of other details to be minted.   
     */

    function MintCertificate(
        uint256 logoID,
        uint256 BackgroundID,
        uint256 MainID
    ) external payable {
        //getting price and NFT address
        if (msg.value < minPricePolicy) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy);}

        (, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
      if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        uint256 issued = msg.value * exchangeRate;

        saleCap -= issued;
       
        NFTContract NFTmint = NFTContract(addressNFT);

        if (BackgroundID >= 1000) {
            if (msg.value < minPricePolicy * 100) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy * 100);}
        } else if (logoID >= 100) {
            if (msg.value < minPricePolicy * 10) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy * 10);}
        }

        NFTmint.mintCertificate(
            waver.proposer,
            hasensName[waver.proposer],
            waver.proposed,
            hasensName[waver.proposed],
            waver.marriageContract,
            waver.id,
            logoID,
            BackgroundID,
            MainID
        );

        _mint(waver.proposer, issued / 2);
        _mint(waver.proposed, issued / 2);
    }

    /* Adding Family Members*/

    error MEMBER_NOT_INVITED(address member);
    /**
     * @notice When an Address has been added to a Proxy contract as a family member, 
     the owner of the Address have to accept the invitation.  
     * @dev The system checks whether the msg.sender has an invitation, if it is i.e. id>0, it adds the member to 
     corresponding marriage id. It also makes pertinent adjustments to the proxy contract. 
     * @param _response Bool response of the owner of Address.    
     */

    function joinFamily(uint8 _response) external {
        address msgSender_ = _msgSender();
        if (member[msgSender_][0] == 0) {revert MEMBER_NOT_INVITED(msgSender_);}
        uint256 _id = member[msgSender_][0];
        Wave storage waver = proposalAttributes[_id];
        Status status;

        if (_response == 2) {
            member[msgSender_][1] = _id;
            member[msgSender_][0] = 0;
            
            waverImplementation1 waverImplementation = waverImplementation1(
                waver.marriageContract
            );
            waverImplementation._addFamilyMember(msgSender_);
            status = Status.InvitationAccepted;
        } else {
            member[msgSender_][0] = 0;
            status = Status.InvitationDeclined;
        }

      emit NewWave(_id, msgSender_, waver.marriageContract, status);
    }

    
    /**
     * @notice A proxy contract adds a family member through this method. A family member is first invited,
     and added only if the indicated Address accepts the invitation.   
     * @dev invited user preliminary received marriage _id and is added to a list of family Members of the contract.
     Only marriage partners can add a family member. 
     * @param _familyMember Address of a member being invited.    
     * @param _id ID of the marriage.
     */

    function addFamilyMember(address _familyMember, uint256 _id)
        external
        onlyContract
    {
        if (isMember(_familyMember) != 0) {revert USER_ALREADY_EXISTS_IN_CM(_familyMember);}
        member[_familyMember][0] = _id;
        familyMembers[msg.sender].push(_familyMember);
        emit NewWave(_id, _familyMember,msg.sender,Status.MemberInvited);
    }
  
    /**
     * @notice A family member can be deleted through a proxy contract. A family member can be deleted at any stage.
     * @dev the list of a family members per a proxy contract is not updated to keep history of members. Deleted 
     members can be added back. 
     * @param _familyMember Address of a member being deleted.    
     */

    function deleteFamilyMember(address _familyMember, uint id_) external onlyContract {
        if (member[_familyMember][1] > 0) {
            member[_familyMember][1] = 0;
        } else {
            if (member[_familyMember][0] == 0) {revert MEMBER_NOT_INVITED(_familyMember);}
            member[_familyMember][0] = 0;
        }
    emit NewWave(id_, _familyMember, msg.sender, Status.MemberDeleted);
    }

      /**
     * @notice A function to add string name for an Address 
     * @dev Names are used for better UI/UX. 
     * @param _name String name
     */

    function addName(string memory _name) external {
        nameAddress[msg.sender] = _name;
    }

      /**
     * @notice A function to add contact for notifications 
     * @dev It is planned to send notifications using webhooks
     * @param _contact String name
     */

    function addContact(string memory _contact) external {
        contactDetails[msg.sender] = _contact;
    }

    /**
     * @notice A view function to get the list of family members per a Proxy Contract.
     * @dev the list is capped by a proxy contract to avoid unlimited lists.
     * @param _instance Address of a Proxy Contract.
     */

    function getFamilyMembers(address _instance)
        external
        view
        returns (address[] memory)
    {
        return familyMembers[_instance];
    }

    /**
     * @notice If a Dissalution is initiated and accepted, this method updates the status of the partnership as Divorced.
     It also updates the last NFT Certificates Status.  
     * @dev this method is triggered once settlement has happened within the proxy contract. 
     * @param _id ID of the marriage.   
     */

    function divorceUpdate(uint256 _id) external onlyContract {
        Wave storage waver = proposalAttributes[_id];
      if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        waver.ProposalStatus = Status.Divorced;
        NFTContract NFTmint = NFTContract(addressNFT);

        if (NFTmint.nftHolder(waver.marriageContract)>0) {
            NFTmint.changeStatus(waver.marriageContract, false);
        }
    emit NewWave(_id, msg.sender, msg.sender, Status.Divorced);
    }

    error COULD_NOT_PROCESS(address _to, uint amount);

    /**
     * @notice Internal function to process payments.
     * @dev call method is used to keep process gas limit higher than 2300.
     * @param _to Address that will be reveiving payment
     * @param _amount the amount of payment
     */

    function processtxn(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {revert COULD_NOT_PROCESS(_to,_amount);}
    }

    /**
     * @notice internal view function to check whether msg.sender has marriage ID.
     * @dev for a family member that was invited, temporary id is given.
     */

    function isMember(address _partner) public view returns (uint256 _id) {
        if (proposers[_partner] > 0) {
            return proposers[_partner];
        } else if (proposedto[_partner] > 0) {
            return proposedto[_partner];
        } else if (member[_partner][1] > 0) {
            return member[_partner][1];
        } else if (member[_partner][0] > 0) {
            return 1e9;
        }
    }

    function checkAuth()
        internal
        view
        returns (address __msgSender, uint256 _id)
    {
        address msgSender_ = _msgSender();
        uint256 uid = isMember(msgSender_);
        return (msgSender_, uid);
    }

    /**
     * @notice  public view function to check whether msg.sender has marriage struct Wave with proxy contract..
     * @dev if msg.sender is a family member that was invited, temporary id is sent. If id>0 not found, empty struct is sent.
     */
  

    function checkMarriageStatus() external view returns (Wave memory) {
        // Get the tokenId of the user's character NFT
        (address msgSender_, uint256 _id) = checkAuth();
        // If the user has a tokenId in the map, return their character.
        if (_id > 0 && _id < 1e9) {
            return proposalAttributes[_id];
        }
        if (_id == 1e9) {
            uint __id = member[msgSender_][0]; 
             Wave memory waver = proposalAttributes[__id];
            return
                Wave({
                    id: _id,
                    stake: waver.stake,
                    proposer: waver.proposer,
                    proposed: waver.proposed,
                    ProposalStatus: Status.WaitingConfirmation,
                    marriageContract: waver.marriageContract
                });
        }

        Wave memory emptyStruct;
        return emptyStruct;
    }

    /**
     * @notice Proxy contract can burn LOVE tokens as they are being used.
     * @dev only Proxy contracts can call this method/
     * @param _to Address whose LOVE tokens are to be burned.
     * @param _amount the amount of LOVE tokens to be burned.
     */

    function burn(address _to, uint256 _amount) external onlyContract {
        _burn(_to, _amount);
    }

    /* Parameters that are adjusted by the contract owner*/

    /**
     * @notice Tuning policies related to CM functioning
     * @param _claimPolicyDays The number of days required before claiming next LOVE tokens
     * @param _minPricePolicy Minimum price of minting NFT certificate of family account
     */

    function changePolicy(uint256 _claimPolicyDays, uint256 _minPricePolicy) external onlyOwner {
        claimPolicyDays = _claimPolicyDays;
        minPricePolicy = _minPricePolicy;
    }


    /**
     * @notice Changing Policies in terms of Sale Cap, Fees and the Exchange Rate
     * @param _saleCap uint is set in Wei.
     * @param _exchangeRate uint is set how much Love Tokens can be bought for 1 Ether.
     */

    function changeTokenPolicy(uint256 _saleCap, uint256 _exchangeRate, uint256 _promoDays) external onlyOwner {
        saleCap = _saleCap;
        exchangeRate = _exchangeRate;
        promoDays = _promoDays;
    }

    /**
     * @notice A fee that is paid by users for incoming and outgoing transactions.
     * @param _cmFee uint is set in Wei.*/
     
    function changeFee(uint256 _cmFee) external onlyOwner {
       cmFee = _cmFee;
    }

    /**
     * @notice A reference contract address of NFT Certificates factory and NFT split.
     * @param _addressNFT an Address of the NFT Factort.
     * @param _addressNFTSplit an Address of the NFT Split. 
     */

    function changeaddressNFT(address _addressNFT, address _addressNFTSplit ) external onlyOwner {
        addressNFT = _addressNFT;
        addressNFTSplit = _addressNFTSplit;
    }

    /**
     * @notice Changing contract addresses of Factory and Forwarder
     * @param _addressFactory an Address of the New Factory.
     */

    function changeSystemAddresses(address _addressFactory, address _withdrawaddress)
        external
        onlyOwner
    {
        waverFactoryAddress = _addressFactory;
        withdrawaddress = _withdrawaddress;
    }

 
   /**
     * @notice A functionality for "Social Changing" of a partner address. 
     * @dev can be called only by the Partnership contract 
     * @param _partner an Address to be changed.
     * @param _newAddress an address to be changed to.
     * @param id_ Address of the partnership.
     */

    function changePartnerAddress(address _partner, address _newAddress, uint id_) 
        external
    {
         Wave storage waver = proposalAttributes[id_];
         if (msg.sender != waver.marriageContract) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
         if (proposers[_partner] > 0) {
            proposers[_partner] = 0;
            proposers[_newAddress] = id_;
            waver.proposer =  _newAddress;
        } else if (proposedto[_partner] > 0) {
            proposedto[_partner] = 0;
            proposedto[_newAddress] = id_; 
            waver.proposed = _newAddress;
        } 
    emit NewWave(id_, _newAddress, msg.sender, Status.PartnerAddressChanged);
    }

    /**
     * @notice A function that resets indexes of users 
     * @dev A user will not be able to access proxy contracts if triggered from the CM FrontEnd
     */

    function forgetMe() external {
        proposers[msg.sender] = 0;
        proposedto[msg.sender] = 0;
        member[msg.sender][1] = 0;
    }
    error ACCOUNT_PAUSED(address sender);
    /**
     * @notice A method to withdraw comission that is accumulated within the main contract. 
     Withdraws the whole balance.
     */

    function withdrawcomission() external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        processtxn(payable(withdrawaddress), address(this).balance);
    }

    /**
     * @notice A method to withdraw comission that is accumulated within ERC20 contracts.  
     Withdraws the whole balance.
     * @param _tokenID the address of the ERC20 contract.
     */
    function withdrawERC20(address _tokenID) external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        uint256 amount;
        amount = IERC20(_tokenID).balanceOf(address(this));
        bool success =  IERC20(_tokenID).transfer(withdrawaddress, amount);
        if (!success) {revert COULD_NOT_PROCESS(withdrawaddress,amount);}
    }

    /**
     * @notice A method to pause withdrawals from the this and proxy contracts if threat is detected.
     * @param pauseData an List of addresses to be paused/unpaused
     */
    function pause(Pause[] calldata pauseData) external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        for (uint i; i<pauseData.length; i++) {
            pauseAddresses[pauseData[i].ContractAddress] = pauseData[i].Status;
        }   
    }

     /**
     * @notice A method to mint LOVE tokens who participated in Reward Program
     * @param mintData an List of addresses to be rewarded
     */
    function reward(Pause[] calldata mintData) external onlyOwner{
        for (uint i; i<mintData.length; i++) {
            rewardAddresses[mintData[i].ContractAddress] = mintData[i].Status;
        }   
    }
    error REWARD_NOT_FOUND(address claimer);
    function claimReward() external {
        if (rewardAddresses[msg.sender] == 0) {revert REWARD_NOT_FOUND(msg.sender);}
        uint amount = rewardAddresses[msg.sender];
        rewardAddresses[msg.sender] = 0;
        _mint(msg.sender, amount);
        saleCap-= amount;
    }

  /**
     * @notice A view function to monitor balance
     */

    function balance() external view returns (uint ETHBalance) {
       return address(this).balance;
    }

    receive() external payable {
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        require(msg.value > 0);
    }
}