//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

/**
    Dappd Subscription Service Smart Contract
    Learn More At dappd.net/hosting
 */
contract DappdSubscriptionService is Ownable {

    /** Constants */
    uint256 public constant month = 864000;

    /** Token To Accept As Payment */
    address public payToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    /** Payment Recipient */
    address public paymentRecipient = 0x06fe7eB32a532Bce5a8e63f21DD597927E923B0e;

    /** Client Structure */
    struct Client {
        string identifier;
        uint256 amountPaid;
        uint256 amountPerBlock;
        uint256 lastPaid;
        uint256 tolerance;
    }

    /** Client ID => Project */
    mapping ( uint32 => Client ) public clients;

    /** Identifier => Client ID */
    mapping ( string => uint32 ) public getClientID;

    /** Client ID => List Of Domains */
    mapping ( uint32 => string[] ) private getDomains;

    /** Client ID Nonce */
    uint32 public nonce;


    ////////////////////////////////////
    /////     OWNER FUNCTIONS     //////
    ////////////////////////////////////

    function setPayRecipient(address newRecipient) external onlyOwner {
        require(
            newRecipient != address(0),
            'Zero Address'
        );
        paymentRecipient = newRecipient;
    }

    function setPayToken(address newToken) external onlyOwner {
        payToken = newToken;
    }

    function resetLastPaidTime(uint32 id, uint256 decrement) external onlyOwner {
        clients[id].lastPaid = block.number - decrement;
    }

    function addProject(string calldata identifier_, uint256 amountMonthly, uint256 tolerance_) external onlyOwner {
        require(
            !identifierInUse(identifier_),
            'Identifier Already Exists'
        );

        clients[nonce].amountPerBlock = amountMonthly / month;
        clients[nonce].lastPaid = block.number;
        clients[nonce].identifier = identifier_;
        clients[nonce].tolerance = tolerance_;
        getClientID[identifier_] = nonce;
        nonce++;
    }

    function setAmountPerMonth(uint32 id, uint256 amountPerMonth_) external onlyOwner {
        clients[id].amountPerBlock = amountPerMonth_ / month;
    }

    function setIdentifier(uint32 id, string calldata identifier_) external onlyOwner {
        require(
            !identifierInUse(identifier_),
            'Identifier Already Exists'
        );
        delete getClientID[clients[id].identifier];
        getClientID[identifier_] = id;
        clients[id].identifier = identifier_;
    }

    function setTolerance(uint32 id, uint256 tolerance_) external onlyOwner {
        clients[id].tolerance = tolerance_;
    }
    
    function addDomains(uint32 id, string[] calldata domains) external onlyOwner {
        for (uint i = 0; i < domains.length; i++) {
            getDomains[id].push(domains[i]);
        }
    }

    function removeDomain(uint32 id, string calldata domain) external onlyOwner {
        uint len = getDomains[id].length;
        uint index = len;
        for (uint i = 0; i < len; i++) {
            if (keccak256(abi.encodePacked(getDomains[id][i])) == keccak256(abi.encodePacked(domain))) {
                index = i;
                break;
            }
        }
        require(
            index < len,
            'Domain not found'
        );
        getDomains[id][index] = getDomains[id][len - 1];
        getDomains[id].pop();
    }


    ////////////////////////////////////
    /////     PUBLIC FUNCTIONS    //////
    ////////////////////////////////////


    function payBill(uint32 id, uint256 additional) external {
        uint owed = amountOwed(id);
        uint amountToTransfer = additional + owed;

        require(
            IERC20(payToken).allowance(msg.sender, address(this)) >= amountToTransfer,
            'Insufficient Allowance'
        );
        require(
            IERC20(payToken).transferFrom(
                msg.sender,
                paymentRecipient,
                amountToTransfer
            ),
            'Failure Transfer From'
        );

        unchecked {
            clients[id].amountPaid += amountToTransfer;
        }

        uint additionalBlocks = ( additional / clients[id].amountPerBlock );
        clients[id].lastPaid = owed == 0 ? clients[id].lastPaid + additionalBlocks : block.number + additionalBlocks;
    }


    ////////////////////////////////////
    /////      READ FUNCTIONS     //////
    ////////////////////////////////////


    function identifierInUse(string calldata identifier_) public view returns (bool) {
        uint32 id = getClientID[identifier_];
        return keccak256(abi.encodePacked(clients[id].identifier)) == keccak256(abi.encodePacked(identifier_));
    }

    function getDomainsForID(uint32 id) public view returns (string[] memory) {
        return getDomains[id];
    }

    function getDomainsForIdentifier(string calldata identifier_) public view returns (string[] memory) {
        return getDomainsForID(getClientID[identifier_]);
    }

    function fetchProjectDetails(uint32 id) public view returns (
        string memory identifier,
        uint256 amountPaid,
        uint256 amountPerBlock,
        uint256 lastPaid,
        uint256 tolerance,
        uint256 amountOwed_
    ) {
        identifier = clients[id].identifier;
        amountPaid = clients[id].amountPaid;
        amountPerBlock = clients[id].amountPerBlock;
        lastPaid = clients[id].lastPaid;
        tolerance = clients[id].tolerance;
        amountOwed_ = amountOwed(id);
    }

    function fetchProjectDetails(string calldata identifier_) public view returns (
        string memory identifier,
        uint256 amountPaid,
        uint256 amountPerBlock,
        uint256 lastPaid,
        uint256 tolerance,
        uint256 amountOwed_
    ) {
        return fetchProjectDetails(getClientID[identifier_]);
    }

    function fetchAllDetails() external view returns (
        string[] memory identifier,
        uint256[] memory amountPaid,
        uint256[] memory amountPerBlock,
        uint256[] memory lastPaid,
        uint256[] memory tolerance,
        uint256[] memory amountOwed_
    ) {
        
        identifier = new string[](nonce);
        amountPaid = new uint256[](nonce);
        amountPerBlock = new uint256[](nonce);
        lastPaid = new uint256[](nonce);
        tolerance = new uint256[](nonce);
        amountOwed_ = new uint256[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            identifier[i] = clients[i].identifier;
            amountPaid[i] = clients[i].amountPaid;
            amountPerBlock[i] = clients[i].amountPerBlock;
            lastPaid[i] = clients[i].lastPaid;
            tolerance[i] = clients[i].tolerance;
            amountOwed_[i] = amountOwed(i);
        }
    }

    function totalPaid() external view returns (uint256 total) {
        for (uint32 i = 0; i < nonce; i++) {
            total += clients[i].amountPaid;
        }
    }

    function totalOwed() external view returns (uint256 total) {
        for (uint32 i = 0; i < nonce; i++) {
            total += amountOwed(i);
        }
    }

    function fetchAllOwed() external view returns (uint256[] memory) {
        uint256[] memory allOwed = new uint256[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            allOwed[i] = amountOwed(i);
        }
        return allOwed;
    }

    function fetchAllOwedAndTolerance() external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory allOwed = new uint256[](nonce);
        uint256[] memory allTolerances = new uint256[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            allOwed[i] = amountOwed(i);
            allTolerances[i] = clients[i].tolerance;
        }
        return (allOwed, allTolerances);
    }

    function fetchAllOwedAndToleranceAndTimePassed() external view returns (uint256[] memory, uint256[] memory, int256[] memory) {
        uint256[] memory allOwed = new uint256[](nonce);
        uint256[] memory allTolerances = new uint256[](nonce);
        int256[] memory timesPassed = new int256[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            allOwed[i] = amountOwed(i);
            allTolerances[i] = clients[i].tolerance;
            timesPassed[i] = timePassed(i);
        }
        return (allOwed, allTolerances, timesPassed);
    }

    function fetchAllShouldDisplaySites() external view returns (bool[] memory) {
        bool[] memory shouldDisplay = new bool[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            shouldDisplay[i] = shouldDisplaySite(i);
        }
        return shouldDisplay;
    }

    function fetchAllShouldDisplaySitesAndProjectIdentifiers() external view returns (bool[] memory, string[] memory) {
        bool[] memory shouldDisplay = new bool[](nonce);
        string[] memory identifiers = new string[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            shouldDisplay[i] = shouldDisplaySite(i);
            identifiers[i] = clients[i].identifier;
        }
        return (shouldDisplay, identifiers);
    }

    function amountOwed(uint32 id) public view returns (uint256) {

        uint last = clients[id].lastPaid;
        uint cost = clients[id].amountPerBlock;
        if (last == 0 || cost == 0) {
            return 0;
        }

        uint tPassed = last < block.number ? block.number - last : 0;
        return tPassed * cost;
    }

    function timePassed(uint32 id) public view returns (int256 tPassed) {
        uint last = clients[id].lastPaid;
        unchecked {
            tPassed = int256(block.number) - int256(last);
        }
    }

    function fetchTimePassed() external view returns (int256[] memory) {
        int256[] memory timesPassed = new int256[](nonce);
        for (uint32 i = 0; i < nonce; i++) {
            timesPassed[i] = timePassed(i);
        }
        return timesPassed;
    }

    function blocksAheadOnPayment(uint32 id) public view returns (uint256) {
        return clients[id].lastPaid > block.number ? clients[id].lastPaid - block.number : 0;
    }

    function blocksBehindOnPayment(uint32 id) public view returns (uint256) {
        return clients[id].lastPaid < block.number ? block.number - clients[id].lastPaid : 0;
    }

    function shouldDisplaySite(uint32 id) public view returns (bool) {
        if (id >= nonce || clients[id].tolerance == 0) {
            return true;
        }
        return clients[id].tolerance >= amountOwed(id);
    }

}