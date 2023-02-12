// SPDX-License-Identifier: CC-BY-NC-ND-3.0-DE
//@author smashice.eth - https://dtech.vision - https://hupfmedia.de
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract sharedInvest is Ownable {
    /**
     * Event getting fired when a new request is created
     * @param id Request ID
     * @param creator Wallet that created the Request
     * @param timestamp Timestamp at which it was created
     */
    event RequestCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp
    );
    /**
     * Event getting fired when a request is supported
     * @param id Request ID
     * @param supporter Wallet that supported the request
     * @param amount The amount invested in the request
     * @param timestamp Timestamp at which it was supported
     */
    event RequestSupported(
        uint256 indexed id,
        address indexed supporter,
        uint256 indexed amount,
        uint256 timestamp
    );
    /**
     * Event getting fired when a request is finalized
     * @param id Request ID
     * @param success true if request raised successfully
     * @param amount The amount raised by the request
     * @param targetAmount The target amount by the request
     * @param timestamp Timestamp at which it was finalized
     */
    event RequestFinalized(
        uint256 indexed id,
        bool indexed success,
        uint256 indexed amount,
        uint256 targetAmount,
        uint256 timestamp
    );
    /**
     * Event getting fired when a request gets a payout without being sold (airdrop)
     * @param id Request ID
     * @param amount The amount airdropped/payed out to investors
     * @param description Description of the AirDrop
     * @param timestamp Timestamp of Airdrop
     */
    event RequestAirdrop(
        uint256 indexed id,
        uint256 indexed amount,
        string description,
        uint256 timestamp
    );
    /**
     * Event getting fired when a request is sold
     * @param id Request ID
     * @param amount The amount sold for
     * @param timestamp Timestamp of sale announcement
     */
    event RequestSold(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 timestamp
    );
    /**
     * Event getting fired when a request is payed out
     * @param id Request ID
     * @param timestamp Timestamp of sale announcement
     */
    event RequestPayedOut(
        uint256 indexed id,
        uint256 indexed timestamp
    );

    using ECDSA for bytes32; 
    //funding request - opportunity
    struct request {
        uint256 id;
        uint256 expiry;
        uint256 targetAmount;
        uint256 currentAmount;
        uint256 soldAmount;
        string title;
        string description;
        address targetCollection; //the smartcontract address of the investment target
        address[] participantWallets;
        uint256[] participantAmounts;
        uint256[] participantTimestamp;
        uint8 status; //0 = running, 1=refunded, 2=invested, 3=sold, 4=payed out
    }

    uint256 public nextId = 0;
    uint256 public activeRequests = 0;
    mapping (uint256 => request) public requests;
    mapping (address => int256) public totalPnL;
    mapping (address => int256) public totalInvested;

    address payable public trust;
    address public signerAddress;

    bool public pauseCreation = false;
    bool public pauseSupport  = false;
    bool public pauseFinalize = false;
    bool public pauseSold     = false;
    bool public pausePayout   = false;

    bool public payingOut     = false;

    constructor(
        address signer_,
        address payable trust_
    )
    {
        signerAddress = signer_;
        trust = trust_;
    }

    /**
     * Allows Owner to change Signer
     * @param signer_ the new signer address
     */
    function setSigner (
        address signer_
    ) public onlyOwner {
        signerAddress = signer_;
    }

    /**
     * Allows Owner to pause Request Creation
     */
    function flipPauseCreation()
    public onlyOwner {
        pauseCreation = !pauseCreation;
    }

    /**
     * Allows Owner to pause Request Support
     */
    function flipPauseSupport()
    public onlyOwner {
        pauseSupport = !pauseSupport;
    }

    /**
     * Allows Owner to pause Request Finalization
     */
    function flipPauseFinalize()
    public onlyOwner {
        pauseFinalize = !pauseFinalize;
    }

    /**
     * Allows Owner to pause Request marking as Sold
     */
    function flipPauseSold()
    public onlyOwner {
        pauseSold = !pauseSold;
    }

    /**
     * Allows Owner to pause Request Payout
     */
    function flipPausePayout()
    public onlyOwner {
        pausePayout = !pausePayout;
    }

    /**
     * Create an investment/funding request
     * @param title_ string: Title of the investment
     * @param description_ string: description of the investment
     * @param expiry_  uint256: timestamp of when the targetAmount is to be collected
     * @param targetAmount_ uint256: how much WEI to collect
     * @param targetCollection_ address: from which collection/contract to buy
     * @param signature_ bytes: verification that you are allowed to use the tool
     */
    function createRequest(
        string memory title_,
        string memory description_,
        uint256 expiry_,
        uint256 targetAmount_,
        address targetCollection_,
        bytes memory signature_
    ) public payable 
    {
        require(!pauseCreation, "702 Creation Paused");
        require(
          matchAddresSigner(hashTransaction(msg.sender, msg.value), signature_),
         "706 Signature doesn't match."
        );
        require(expiry_ > block.timestamp, "already expired");

        uint256 id = nextId++;

        request storage req = requests[id];
        req.id=id;
        req.status = 0;
        req.expiry = expiry_;
        req.targetAmount = targetAmount_;
        req.currentAmount += msg.value;
        req.title = title_;
        req.description = description_;
        req.targetCollection = targetCollection_;
        req.participantWallets = [msg.sender];
        req.participantAmounts = [msg.value];
        req.participantTimestamp = [block.timestamp];

        requests[id] = req; 
        activeRequests++;

        totalInvested[msg.sender] += (int)(msg.value);
        emit RequestCreated(id, msg.sender, block.timestamp);
    }
 
    /**
     * Support the Request by adding funds
     * @param id_ The request id to invest in/support
     * @param signature_ bytes: verification that you are allowed to use the tool
     */
    function supportRequest(
        uint256 id_,
        bytes memory signature_
    ) public payable 
    {
        require(!pauseSupport, "702 Supporting Paused");
        require(
          matchAddresSigner(hashTransaction(msg.sender, msg.value), signature_),
         "706 Signature doesn't match."
        );

        require(id_ < nextId, "704 Query for nonexistent id"); 
        request storage req = requests[id_];
        require (req.expiry > block.timestamp, "support too late, request expired");
        require (msg.value > 0, "need to send currency");
        require ((msg.value + req.currentAmount) <= req.targetAmount, "Invest would exceed target Amount");

        req.currentAmount += msg.value;
        req.participantAmounts.push(msg.value);
        req.participantWallets.push(msg.sender);
        req.participantTimestamp.push(block.timestamp);

        requests[id_] = req;
        totalInvested[msg.sender] += (int)(msg.value);
        emit RequestSupported(id_, msg.sender, msg.value, block.timestamp);
    }

    /**
     * Finalize the request by refunding or initiating invest
     * @param id_ The request id to finalize
     */
    function finalizeRequest(
        uint256 id_
    ) public 
    {
       require(!pauseFinalize, "702 Finalization Paused");
       require(id_ >= 0 && id_ < nextId,"704 Query for nonexistent id");
       request storage req = requests[id_]; 
       if(req.currentAmount >= req.targetAmount)
       {
          //successful
          require(req.status == 0, "Request already finalized");
          req.status = 2;
          requests[id_] = req; 
          require (!payingOut, "Please wait for current finalize to finish.");
          payingOut = true;
          (bool success, ) = trust.call{value: req.currentAmount}("");
          require(success, "Transfer failed!");
          payingOut = false;
          emit RequestFinalized(id_, true, req.currentAmount, req.targetAmount, block.timestamp);
       }
       else 
       {
          require (req.expiry < block.timestamp, "not ready");
          //not successful
          require(req.status == 0, "Request already finalized");
          req.status = 1;
          requests[id_] = req; 
          bool success = refundRequest(req.id);
          require(success);
          emit RequestFinalized(id_, false, req.currentAmount, req.targetAmount, block.timestamp);
       }
    }

    /**
     * Refund the request
     * @param id_ The request id to payout/refund
     */
    function refundRequest(
        uint256 id_
    ) private returns (bool)
    {
       require(id_ < nextId, "704 Query for nonexistent id"); 
       request storage req = requests[id_]; 
       for(uint256 i = 0; i < req.participantWallets.length; i++)
       {
          address payable wallet = payable(req.participantWallets[i]);
          uint256 amount = req.participantAmounts[i];
          if(amount > 0) //no transfer of negative or zero amounts
          {
            totalInvested[wallet] -= (int)(amount);
            require (!payingOut, "Please wait for current finalize to finish.");
            payingOut = true;
            (bool success, ) = wallet.call{value: amount}("");
            require(success, "Transfer failed!");
            payingOut = false;
          }
       }
       return true;
    }

    /**
     * Pays out successful investment
     * @param id_ The request id to payout
     */
    function payoutRequest(
        uint256 id_
    ) public returns (bool)
    {
       require(!pausePayout, "702 Payout Paused");
       require(id_ < nextId, "704 Query for nonexistent id"); 
       request storage req = requests[id_]; 
       require(req.status == 3, "Status not 3");
       req.status = 4;
       requests[id_] = req; 

       for(uint256 i = 0; i < req.participantWallets.length; ++i){
          address payable wallet = payable(req.participantWallets[i]);
          require(req.currentAmount > 0, "704 Nothing invested in request");
          uint256 amount = (req.participantAmounts[i] * req.soldAmount) / req.currentAmount;         
          if(amount > 0) //no transfer of negative or zero amounts
          {
            require (!payingOut, "Please wait for current payout to finish.");
            payingOut = true;
            (bool success, ) = wallet.call{value: amount}("");
            require(success, "Transfer failed!");
            payingOut = false;
          }
       }
       emit RequestPayedOut(id_, block.timestamp);
       return true;
    }

    /**
     * Let the trust mark the request as sold and indicate the amount
     * @param id_ The request id to mark as sold
     */
    function soldRequest(
        uint256 id_
    ) public payable 
    {
       require(!pauseSold, "702 Mark as Sold Paused");
       require(msg.sender == trust, "Only available from trust");
       require(0 <= id_ && id_ < nextId, "704 Query for nonexistent id"); 
       request storage req = requests[id_]; 
       require(req.status == 2, "Status not 2");
       require(req.currentAmount > 0, "704 Nothing invested in request");
       req.status = 3;
       req.soldAmount = msg.value;
       requests[id_] = req; 

       for(uint256 i = 0; i < req.participantWallets.length; ++i){
          address payable wallet = payable(req.participantWallets[i]);
          uint256 amount = (req.participantAmounts[i] * req.soldAmount) / req.currentAmount;         
          totalPnL[wallet] += (int)(amount) - (int)(req.participantAmounts[i]);
       }
       emit RequestSold(id_, msg.value, block.timestamp);
    }

    /**
     * Splits the sent either to investors of the request as "Airdrop"
     * @param id_ The request id to airdrop to
     * @param description Short description of the Airdrop
     */
    function payoutRequestAirdrop(
        uint256 id_,
        string memory description
    ) public payable returns (bool)
    {
       require(!pausePayout, "702 Payout Paused");
       require(id_ < nextId, "704 Query for nonexistent id"); 
       request storage req = requests[id_]; 
       uint256 value = msg.value;

       for(uint256 i = 0; i < req.participantWallets.length; ++i){
          address payable wallet = payable(req.participantWallets[i]);
          require(req.currentAmount > 0, "704 Nothing invested in request");
          uint256 amount = (req.participantAmounts[i] * value) / req.currentAmount;         
          if(amount > 0) //no transfer of negative or zero amounts
          {
            require (!payingOut, "Please wait for current payout to finish.");
            payingOut = true;
            (bool success, ) = wallet.call{value: amount}("");
            require(success, "Transfer failed!");
            payingOut = false;
            totalPnL[wallet] += (int)(amount);
          }
       }
       emit RequestAirdrop(id_, msg.value, description, block.timestamp);
       return true;
    }

    /**
     * Returns the request given by the specific id_
     * @param id_ uint256 id of the request
     */
    function getRequest(
        uint256 id_
    ) public view returns (request memory)
    {
        require(id_ < nextId, "704 Query for nonexistent id"); 
        return requests[id_];
    }

    /**
     * Returns all active requests (not sold or failed)
     */
    function getActiveRequests(
    ) public view returns (request[] memory)
    {
        request[] memory reqs = new request[](nextId); 
        for(uint256 i = 0; i < nextId; ++i)
        {
            if(reqs[i].status == 0 || reqs[i].status == 2)
            {
                reqs[i] = requests[i];
            }
        }
        return reqs;
    }

    /**
     * Returns all the Requests
     */
    function getAllRequests(
    ) public view returns (request[] memory)
    {
        request[] memory reqs = new request[](nextId); 
        for(uint256 i = 0; i < nextId; ++i)
        {
            reqs[i] = requests[i];
        }
        return reqs;
    }

    /**
     * Verify that address signing the hash with signature is indeed the signerAddress
     * @param hash The signed hash
     * @param signature The signature used to sign the hash
     */
    function matchAddresSigner(
        bytes32 hash,
        bytes memory signature
        ) private view returns(
            bool
        ) {
        return signerAddress == hash.recover(signature);
    }

    /**
     * Verify that the hash actually corresponds to the given public sale mint data
     * @param sender The address sending the transaction
     * @param amount the amount being sent (in WEI)
     */
    function hashTransaction(
        address sender,
        uint256 amount
        ) private pure returns(
            bytes32
        ) {
          return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, amount)))
          );
    }
}