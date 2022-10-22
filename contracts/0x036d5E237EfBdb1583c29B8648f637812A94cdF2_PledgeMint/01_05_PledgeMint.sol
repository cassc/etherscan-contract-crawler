/// @notice Pledge Mint v1.2 contract by Culture Cubs
// pledgemint.io
//
// For your ERC721 contract to be compatible, follow the following instructions:
// - declare a variable for the pledgemint contract address:
//   address public pledgeContractAddress;
// - add the following function to allow Pledge Mint to mint NFT for your pledgers:
//   function pledgeMint(address to, uint8 quantity) override
//       external
//       payable {
//       require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
//       require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
//       _mint(to, quantity);
//   }
//
//    * Please ensure you test this method before deploying your contract.
//    * PledgeMint will send the funds collected along with the mint call, minus the fee agreed upon.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/Errors.sol";

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity) external payable;
}

contract PledgeMint is Ownable, ReentrancyGuard {
    // Phases allow to have different cohorts of pledgers, with different contracts, prices and limits.
    struct PhaseConfig {
        address admin;
        IERC721Pledge mintContract;
        uint256 mintPrice;
        uint8 maxPerWallet;
        // When locked, the contract on which the mint happens cannot ever be changed again
        bool mintContractLocked;
        // Can only be set to true if mint contract is locked, which is irreversible.
        // Owner of the contract can still trigger refunds - but not access anyone's funds.
        bool pledgesLocked;
        uint16 fee; // int representing the percentage with 2 digits. e.g. 1.75% -> 175
        uint16 cap; // max number of NFTs to sell during this phase
        uint256 startTime;
        uint256 endTime;
    }

    // Mapping from phase Id to array of pledgers
    mapping(uint16 => address[]) public pledgers;
    // Mapping from phase Id to mapping from address to boolean allow value
    mapping(uint16 => mapping(address => bool)) public allowlists;
    // Mapping from phase Id to mapping from address to pladge number
    mapping(uint16 => mapping(address => uint8)) public pledges;

    uint256 public pledgeMintRevenue;

    PhaseConfig[] public phases;

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert Errors.CallerIsContract();
        _;
    }

    modifier onlyAdminOrOwner(uint16 phaseId) {
        if (owner() != _msgSender() && phases[phaseId].admin != _msgSender())
            revert Errors.CallerIsNotOwner();
        _;
    }

    constructor() {}

    function addPhase(
        address admin,
        IERC721Pledge mintContract,
        uint256 mintPrice,
        uint8 maxPerWallet,
        uint16 fee,
        uint16 cap,
        uint startTime,
        uint endTime
    ) external onlyOwner {
        phases.push(
            PhaseConfig(
                admin,
                mintContract,
                mintPrice,
                maxPerWallet,
                false,
                false,
                fee,
                cap,
                startTime,
                endTime
            )
        );
    }

    function allowAddresses(uint16 phaseId, address[] calldata allowlist_)
        external
        onlyAdminOrOwner(phaseId)
    {
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        for (uint256 i; i < allowlist_.length; ) {
            _allowlist[allowlist_[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    function pledgeWithCap(uint16 phaseId, uint8 number)
        external
        payable
        callerIsUser
    {
        PhaseConfig memory phase = phases[phaseId];
        if (block.timestamp < phase.startTime || phase.endTime > 0 && block.timestamp > phase.endTime) revert Errors.PhaseNotActive();
        (uint256 nbPledged, ) = _nbNFTsPledge(phaseId);
        if (phase.cap > 0 && nbPledged + number > phase.cap) revert Errors.OverPhaseCap();
        if (number > phase.maxPerWallet) revert Errors.NFTAmountNotAllowed();
        if (number < 1) revert Errors.AmountNeedsToBeGreaterThanZero();
        if (msg.value != phase.mintPrice * number)
            revert Errors.AmountMismatch();
        if (pledges[phaseId][msg.sender] != 0) revert Errors.AlreadyPledged();
        pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
    }

    function pledge(uint16 phaseId, uint8 number)
        external
        payable
        callerIsUser
    {
        PhaseConfig memory phase = phases[phaseId];
        if (block.timestamp < phase.startTime || phase.endTime > 0 && block.timestamp > phase.endTime) revert Errors.PhaseNotActive();
        if (number > phase.maxPerWallet) revert Errors.NFTAmountNotAllowed();
        if (number < 1) revert Errors.AmountNeedsToBeGreaterThanZero();
        if (msg.value != phase.mintPrice * number)
            revert Errors.AmountMismatch();
        if (pledges[phaseId][msg.sender] != 0) revert Errors.AlreadyPledged();
        pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
    }

    function unpledge(uint16 phaseId) external nonReentrant callerIsUser {
        if (phases[phaseId].pledgesLocked == true)
            revert Errors.PledgesAreLocked();

        uint256 nbPledged = pledges[phaseId][msg.sender];
        if (nbPledged < 1) revert Errors.NothingWasPledged();
        pledges[phaseId][msg.sender] = 0;

        (bool success, ) = msg.sender.call{
            value: phases[phaseId].mintPrice * nbPledged
        }("");

        if (!success) revert Errors.UnableToSendValue();
    }

    function lockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        if (phases[phaseId].mintContractLocked == false)
            revert Errors.CannotLockPledgeWithoutLockingMint();
        phases[phaseId].pledgesLocked = true;
    }

    function unlockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        phases[phaseId].pledgesLocked = false;
    }

    // mint for all participants
    function mintPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, 0, _addresses.length, false);
    }

    // mint for all participants
    function mintAllPledgesInPhase(uint16 phaseId)
        external
        onlyAdminOrOwner(phaseId)
    {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, 0, _addresses.length, true);
    }

    // mint for all participants, paginated
    function mintPhase(
        uint16 phaseId,
        uint256 startIdx,
        uint256 length
    ) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, startIdx, length, false);
    }

    // mint for select participants
    // internal function checks eligibility and pledged number.
    function mintPhase(uint16 phaseId, address[] calldata selectPledgers)
        external
        onlyAdminOrOwner(phaseId)
    {
        _mintPhase(phaseId, selectPledgers, 0, selectPledgers.length, false);
    }

    function _mintPhase(
        uint16 phaseId,
        address[] memory addresses,
        uint256 startIdx,
        uint256 count,
        bool allowAllMints
    ) internal {
        PhaseConfig memory _phase = phases[phaseId];
        if (_phase.mintContractLocked == false)
            revert Errors.CannotLaunchMintWithoutLockingContract();
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        uint256 phaseRevenue;
        for (uint256 i = startIdx; i < count; ) {
            address addy = addresses[i];
            uint8 quantity = _pledges[addy];

            // Any address not allowed will have to withdraw their pledge manually. We skip them here.
            if ((allowAllMints || _allowlist[addy]) && quantity > 0) {
                _pledges[addy] = 0;
                uint256 totalCost = _phase.mintPrice * quantity;
                uint256 pmRevenue = (totalCost * _phase.fee) / 10000;
                phaseRevenue += pmRevenue;
                _phase.mintContract.pledgeMint{value: totalCost - pmRevenue}(
                    addy,
                    quantity
                );
            }

            unchecked {
                ++i;
            }
        }
        pledgeMintRevenue += phaseRevenue;
    }

    // These stats may decrease in case of refund or mint. They are not itended to archive states.
    function currentPhaseStats(uint16 phaseId)
        public
        view
        returns (
            uint256 nbPledges,
            uint256 nbNFTsPledged,
            uint256 amountPledged,
            uint256 nbAllowedPledges,
            uint256 nbNAllowedFTsPledged,
            uint256 allowedAmountPledged
        )
    {
        PhaseConfig memory _phase = phases[phaseId];
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        address[] storage _pledgers = pledgers[phaseId];
        for (uint256 i; i < _pledgers.length; ) {
            address addy = _pledgers[i];
            uint8 quantity = _pledges[addy];
            if (quantity > 0) {
                nbPledges += 1;
                nbNFTsPledged += quantity;
                amountPledged += quantity * _phase.mintPrice;
                if (_allowlist[addy]) {
                    nbAllowedPledges += 1;
                    nbNAllowedFTsPledged += quantity;
                    allowedAmountPledged += quantity * _phase.mintPrice;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function refundPhase(uint16 phaseId)
        external
        onlyAdminOrOwner(phaseId)
        nonReentrant
    {
        _refundPhase(phaseId);
    }

    function refundAll() external onlyOwner nonReentrant {
        for (uint8 i; i < phases.length; ) {
            _refundPhase(i);

            unchecked {
                ++i;
            }
        }
    }

    function refundPhasePledger(uint16 phaseId, address pledger)
        external
        onlyAdminOrOwner(phaseId)
        nonReentrant
    {
        uint256 amount = pledges[phaseId][pledger] * phases[phaseId].mintPrice;
        pledges[phaseId][pledger] = 0;
        (bool success, ) = pledger.call{value: amount}("");
        if (!success) revert Errors.UnableToSendValue();
    }

    function _refundPhase(uint16 phaseId) internal {
        PhaseConfig memory _phase = phases[phaseId];
        address[] storage _addresses = pledgers[phaseId];
        for (uint8 i; i < _addresses.length; ) {
            address addy = _addresses[i];
            uint8 quantity = pledges[phaseId][addy];
            if (quantity > 0) {
                pledges[phaseId][addy] = 0;
                (bool success, ) = addy.call{
                    value: _phase.mintPrice * quantity
                }("");
                if (!success) revert Errors.UnableToSendValue();
            }

            unchecked {
                ++i;
            }
        }
    }

    function _nbNFTsPledge(uint16 phaseId)
        internal
        view
        returns (
            uint256 nbNFTsPledged,
            uint256 nbNAllowedFTsPledged
        )
    {
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        address[] storage _pledgers = pledgers[phaseId];
        for (uint256 i; i < _pledgers.length; ) {
            address addy = _pledgers[i];
            uint8 quantity = _pledges[addy];
            if (quantity > 0) {
                nbNFTsPledged += quantity;
                if (_allowlist[addy]) {
                    nbNAllowedFTsPledged += quantity;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function emergencyRefund(
        uint16 phaseId,
        uint256 startIdx,
        uint256 count
    ) external onlyOwner {
        PhaseConfig memory _phase = phases[phaseId];
        for (uint256 i = startIdx; i < count; ) {
            address addy = pledgers[phaseId][i];
            uint8 quantity = pledges[phaseId][addy];

            (bool success, ) = addy.call{value: _phase.mintPrice * quantity}(
                ""
            );
            if (!success) revert Errors.UnableToSendValue();

            unchecked {
                ++i;
            }
        }
    }

    function setMintContract(uint16 phaseId, IERC721Pledge mintContract_)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].mintContract = mintContract_;
    }

    function setFee(uint16 phaseId, uint16 fee)
        external
        onlyOwner
    {
        phases[phaseId].fee = fee;
    }

    function setStartTime(uint16 phaseId, uint256 startTime)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].startTime = startTime;   
    }

    function setEndTime(uint16 phaseId, uint256 endTime)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].endTime = endTime;   
    }

    function setPrice(uint16 phaseId, uint256 price)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].mintPrice = price;   
    }

    function setCap(uint16 phaseId, uint16 cap)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].cap = cap;   
    }

    function setAdmin(uint16 phaseId, address admin)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].admin = admin;
    }

    function setMaxPerWallet(uint16 phaseId, uint8 maxPerWallet)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].maxPerWallet = maxPerWallet;   
    }

    function withdrawRevenue() 
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: pledgeMintRevenue}("");
        require(success, "Transfer failed.");
        pledgeMintRevenue = 0;
    }
}