// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC721TokenReciever.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IShatteredEON.sol";
import "./interfaces/IMasterStaker.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IRandomizer.sol";

contract Pytheas is IPytheas, IERC721TokenReceiver, Pausable {
    // struct to store a stake's token, sOwner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address sOwner;
    }

    event ColonistStaked(
        address indexed sOwner,
        uint256 indexed tokenId,
        uint256 value
    );
    event ColonistClaimed(
        uint256 indexed tokenId,
        bool indexed unstaked,
        uint256 earned
    );

    event Metamorphosis(address indexed addr, uint256 indexed tokenId);

    // reference to the Colonist NFT contract
    IColonist public colonistNFT;
    // reference to the game logic  contract
    IShatteredEON public shattered;
    // reference to the masterStaker contract
    IMasterStaker public masterStaker;
    // reference to orbital blockade to retrieve information on staked pirates
    IOrbitalBlockade public orbital;
    // reference to the $rEON contract for minting $rEON earnings
    IRAW public raw;
    // reference to Randomizer
    IRandomizer public randomizer;

    // maps tokenId to stake
    mapping(uint256 => Stake) private pytheas;

    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;

    // colonist earn 2700 $rEON per day
    uint256 public constant DAILY_rEON_RATE = 2700;
    // colonist must have 2 days worth of $rEON to unstake or else they're still down in the mines
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // pirates take a 20% tax on all $rEON claimed
    uint256 public constant rEON_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 3.125 billion (half of the total supply) rEON earned through staking;
    uint256 public constant MAXIMUM_GLOBAL_rEON = 3125000000;
    // colonistStaked
    uint256 public numColonistStaked;
    // amount of $rEON earned so far
    uint256 public totalRawEonEarned;
    // the last time $rEON was claimed
    uint256 private lastClaimTimestamp;
    //allowed to call owner functions
    address public auth;

    // emergency rescue to allow unstaking without any checks but without $rEON
    bool public rescueEnabled;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(colonistNFT) != address(0) &&
                address(raw) != address(0) &&
                address(orbital) != address(0) &&
                address(shattered) != address(0) &&
                address(masterStaker) != address(0) &&
                address(randomizer) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _colonistNFT,
        address _raw,
        address _orbital,
        address _shattered,
        address _masterStaker,
        address _rand
    ) external onlyOwner {
        colonistNFT = IColonist(_colonistNFT);
        raw = IRAW(_raw);
        orbital = IOrbitalBlockade(_orbital);
        shattered = IShatteredEON(_shattered);
        masterStaker = IMasterStaker(_masterStaker);
        randomizer = IRandomizer(_rand);
    }

    /** STAKING */

    /**
     * adds Colonists to pytheas and crew
     * @param account the address of the staker
     * @param tokenIds the IDs of the Colonists to stake
     */
    function addColonistToPytheas(address account, uint16[] calldata tokenIds)
        external
        override
        whenNotPaused
        noCheaters
    {
        require(account == tx.origin);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender == address(masterStaker)) {
                require(
                    colonistNFT.isOwner(tokenIds[i]) == account,
                    "Not Colonist Owner"
                );
                colonistNFT.transferFrom(account, address(this), tokenIds[i]);
            } else if (msg.sender != address(shattered)) {
                // dont do this step if its a mint + stake
                require(
                    colonistNFT.isOwner(tokenIds[i]) == msg.sender,
                    "Not Colonist Owner"
                );
                colonistNFT.transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }
            _addColonistToPytheas(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Colonist to pytheas
     * @param account the address of the staker
     * @param tokenId the ID of the Colonist to add to pytheas
     */
    function _addColonistToPytheas(address account, uint256 tokenId)
        internal
        _updateEarnings
    {
        pytheas[tokenId] = Stake({
            sOwner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        numColonistStaked += 1;
        emit ColonistStaked(account, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $rEON earnings and optionally unstake tokens from Pytheas / Crew
     * to unstake a Colonist it will require it has 2 days worth of $rEON unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimColonistFromPytheas(
        address account,
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused _updateEarnings noCheaters {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimColonistFromPytheas(account, tokenIds[i], unstake);
        }
        if (owed == 0) {
            return;
        }
        raw.mint(1, owed, account);
    }

    /** external function to see the amount of raw eon
  a colonist has mined
  */

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        Stake memory stake = pytheas[tokenId];
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            owed = ((block.timestamp - stake.value) * DAILY_rEON_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $rEON production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
    }

    /**
     * realize $rEON earnings for a single Colonist and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Pirates
     * if unstaking, there is a 50% chance all $rEON is stolen
     * @param tokenId the ID of the Colonist to claim earnings from
     * @param unstake whether or not to unstake the Colonist
     * @return owed - the amount of $rEON earned
     */
    function _claimColonistFromPytheas(
        address account,
        uint256 tokenId,
        bool unstake
    ) internal returns (uint256 owed) {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == account, "Not Owner");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "Your shift isn't over!"
        );
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            owed = ((block.timestamp - stake.value) * DAILY_rEON_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $rEON production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
        if (unstake) {
            if (randomizer.random(tokenId) & 1 == 1) {
                // 50% chance of all $rEON stolen
                orbital.payPirateTax(owed);
                owed = 0;
            }
            delete pytheas[tokenId];
            numColonistStaked -= 1;
            // Always transfer last to guard against reentrance
            colonistNFT.safeTransferFrom(address(this), account, tokenId, ""); // send back colonist
        } else {
            orbital.payPirateTax((owed * rEON_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked pirates
            owed = (owed * (100 - rEON_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Colonist sOwner
            pytheas[tokenId] = Stake({
                sOwner: account,
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit ColonistClaimed(tokenId, unstake, owed);
    }

    // To be worthy of joining the pirates one must be
    // willing to risk it all, used to handle the colonist
    // token burn when making an attempt to join the pirates
    function handleJoinPirates(address addr, uint16 tokenId)
        external
        override
        noCheaters
    {
        require(admins[msg.sender]);
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Pytheas: Not Owner");
        delete pytheas[tokenId];
        colonistNFT.burn(tokenId);

        emit Metamorphosis(addr, tokenId);
    }

    function payUp(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) external override _updateEarnings {
        require(admins[msg.sender]);
        uint256 minusTax = 0;
        minusTax += _piratesLife(tokenId, amtMined, addr);
        if (minusTax == 0) {
            return;
        }
        raw.mint(1, minusTax, addr);
    }

    /**
   * external admin only function to get the amount owed to a colonist
   * for use whem making a pirate attempt
   @param account the account that owns the colonist
   @param tokenId  the ID of the colonist who is mining
    */
    function getColonistMined(address account, uint16 tokenId)
        external
        view
        override
        returns (uint256 minedAmt)
    {
        require(admins[msg.sender]);
        uint256 mined = 0;
        mined += colonistDues(account, tokenId);
        return mined;
    }

    /**
 * internal function to calculate the amount a colonist
 * is owed for their mining attempts;
 * for use with making a pirate attempt;
 @param addr the owner of the colonist
 @param tokenId the ID of the colonist who is mining
  */
    function colonistDues(address addr, uint16 tokenId)
        internal
        view
        returns (uint256 mined)
    {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Not Owner");
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            mined =
                ((block.timestamp - stake.value) * DAILY_rEON_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            mined = 0; // $rEON production stopped already
        } else {
            mined =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
    }

    /*
Realizes gained rEON on a failed pirate attempt and always pays pirate tax
*/
    function _piratesLife(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) internal returns (uint256 owed) {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Pytheas: Not Owner");
        // tax amount sent to pirates
        uint256 pirateTax = (amtMined * rEON_CLAIM_TAX_PERCENTAGE) / 100;
        orbital.payPirateTax(pirateTax);
        // remainder after pirate tax goes to Colonist
        //sOwner who made the pirate attempt
        owed = (amtMined - pirateTax);
        // reset stake
        pytheas[tokenId] = Stake({
            sOwner: addr,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        emit ColonistClaimed(tokenId, false, owed);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external noCheaters {
        require(rescueEnabled, "Rescue Not Enabled");
        uint256 tokenId;
        Stake memory stake;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = pytheas[tokenId];
            require(stake.sOwner == msg.sender, "Not Owner");
            delete pytheas[tokenId];
            numColonistStaked -= 1;
            colonistNFT.safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            ); // send back Colonist
            emit ColonistClaimed(tokenId, true, 0);
        }
    }

    /** ACCOUNTING */

    /**
     * tracks $rEON earnings to ensure it stops once 6.5 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            totalRawEonEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    numColonistStaked *
                    DAILY_rEON_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    //Admin
    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    //READ ONLY

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Only EOA");
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}