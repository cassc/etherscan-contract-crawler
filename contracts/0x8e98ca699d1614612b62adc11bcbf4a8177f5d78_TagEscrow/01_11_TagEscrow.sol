//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ITagNFT.sol";

contract TagEscrow is
ReentrancyGuard,
Ownable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITagNFT public NFTContract;

    mapping(uint256 => EscrowVault) public escrows;
    mapping(uint256 => DepositAsset) public escrowAssetsA;
    mapping(uint256 => DepositAsset) public escrowAssetsB;
    mapping(address => IdContainer) private walletEscrows;

    EnumerableSet.UintSet private escrowIds;
    uint256 public nextEscrowId;

    address payable public tagFeeVault;

    uint256 public tagFeeBps;
    uint256 private maxFeeBps;

    string public version = "V3";

    /**
     * @dev The asset deposited for an escrow
     * @param currency The currency deposited
     * @param amount The amount of the asset
     */
    struct DepositAsset {
        IERC20 currency;
        uint256 amount;
    }

    struct IdContainer {
        uint256[] escrowIds;
    }

    /**
     * @dev When a case is created then the escrow is created. If the sender confirms or the handler
     * confirms then the escrow is released.
     * @param escrowId id of the escrow
     * @param partyA The address that will receive the money if the escrow is released
     * @param partyB The address of the person who sent the money
     * @param partyArbitrator The address of the person who is handling the case
     * @param closed Whether the escrow has been closed
     * @param description The text describing what the escrow is
     * @param determineTime The time the escrow can be judged. This is optional if set to 0.
     * @param pendingAssetB The assets to be deposited by partyB
     */
    struct EscrowVault {
        uint256 escrowId;
        address partyA;
        address partyB;
        uint256 nftA;
        uint256 nftB;
        address partyArbitrator;
        uint256 arbitratorFeeBps;
        string description;
        uint256 createTime;
        uint256 determineTime;
        bool started;
        bool closed;
        DepositAsset pendingAssetB;
        address winner;
    }

    // -- EVENTS
    event EscrowCreated(
        uint256 escrowId,
        address partyA,
        address partyB,
        address partyArbitrator,
        uint256 arbitratorFeeBps,
        string description,
        uint256 createTime,
        uint256 determineTime,
        bool started,
        bool closed,
        DepositAsset pendingAssetB
    );
    event EscrowCancelled(uint256 escrowId);
    event EscrowStarted(uint256 escrowId);
    event EscrowDetermined(uint256 escrowId, address winner);
    event FundsReclaimed(uint256 escrowId, address depositor);
    event FundsWithdrawn(uint256 escrowId, address withdrawer);
    event FundsDeposited(
        uint256 escrowId,
        address depositor,
        IERC20 currency,
        uint256 amount,
        uint256 partyANftId,
        uint256 partyBNftId
    );

    // -- MODIFIERS
    modifier onlyCaseArbitrator(uint256 escrowId) {
        require(
            escrows[escrowId].partyArbitrator == msg.sender,
            "Caller is not the Arbitrator"
        );
        _;
    }

    modifier onlyOpenCase(uint256 escrowId) {
        require(escrowIds.contains(escrowId), "Escrow does not exist");
        require(!escrows[escrowId].closed, "Escrow has been closed");
        _;
    }

    modifier onlyParticipatingParty(uint256 escrowId) {
        require(escrows[escrowId].started, "Escrow has not started");
        require(
            NFTContract.ownerOf(escrows[escrowId].nftA) == msg.sender ||
            NFTContract.ownerOf(escrows[escrowId].nftB) == msg.sender,
            "Caller is not a participating party"
        );
        _;
    }

    modifier nftContractOnly() {
        require(msg.sender == address(NFTContract), "Caller is not the NFT Contract");
        _;
    }

    // -- FUNCTIONS
    constructor(address payable _tagFeeVault) {
        require(_tagFeeVault != address(0), "Fee Treasury wallet cannot be 0 address");
        tagFeeVault = _tagFeeVault;
        maxFeeBps = 10000;
        tagFeeBps = 100;
    }

    /**
    * @dev Create a new escrow assigning counterparty, arbitrator and amounts
    * @param partyB The counterparty
    * @param partyArbitrator The Arbitrator
    * @param description The title/description of the escrow determination
    * @param determineTime The time the arbitration can kick off
    * @param currencyToDepositA The currency for the calling party to deposit
    * @param amountToDepositA The amount for the calling party to deposit
    * @param currencyToDepositB The currency for the counterparty to deposit
    * @param amountToDepositB The amount for the counterparty to deposit
    * @return escrowId the ID of the created Escrow
    */
    function createEscrow(
        address partyB,
        address partyArbitrator,
        uint256 arbitratorFeeBps,
        string memory description,
        uint256 determineTime,
        IERC20 currencyToDepositA,
        uint256 amountToDepositA,
        IERC20 currencyToDepositB,
        uint256 amountToDepositB
    ) external payable returns (uint256) {
        require(partyArbitrator != address(0), "Cannot set the Arbitrator's address to 0x00...");
        require(msg.sender != partyArbitrator && partyB != partyArbitrator, "The Arbitrator cannot be the same as the other participants");
        require(arbitratorFeeBps <= 2000, "Cannot set the arbitrator fee higher than 20 %");
        require(msg.sender != partyB, "Participants must be unique");
        require(determineTime > block.timestamp, "Time of bet should be after current time");
        require(amountToDepositB > 0 && (msg.value > 0 || amountToDepositA > 0), "You cannot request amounts less than 0");

        // ERC20 token
        if (address(currencyToDepositA) != address(0)) {
            currencyToDepositA.safeTransferFrom(msg.sender, address(this), amountToDepositA - amountToDepositA * tagFeeBps / maxFeeBps);
            currencyToDepositA.safeTransferFrom(msg.sender, tagFeeVault, amountToDepositA * tagFeeBps / maxFeeBps);
        } else {
            // GAS token
            require(msg.value == amountToDepositA, "The amount sent is not the amount determined in the call");
            (bool successA, ) = tagFeeVault.call{value: amountToDepositA * tagFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the tag fee. Gas token");
        }

        escrowAssetsA[nextEscrowId] = DepositAsset({
            currency: currencyToDepositA,
            amount: address(currencyToDepositA) == address(0) ? msg.value : amountToDepositA
        });

        escrows[nextEscrowId] = EscrowVault({
            escrowId: nextEscrowId,
            partyA: msg.sender,
            partyB: partyB,
            partyArbitrator: partyArbitrator,
            arbitratorFeeBps: arbitratorFeeBps,
            description: description,
            createTime: block.timestamp,
            determineTime: determineTime,
            started: false,
            closed: false,
            nftA: 0,
            nftB: 0,
            pendingAssetB: DepositAsset({
                currency: currencyToDepositB,
                amount: amountToDepositB
            }),
            winner: address(0)
        });

        escrowIds.add(nextEscrowId);
        addEscrowIdToAddress(nextEscrowId, msg.sender);
        addEscrowIdToAddress(nextEscrowId, partyB);
        addEscrowIdToAddress(nextEscrowId, partyArbitrator);

        emit EscrowCreated(
            nextEscrowId,
            msg.sender,
            partyB,
            partyArbitrator,
            arbitratorFeeBps,
            description,
            block.timestamp,
            determineTime,
            false,
            false,
            escrows[nextEscrowId].pendingAssetB
        );

        generateEscrowId();
        return nextEscrowId;
    }

    // TODO set the 2 NFT urls for metadata here, not the best design but easier based on what we want to achieve
    /**
    * @dev Deposits funds for partyB (counterparty) and sets the escrow as `started`
    * @param escrowId The ID to deposit the funds to.
    */
    function depositFunds(uint256 escrowId, string memory nftUrlA, string memory nftUrlB)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    {
        require(msg.sender == escrows[escrowId].partyB || escrows[escrowId].partyB == address(0),
            "Only partyB can deposit funds after creation if the bet is not open"
        );
        if (escrows[escrowId].partyB == address(0)) {
            require(
                msg.sender != escrows[escrowId].partyA &&
                msg.sender != escrows[escrowId].partyArbitrator,
                "Arbitrator or You cannot take up this bet. Only a new party can"
            );
        }

        bool valid = escrowAssetsB[escrowId].amount > 0;
        require(!valid, "You have already deposited funds");

        DepositAsset memory assetToDeposit = escrows[escrowId].pendingAssetB;
        // ERC20 token
        if (address(assetToDeposit.currency) != address(0)) {
            assetToDeposit.currency.safeTransferFrom(msg.sender, address(this), assetToDeposit.amount - assetToDeposit.amount * tagFeeBps / maxFeeBps);
            assetToDeposit.currency.safeTransferFrom(msg.sender, tagFeeVault, assetToDeposit.amount * tagFeeBps / maxFeeBps);
        } else {
            // GAS token
            (bool successA, ) = tagFeeVault.call{value: assetToDeposit.amount * tagFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the tag fee. Gas token");
            require(msg.value == assetToDeposit.amount, "The amount sent is not the amount determined in the call");
        }

        escrowAssetsB[escrowId] = assetToDeposit;
        if (escrows[escrowId].partyB == address(0)) {
            escrows[escrowId].partyB = msg.sender;
        }

        uint256 nftId1 = NFTContract.mintEscrowNft(
            escrows[escrowId].partyA,
            escrows[escrowId].partyArbitrator,
            escrowId,
            true,
            nftUrlA
        );
        uint256 nftId2 = NFTContract.mintEscrowNft(
            msg.sender,
            escrows[escrowId].partyArbitrator,
            escrowId,
            false,
            nftUrlB
        );

        escrows[escrowId].nftA = nftId1;
        escrows[escrowId].nftB = nftId2;
        escrows[escrowId].started = true;

        emit FundsDeposited(
            escrowId,
            msg.sender,
            assetToDeposit.currency,
            assetToDeposit.amount,
            nftId1,
            nftId2
        );
    }

    /**
    * @dev Withdraw for owner of partyA NFT only if 24h have passed since bet started and partyB didn't deposit.
    * There are NO NFTs issued at this point
    * @param escrowId The ID to withdraw the funds from.
    */
    function withdrawFunds(uint256 escrowId)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    {
        require(msg.sender == escrows[escrowId].partyA,
            "You are not authorized to withdraw funds from this escrow"
        );
        require(!escrows[escrowId].started, "The bet has already started, you cannot withdraw your funds");
        require(block.timestamp > (escrows[escrowId].createTime + 24 hours), "You cannot withdraw your funds yet");

        if (address(escrowAssetsA[escrowId].currency) != address(0)) {
            escrowAssetsA[escrowId].currency.safeTransfer(
                msg.sender,
                escrowAssetsA[escrowId].amount - escrowAssetsA[escrowId].amount * tagFeeBps / maxFeeBps
            );
        } else { // GAS token
            (bool successA, ) = msg.sender.call{value: escrowAssetsA[escrowId].amount - escrowAssetsA[escrowId].amount * tagFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with the withdrawing transaction. Gas token");
        }
        escrows[escrowId].closed = true;
        emit FundsWithdrawn(escrowId, msg.sender);
        emit EscrowCancelled(escrowId);
    }

    /**
    * @dev Reclaim funds for a party only if the time is 72 hours after the determine time.
    * @param escrowId The ID to withdraw the funds from.
    */
    function reclaimFunds(uint256 escrowId)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    onlyParticipatingParty(escrowId)
    {
        require(block.timestamp > (escrows[escrowId].determineTime + 72 hours), "You cannot reclaim your funds yet");
        transferFundsToParty(escrowAssetsA[escrowId], NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
        transferFundsToParty(escrowAssetsB[escrowId], NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
        escrows[escrowId].closed = true;
        emit FundsReclaimed(escrowId, msg.sender);
    }

    /**
    * @dev Determines the outcome of the Escrow
    * @param escrowId The ID of the Escrow to be determined
    * @param partyAWon If true then distributes the funds to partyA else to partyB (minus fees)
    */
    function determineOutcome(uint256 escrowId, bool partyAWon)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    onlyCaseArbitrator(escrowId)
    {
        require(block.timestamp >= escrows[escrowId].determineTime, "You cannot make a decision yet");
        require(escrows[escrowId].started, "Escrow has not started");
        require(block.timestamp >= escrows[escrowId].determineTime, "Escrow cannot be determined until determineTime");

        DepositAsset memory assetsA = escrowAssetsA[escrowId];
        DepositAsset memory assetsB = escrowAssetsB[escrowId];

        require(assetsA.amount > 0 && assetsB.amount > 0, "The parties have not completed their fund deposits yet");

        if (partyAWon) {
            transferFundsToParty(assetsA, NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
            transferFundsToParty(assetsB, NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
            escrows[escrowId].winner = NFTContract.ownerOf(escrows[escrowId].nftA);
        } else {
            transferFundsToParty(assetsA, NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
            transferFundsToParty(assetsB, NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
            escrows[escrowId].winner = NFTContract.ownerOf(escrows[escrowId].nftB);
        }
        collectArbitratorFee(escrowId);
        escrows[escrowId].closed = true;
        emit EscrowDetermined(escrowId, escrows[escrowId].winner);
    }


    /**
    * @dev Sets the address of the NFT contract
    * @param _nftContractAddress The address of the NFT contract address
    */
    function updateNftContractAddress(address _nftContractAddress) external onlyOwner {
        require(_nftContractAddress != address(0));
        NFTContract = ITagNFT(_nftContractAddress);
    }

    /**
    * @dev Changes the address of the treasury
    * @param _treasuryAddress The address of the NFT contract address
    */
    function updateTreasuryAddress(address payable _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Treasury cannot be the 0x address");
        tagFeeVault = _treasuryAddress;
    }

    // -- INTERNAL
    /**
    * Sends the funds to the arbitrator for given Escrow
    * @param escrowId The ID of the escrow in question
    */
    function collectArbitratorFee(uint256 escrowId) internal {
        DepositAsset memory assetsA = escrowAssetsA[escrowId];
        DepositAsset memory assetsB = escrowAssetsB[escrowId];
        uint256 arbitratorFeeBps = escrows[escrowId].arbitratorFeeBps;

        if (address(escrowAssetsA[escrowId].currency) != address(0)) {
            assetsA.currency.safeTransfer(msg.sender, assetsA.amount * arbitratorFeeBps / maxFeeBps);
        } else { // GAS token
            (bool successA, ) = msg.sender.call{value: assetsA.amount * arbitratorFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the Arbitrator's fee. Gas token");
        }

        if (address(assetsB.currency) != address(0)) {
            assetsB.currency.safeTransfer(msg.sender, assetsB.amount * arbitratorFeeBps / maxFeeBps);
        } else { // GAS token
            (bool successB, ) = msg.sender.call{value: assetsB.amount * arbitratorFeeBps / maxFeeBps}("");
            require(successB, "Something went wrong with collecting the Arbitrator's fee. Gas token");
        }
    }

    function addEscrowIdToAddress(uint256 escrowId, address partyAddress) internal {
        if (walletEscrows[partyAddress].escrowIds.length > 0) {
            walletEscrows[partyAddress].escrowIds.push(escrowId);
        } else {
            uint256[] memory e = new uint256[](1);
            e[0] = escrowId;
            walletEscrows[partyAddress] = IdContainer(e);
        }
    }

    /**
    * @dev Transfer asset to address
    **/
    function transferFundsToParty(DepositAsset memory asset, address winner, uint256 escrowId) internal {
        // ERC20 token
        uint256 arbitratorFeeBps = escrows[escrowId].arbitratorFeeBps;
        uint256 amountMinusFees = asset.amount - asset.amount * arbitratorFeeBps / maxFeeBps - asset.amount * tagFeeBps / maxFeeBps;
        if (address(asset.currency) != address(0)) {
            asset.currency.safeTransfer(winner, amountMinusFees);
        } else { // GAS token
            (bool success, ) = winner.call{value: amountMinusFees}("");
            require(success, "Something went wrong with the transfer to the winner of the escrow. Gas token");
        }
    }

    /**
     * @dev generate a new escrow/escrow id (iterates by 1)
     * @return the generated case id
     */
    function generateEscrowId() internal returns (uint256) {
        return nextEscrowId++;
    }

    // -- VIEWS
    function getEscrowsForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsParticipated)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        escrowsParticipated = new uint256[](length);

        for(uint i = 0; i < length; i++) {
            escrowsParticipated[i] = walletEscrows[_address].escrowIds[i];
        }
    }

    function getEscrowsPendingDepositForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsPending)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nPending = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[walletEscrows[_address].escrowIds[i]].closed &&
                address(escrowAssetsB[walletEscrows[_address].escrowIds[i]].currency) == address(0)
            ) {
                nPending = nPending + 1;
            }
        }

        escrowsPending = new uint256[](nPending);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[walletEscrows[_address].escrowIds[i]].closed &&
                address(escrowAssetsB[walletEscrows[_address].escrowIds[i]].currency) == address(0)
            ) {
                escrowsPending[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsPending;
    }

    function getEscrowsStartedForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsStarted)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nStarted = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].started &&
                !escrows[walletEscrows[_address].escrowIds[i]].closed
            ) {
                nStarted = nStarted + 1;
            }
        }

        escrowsStarted = new uint256[](nStarted);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].started &&
                !escrows[walletEscrows[_address].escrowIds[i]].closed
            ) {
                escrowsStarted[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsStarted;
    }

    function getEscrowsResolvedForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsResolved)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nClosed = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].closed &&
                escrows[walletEscrows[_address].escrowIds[i]].winner != address(0)
            ) {
                nClosed = nClosed + 1;
            }
        }

        escrowsResolved = new uint256[](nClosed);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].closed &&
                escrows[walletEscrows[_address].escrowIds[i]].winner != address(0)
            ) {
                escrowsResolved[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsResolved;
    }

    function getOpenEndedEscrows()
    public
    view
    returns
    (uint256[] memory openEndedEscrows)
    {
        uint length = nextEscrowId;
        uint nOpenPick = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[i].started &&
                !escrows[i].closed &&
                escrows[i].partyB == address(0)
            ) {
                nOpenPick = nOpenPick + 1;
            }
        }

        openEndedEscrows = new uint256[](nOpenPick);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[i].started &&
                !escrows[i].closed &&
                escrows[i].partyB == address(0)
            ) {
                openEndedEscrows[j] = i;
                j = j + 1;
            }
        }
        return openEndedEscrows;
    }
}