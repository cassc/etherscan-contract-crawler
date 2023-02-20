// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

/********************
/===================\
|    ,d88b.d88b,    |
|    88888888888    |
|    `Y8888888Y'    |
|      `Y888Y'      |
|        `Y'        |
\===================/
********************/

pragma solidity ^0.8.17;

//  _________  ___  ___  _______           ________  ___       ________  _________  ________ ________  ________  _____ ______
//  |\___   ___\\  \|\  \|\  ___ \         |\   __  \|\  \     |\   __  \|\___   ___\\  _____\\   __  \|\   __  \|\   _ \  _   \
//  \|___ \  \_\ \  \\\  \ \   __/|        \ \  \|\  \ \  \    \ \  \|\  \|___ \  \_\ \  \__/\ \  \|\  \ \  \|\  \ \  \\\__\ \  \
//       \ \  \ \ \   __  \ \  \_|/__       \ \   ____\ \  \    \ \   __  \   \ \  \ \ \   __\\ \  \\\  \ \   _  _\ \  \\|__| \  \
//        \ \  \ \ \  \ \  \ \  \_|\ \       \ \  \___|\ \  \____\ \  \ \  \   \ \  \ \ \  \_| \ \  \\\  \ \  \\  \\ \  \    \ \  \
//         \ \__\ \ \__\ \__\ \_______\       \ \__\    \ \_______\ \__\ \__\   \ \__\ \ \__\   \ \_______\ \__\\ _\\ \__\    \ \__\
//          \|__|  \|__|\|__|\|_______|        \|__|     \|_______|\|__|\|__|    \|__|  \|__|    \|_______|\|__|\|__|\|__|     \|__|

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./HeartColors.sol";

/**
 * Every heart sings a song, incomplete, until another heart whispers back.
 * Those who wish to sing always find a song.
 * At the touch of a lover, everyone becomes a poet.
 *     ~ Plato
**/

contract InactiveHearts is Ownable, ERC165 {
    using Address for address;
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    error InviteeInviteError(
        bool noDuplicateInvites,
        bool senderInvited,
        bool withinInviteLimit
    );
    error PuzzleInviteError(
        bool puzzleSolved,
        bool arrayLengthsMatch,
        bool withinInviteLimit,
        bool ownColorNotUsed,
        bool validColorsUsed,
        bool noDuplicateInvites,
        bool noSelfInvite,
        bool noDuplicateColors
    );
    error PuzzleSolveError(
        bool notYetSolved,
        bool hasCrudeBorneEggs,
        bool puzzleIsSet,
        bool correctPuzzleSolution,
        bool validColor
    );
    error InviteMintError(
        bool mintStatusOpen,
        bool isInvited,
        bool mintNotYetUsed,
        bool fiveInvitesGiven,
        bool correctMsgValue
    );
    error PuzzleMintError(
        bool authorizedToMint,
        bool mintNotYetUsed,
        bool fiveInvitesGiven
    );

    CrudeBorneEggs public cbEggs;
    PuzzleProto public puzzle;
    address public ACTIVE_HEARTS_ADDRESS;

    struct ClaimInfo {
        address inviter;
        uint48 auxData;
        uint48 inviteDepth;
    }

    mapping(address => ClaimInfo) private _inviteeData;
    mapping(address => ClaimInfo) private _solverData;
    mapping(address => uint256) private _freeActivations;

    uint256 private _hcNonce;

    uint256 public mintPrice;

    string private _name;
    string private _symbol;

    string public collectionDescription;
    string public collectionImg;
    string public externalLink;

    string public imageBase;
    string public imagePostfix;

    address public STORAGE_LAYER_ADDRESS;
    address public BURN_REWARDS_ADDRESS;
    address public POOL_ADDRESS_1;
    address public POOL_ADDRESS_2;
    uint256 public p_addr_2_bp;


    uint256 private secondsPerMonth = 2629800;

    ImageDataGetterProto public imageDataGetter;
    mapping(uint256 => uint256) private _imageMode;

    mapping(uint256 => string) private _colorToString;

    modifier onlyStorage() {
        _isStorageContract();
        _;
    }

    function _isStorageContract() internal view virtual {
        require(msg.sender == STORAGE_LAYER_ADDRESS, "nsl");
    }

    enum MintStatus {
        OnlyOwner,
        Open,
        Paused,
        Closed
    }

    MintStatus public mintStatus = MintStatus.OnlyOwner;

    /**
     * "Multi-Sig" functionality for withdrawals
    **/
    address public stagedFundsReceiver;
    uint256 public stagedAmount;
    uint256 public numSignatures;
    address public stagedSigner;

    address public stagedTokenReceiver;
    uint256 public stagedTokenAmount;
    address public stagedTokenAddress;
    uint256 public numTokenSignatures;
    address public stagedTokenSigner;

    mapping(address => bool) public signers;

    modifier onlySigner() {
        _isSigner();
        _;
    }
    function _isSigner() internal view virtual {
        require(signers[msg.sender], "Not a signer!");
    }

    constructor(
        address cbAddy_,
        uint256 mintPrice_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_,
        string memory link_,
        address storageLayerAddress_,
        address puzzleAddress_,
        address[] memory signers_
    ) {
        cbEggs = CrudeBorneEggs(cbAddy_);
        mintPrice = mintPrice_;
        _name = name_;
        _symbol = symbol_;
        collectionDescription = description_;
        collectionImg = image_;
        externalLink = link_;
        STORAGE_LAYER_ADDRESS = storageLayerAddress_;
        puzzle = PuzzleProto(puzzleAddress_);

        _colorToString[0] = "Red";
        _colorToString[1] = "Blue";
        _colorToString[2] = "Green";
        _colorToString[3] = "Yellow";
        _colorToString[4] = "Orange";
        _colorToString[5] = "Purple";
        _colorToString[6] = "Black";
        _colorToString[7] = "White";

        for (uint256 i = 0; i < signers_.length; i++) {
            signers[signers_[i]] = true;
        }
    }

    function setMintStatus(MintStatus newMintStatus) public onlyOwner {
        require(newMintStatus != MintStatus.OnlyOwner, "ms");
        require(mintStatus != MintStatus.Closed);
        mintStatus = newMintStatus;
    }

    /**
     * @dev Produces a random heart color
    **/
    function _randHeartColor() private view returns (HeartColor, uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encode(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - (((_hcNonce>>128)%256) + 1)),
                    address(this),
                    _hcNonce%(1<<128)
                )
            )
        );

        return (HeartColor(rand%(uint8(HeartColor.Length))), rand);
    }

    /**
     * @dev Produces a random heart color
    **/
    function _randHeartColors(uint256 howMany) private view returns (HeartColor[] memory, uint256) {
        require(howMany > 0 && howMany <= 5, "hm");
        uint256 rand = uint256(
            keccak256(
                abi.encode(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - (((_hcNonce>>128)%256) + 1)),
                    address(this),
                    _hcNonce%(1<<128)
                )
            )
        );

        HeartColor[] memory toReturn = new HeartColor[](howMany);
        for (uint256 i = 0; i < howMany; i++) {
            toReturn[i] = HeartColor((rand>>(i*10))%(uint8(HeartColor.Length)));
        }

        return (toReturn, rand);
    }

    /**
     * @dev Returns whether an address has been invited to mint
    **/
    function invited(address addr) public view returns (bool) {
        return (_inviteeData[addr].auxData%2 == 1);
    }

    /**
     * @dev Returns the color that an address was invited to mint for
     *   - Bit-shifted to occupy bits 1-3
    **/
    function invitedColor(address addr) public view returns (HeartColor) {
        return HeartColor((_inviteeData[addr].auxData>>1)%8);
    }

    /**
     * @dev Returns whether an address has already used its invite in order to mint
     *   - Bit-shifted to occupy bit 4
    **/
    function inviteMintUsed(address addr) public view returns (bool) {
        return ((_inviteeData[addr].auxData>>4)%2 == 1);
    }

    /**
     * @dev Returns how many invites an address has given to other addresses
     *   - Bit-shifted to occupy bits 5-7
    **/
    function inviteeInvitesGiven(address addr) public view returns (uint256) {
        return ((_inviteeData[addr].auxData>>5)%8);
    }

    /**
     * @dev Returns the inviter of a given invited address
    **/
    function inviterOf(address addr) public view returns (address) {
        return _inviteeData[addr].inviter;
    }

    /**
     * @dev Returns "lineage depth" of an invited address
    **/
    function inviteDepthOf(address addr) public view returns (uint256) {
        return uint256(_inviteeData[addr].inviteDepth);
    }

    /**
     * @dev Returns whether an address has solved the puzzle with an egg
    **/
    function puzzleSolved(address addr) public view returns (bool) {
        return ((_solverData[addr].auxData%2) == 1);
    }

    /**
     * @dev Returns which color egg was designated by a puzzle solution
     *   - Bit-shifted to occupy bits 1-3
    **/
    function puzzleColor(address addr) public view returns (HeartColor) {
        return HeartColor((_solverData[addr].auxData>>1)%8);
    }

    /**
     * @dev Returns whether an address has already used its puzzle solution to mint
     *   - Bit-shifted to occupy bit 4
    **/
    function puzzleMintUsed(address addr) public view returns (bool) {
        return (((_solverData[addr].auxData>>4)%2) == 1);
    }

    /**
     * @dev Returns how many invites a puzzle solver has given to other addresses
     *   - Bit-shifted to occupy bits 5-7
    **/
    function puzzleInvitesGiven(address addr) public view returns (uint256) {
        return ((_solverData[addr].auxData>>5)%8);
    }

    /**
     * @dev Returns whether a puzzle solver has already invited someone else to a given color
     *   - Bit-shifted to occupy bit(s) 8 + (indexOf(color))
    **/
    function puzzleInviteColorUsed(address inviter, HeartColor color) public view returns (bool) {
        return ((_solverData[inviter].auxData>>(8 + uint8(color)))%2 == 1);
    }

    /**
     * @dev Invites a list of invitees to mint (for someone who was themselves invited)
     * @notice Invite up to 5 invitees to mint; Invites for a given heart color
     *   may not be used multiple times; Note that
    **/
    function inviteeInvite(address[] calldata invitees) public {
        bool alreadyInvited = false;
        bool senderInvited = invited(msg.sender);
        bool withinInviteLimit = ((inviteeInvitesGiven(msg.sender) + invitees.length) <= 5);

        (HeartColor[] memory colors, uint256 rand) = _randHeartColors(invitees.length);
        _hcNonce = (_hcNonce ^ rand) | 1;

        for (uint256 i = 0; i < invitees.length; i++) {
            address invitee = invitees[i];
            HeartColor color = colors[i];
            alreadyInvited = (alreadyInvited || invited(invitee));

            uint256 setForInvitee = 1;
            setForInvitee += (uint8(color)<<1);

            ClaimInfo memory inviteeClaimInfo = _inviteeData[invitee];

            inviteeClaimInfo.auxData = uint48(setForInvitee);
            inviteeClaimInfo.inviter = msg.sender;
            inviteeClaimInfo.inviteDepth = (uint48(inviteDepthOf(msg.sender)) + 1);

            _inviteeData[invitee] = inviteeClaimInfo;
        }

        if (alreadyInvited || (!senderInvited) || (!withinInviteLimit)) {
            revert InviteeInviteError(!alreadyInvited, senderInvited, withinInviteLimit);
        }

        _inviteeData[msg.sender].auxData += uint48(invitees.length<<5);
    }

    /**
     * @dev Invites a list of invitees to mint (for someone who solved the puzzle)
     * @notice Invite up to 5 invitees to mint; Invites for a given heart color
     *   may not be used multiple times; Only callable by those who have solved the puzzle
    **/
    function puzzleInvite(
        address[] calldata invitees,
        HeartColor[] calldata inviteeColors
    ) public {
        bool solved = puzzleSolved(msg.sender);
        bool lengthsMatch = (invitees.length == inviteeColors.length);
        bool withinInviteLimit = ((puzzleInvitesGiven(msg.sender) + invitees.length) <= 5);

        HeartColor ownColor = puzzleColor(msg.sender);
        uint256 addToMsgSenderSolverData = 0;

        bool notOwnColor = true;
        bool validColors = true;
        bool alreadyInvited = false;
        bool noSelfInvite = true;
        bool alreadyUsedColor = false;

        for (uint256 i = 0; i < invitees.length; i++) {
            address invitee = invitees[i];
            HeartColor color = inviteeColors[i];
            alreadyUsedColor = (alreadyUsedColor || puzzleInviteColorUsed(msg.sender, color));
            notOwnColor = (notOwnColor && (color != ownColor));
            validColors = (validColors && (color != HeartColor.Length));
            alreadyInvited = (alreadyInvited || invited(invitee));
            noSelfInvite = (noSelfInvite && (invitee != msg.sender));

            addToMsgSenderSolverData += (1<<(8 + uint8(color)));

            uint256 setForInvitee = 1;
            setForInvitee += (uint8(color)<<1);

            ClaimInfo memory inviteeClaimInfo = _inviteeData[invitee];

            inviteeClaimInfo.auxData = uint48(setForInvitee);
            inviteeClaimInfo.inviter = msg.sender;
            inviteeClaimInfo.inviteDepth = 1;

            _inviteeData[invitee] = inviteeClaimInfo;
        }

        if (!(solved && lengthsMatch && withinInviteLimit && notOwnColor &&
        validColors && (!alreadyInvited) && noSelfInvite && (!alreadyUsedColor))) {
            revert PuzzleInviteError(
                solved,
                    lengthsMatch,
                    withinInviteLimit,
                    notOwnColor,
                    validColors,
                    !alreadyInvited,
                    noSelfInvite,
                    !alreadyUsedColor
            );
        }

        _solverData[msg.sender].auxData += uint48(addToMsgSenderSolverData + (invitees.length<<5));
    }

    /**
     * @dev Solves a puzzle with a given solution string set
    **/
    function solvePuzzle(
        string[] calldata solution,
        HeartColor ownColor
    ) public {
        bool notYetSolved = (_solverData[msg.sender].auxData == 0);
        bool hasCrudeBorneEggs = (cbEggs.balanceOf(msg.sender) > 0);
        bool puzzleIsSet = (address(puzzle) != address(0));
        bool correctPuzzleSolution = puzzle.checkSolution(solution);
        bool validColor = (ownColor != HeartColor.Length);

        if (!(notYetSolved && hasCrudeBorneEggs && puzzleIsSet && correctPuzzleSolution && validColor)) {
            revert PuzzleSolveError(
                notYetSolved,
                    hasCrudeBorneEggs,
                    puzzleIsSet,
                    correctPuzzleSolution,
                    validColor
            );
        }

        _solverData[msg.sender].auxData += (uint8(ownColor)<<1) + 1;
    }

    /**
     * @dev Mints a new inactive heart corresponding to an invite
     * @notice Requires payment, whether egg holder or not - costs 0.01 $ETH
    **/
    function mintFromInvite() public payable {
        bool mintStatusOpen = (mintStatus == MintStatus.Open);
        bool isInvited = invited(msg.sender);
        bool mintAlreadyUsed = inviteMintUsed(msg.sender);
        bool fiveInvitesGiven = (inviteeInvitesGiven(msg.sender) == 5);
        bool correctMsgValue = (msg.value == mintPrice);

        if (!(mintStatusOpen && isInvited && (!mintAlreadyUsed) && fiveInvitesGiven && correctMsgValue)) {
            revert InviteMintError(
                mintStatusOpen,
                    isInvited,
                    !mintAlreadyUsed,
                    fiveInvitesGiven,
                    correctMsgValue
            );
        }

        _freeActivations[msg.sender] += 1;
        _inviteeData[msg.sender].auxData += (1<<4);

        uint256 newHeartId = StorageLayerProto(
            STORAGE_LAYER_ADDRESS
        ).mint(msg.sender, invitedColor(msg.sender), 0, inviteDepthOf(msg.sender), inviterOf(msg.sender));

        BurnRewardsProto(BURN_REWARDS_ADDRESS).storeReward{value: msg.value/10}(newHeartId);

        (bool success1, ) = payable(_inviteeData[msg.sender].inviter).call{value: msg.value/5}("");
        require(success1, "pf1");

        if (POOL_ADDRESS_1 != address(0)) {
            (bool success2, ) = payable(POOL_ADDRESS_1).call{value: msg.value/10}("");
            require(success2, "pf2");
        }

        if (POOL_ADDRESS_2 != address(0)) {
            if (p_addr_2_bp > 0) {
                (bool success3, ) = payable(
                    POOL_ADDRESS_2
                ).call{value: (msg.value*p_addr_2_bp)/10000}("");
                require(success3, "pf3");
            }
        }
    }

    /**
     * @dev Mints a new inactive heart corresponding to a puzzle solution
     * @notice Puzzle mints are free - solve the puzzle to be able to call this function!
    **/
    function mintFromPuzzle() public {
        bool authorizedToMint = (mintStatus == MintStatus.Open || (mintStatus == MintStatus.OnlyOwner && msg.sender == owner()));
        bool puzzleMintAlreadyUsed = puzzleMintUsed(msg.sender);
        bool fiveInvitesGiven = (puzzleInvitesGiven(msg.sender) == 5);

        if ((!authorizedToMint) || puzzleMintAlreadyUsed || (!fiveInvitesGiven)) {
            revert PuzzleMintError(authorizedToMint, !puzzleMintAlreadyUsed, fiveInvitesGiven);
        }

        _freeActivations[msg.sender] += 1;
        _solverData[msg.sender].auxData += (1<<4);

        StorageLayerProto(STORAGE_LAYER_ADDRESS).mint(msg.sender, puzzleColor(msg.sender), 0, 0, address(0));
    }

    /******************/

    /**
     * @notice Returns the cost to activate "numToActivate" hearts for a given address
    **/
    function activationCost(uint256 numToActivate, address addr) public view returns (uint256) {
        uint256 toPay = mintPrice*numToActivate;
        uint256 freeActivations = _freeActivations[addr];

        while ((toPay > 0) && (freeActivations > 0)) {
            toPay -= mintPrice;
            freeActivations -= 1;
        }

        return toPay;
    }

    /**
     * @notice Activates a given heart
     *   - Fails if ACTIVE_HEARTS_ADDRESS is not set
    **/
    function activate(uint256 heartId) public payable {
        uint256 toPay = mintPrice;
        if (_freeActivations[msg.sender] > 0) {
            toPay -= mintPrice;
            _freeActivations[msg.sender] -= 1;
        }

        require(msg.value == toPay, "rekt");

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_activate(heartId);

        BurnRewardsProto(BURN_REWARDS_ADDRESS).storeReward{value: msg.value/10}(heartId);

        if (POOL_ADDRESS_1 != address(0)) {
            (bool success1, ) = payable(POOL_ADDRESS_1).call{value: msg.value/10}("");
            require(success1, "pf1");
        }

        if (POOL_ADDRESS_2 != address(0)) {
            if (p_addr_2_bp > 0) {
                (bool success2, ) = payable(
                    POOL_ADDRESS_2
                ).call{value: (msg.value*p_addr_2_bp)/10000}("");
                require(success2, "pf2");
            }
        }
    }

    /**
     * @notice Activates a batch of hearts, identified by token IDs
     *   - Fails if ACTIVE_HEARTS_ADDRESS is not set
    **/
    function batchActivate(uint256[] calldata heartIds) public payable {
        uint256 toPay = mintPrice*(heartIds.length);
        uint256 freeActivations = _freeActivations[msg.sender];
        uint256 freeUsed = 0;

        while ((toPay > 0) && (freeActivations > 0)) {
            toPay -= mintPrice;
            freeActivations -= 1;
            freeUsed += 1;
        }

        require(msg.value == toPay, "rekt");
        _freeActivations[msg.sender] -= freeUsed;

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_batchActivate(heartIds);

        BurnRewardsProto(BURN_REWARDS_ADDRESS).batchStoreReward{value: msg.value/10}(heartIds);

        if (POOL_ADDRESS_1 != address(0)) {
            (bool success1, ) = payable(POOL_ADDRESS_1).call{value: msg.value/10}("");
            require(success1, "pf1");
        }

        if (POOL_ADDRESS_2 != address(0)) {
            if (p_addr_2_bp > 0) {
                (bool success2, ) = payable(
                    POOL_ADDRESS_2
                ).call{value: (msg.value*p_addr_2_bp)/10000}("");
                require(success2, "pf2");
            }
        }
    }

    function isExpired(uint256 heartId) public view returns (bool) {
        return ((block.timestamp - lastShifted(heartId)) > secondsPerMonth);
    }

    function getExpiryTime(uint256 heartId) public view returns (uint256) {
        return (lastShifted(heartId) + secondsPerMonth);
    }

    /**
     * @notice Burns a heart with ID "heartId"
     *   - Fails if isExpired(heartId) returns false
    **/
    function burn(uint256 heartId) public {
        require(StorageLayerProto(
            STORAGE_LAYER_ADDRESS
        ).storage_balanceOf(true, msg.sender) > 0, "need active <3's...");

        require((block.timestamp - lastShifted(heartId)) > secondsPerMonth, "exp_burn");

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_burn(heartId);

        BurnRewardsProto(BURN_REWARDS_ADDRESS).disburseBurnReward(heartId, msg.sender);
    }

    /**
     * @notice Burns a set of hearts with IDs supplied in "heartIds"
     *   - Fails if isExpired(heartIds[i]) returns false for any "i"
    **/
    function batchBurn(uint256[] calldata heartIds) public {
        require(StorageLayerProto(
            STORAGE_LAYER_ADDRESS
        ).storage_balanceOf(true, msg.sender) > 0, "need active <3's...");

        uint256 month = secondsPerMonth;

        bool allExpired = true;
        for (uint256 i = 0; i < heartIds.length; i++) {
            allExpired = allExpired && ((block.timestamp - lastShifted(heartIds[i])) > month);
        }
        require(allExpired, "exp_batch_burn");

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_batchBurn(heartIds);

        BurnRewardsProto(BURN_REWARDS_ADDRESS).batchDisburseBurnReward(heartIds, msg.sender);
    }

    /******************/

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }

    /******************/

    function setActiveHeartsContract(address _activeHearts) public onlyOwner {
        ACTIVE_HEARTS_ADDRESS = _activeHearts;
    }

    function setBurnRewardsAddress(address burnRewardsAddress) public onlyOwner {
        BURN_REWARDS_ADDRESS = burnRewardsAddress;
    }

    function setPuzzleAddress(address puzzleAddress) public onlyOwner {
        puzzle = PuzzleProto(puzzleAddress);
    }

    function setPoolAddress1(address poolAddress1) public onlyOwner {
        POOL_ADDRESS_1 = poolAddress1;
    }

    function setPoolAddress2(address poolAddress2) public onlyOwner {
        POOL_ADDRESS_2 = poolAddress2;
    }

    function setPA2BP(uint256 pa2bp) public onlyOwner {
        require(pa2bp <= 6000);
        p_addr_2_bp = pa2bp;
    }

    /******************/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /******************/

    function emitTransfer(address from, address to, uint256 tokenId) public onlyStorage {
        emit Transfer(from, to, tokenId);
    }

    function batchEmitTransfers(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public onlyStorage {
        for (uint256 i = 0; i < from.length; i++) {
            emit Transfer(from[i], to[i], tokenIds[i]);
        }
    }

    function emitApproval(address owner, address approved, uint256 tokenId) public onlyStorage {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) public onlyStorage {
        emit ApprovalForAll(owner, operator, approved);
    }

    /******************/

    /**
     * Main portion of ERC721-compatible functionality.
     * Modified to function smoothly with the top-level
     * interface of Virtue (Inactive) Hearts.
    **/

    function balanceOf(address owner) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_balanceOf(false, owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_ownerOf(false, tokenId);
    }

    function colorOf(uint256 tokenId) public view returns (HeartColor) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_colorOf(false, tokenId);
    }

    function parentOf(uint256 tokenId) public view returns (address) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_parentOf(false, tokenId);
    }

    function lineageDepthOf(uint256 tokenId) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_lineageDepthOf(false, tokenId);
    }

    function numChildrenOf(uint256 tokenId) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_numChildrenOf(false, tokenId);
    }

    function rawGenomeOf(uint256 tokenId) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_rawGenomeOf(false, tokenId);
    }

    function genomeOf(uint256 tokenId) public view returns (string memory) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_genomeOf(false, tokenId);
    }

    function lastShifted(uint256 tokenId) public view returns (uint64) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_lastShifted(false, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS)._exists(false, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_transferFrom(msg.sender, from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId);
    }

    function approve(
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_approve(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_getApproved(false, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool _approved
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_setApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_isApprovedForAll(false, owner, operator);
    }

    /********/

    function totalSupply() public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_totalSupply(false);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_tokenOfOwnerByIndex(false, owner, index);
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_tokenByIndex(false, index);
    }

    /******************/

    /**
     * Remaining functionality found below
    **/

    function name() public view returns (string memory) {
        return _name;
    }

    function setName(string calldata newName) public onlyOwner {
        _name = newName;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setSymbol(string calldata newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }

    function setImage(string calldata newImage) public onlyOwner {
        collectionImg = newImage;
    }

    function setCollectionDescription(string calldata newDescription) public onlyOwner {
        collectionDescription = newDescription;
    }

    function setExternalLink(string calldata newLink) public onlyOwner {
        externalLink = newLink;
    }

    /**
     * @notice Flips image between on-chain and off-chain mode for a given heart
    **/
    function flipImageMode(uint256 heartId) public {
        require(msg.sender == ownerOf(heartId), "o");
        if (imageMode(heartId) == 0) {
            _imageMode[heartId/256] += (1<<(heartId%256));
        }
        else {
            _imageMode[heartId/256] -= (1<<(heartId%256));
        }
    }

    /**
     * @notice Returns the "image mode" for a given heart, denoting whether it will
     *   be rendered on-chain or off-chain
    **/
    function imageMode(uint256 heartId) public view returns (uint256) {
        return (_imageMode[heartId/256]>>(heartId%256))%2;
    }

    function imageURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(imageBase, "/", uint256(uint8(colorOf(tokenId))).toString(), imagePostfix));
    }

    function setImageBase(string memory newImageBase) public onlyOwner {
        imageBase = newImageBase;
    }

    function setImagePostfix(string memory newImagePostfix) public onlyOwner {
        imagePostfix = newImagePostfix;
    }

    /**
     * @dev Returns an on-chain token URI (which also points to an off-chain image URI)
     * for a given token
    **/
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        HeartColor color = colorOf(tokenId);

        string memory toReturn = string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"Heart #", tokenId.toString(), "\",",
                    "\"description\":\"This is a ", _colorToString[uint256(uint8(color))], " Heart. It's dangerous to go alone.\",",
                    "\"image\":\"",
                    ((imageMode(tokenId) == 0) ? string(abi.encodePacked(
                        "data:image/svg+xml;utf8,", imageDataGetter.getImageData(color)
                    )) : imageURI(tokenId))
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                "\",\"attributes\":[{\"trait_type\":\"Heart Color\",\"value\":\"", _colorToString[uint256(uint8(color))],
                "\"},{\"trait_type\":\"Genome\",\"value\":\"", genomeOf(tokenId),
                "\"},{\"trait_type\":\"Lineage Parent\",\"value\":\"", uint256(uint160(parentOf(tokenId))).toHexString(20),
                "\"},{\"trait_type\":\"Lineage Depth\",\"value\":\"", lineageDepthOf(tokenId).toString()
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                    "\"},{\"trait_type\":\"Number of Children\",\"value\":\"", numChildrenOf(tokenId).toString(),
                    "\"},{\"trait_type\":\"Expiration Date\",\"display_type\":\"date\",\"value\":\"", getExpiryTime(tokenId).toString(), "\"}",
                    (isExpired(tokenId) ? ",{\"value\":\"Expired\"}" : ""),
                    "],\"external_url\":\"https://hearts.virtue.wtf/hearts?id=", tokenId.toString(), "\"}"
            )
        );

        return toReturn;
    }

    function setImageDataGetter(address newIDGAddress) public onlyOwner {
        imageDataGetter = ImageDataGetterProto(newIDGAddress);
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(),"\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collectionImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    /******************/

    function switchSignatureAddress(address newSignatureAddress) public onlySigner {
        signers[msg.sender] = false;
        signers[newSignatureAddress] = true;
    }

    function _resetWithdrawal() private {
        stagedFundsReceiver = address(0);
        stagedAmount = 0;
        numSignatures = 0;
        stagedSigner = address(0);
    }

    function withdraw(address to, uint256 amount) public onlySigner {
        if (numSignatures == 0) {
            stagedFundsReceiver = to;
            stagedAmount = amount;
            numSignatures = 1;
            stagedSigner = msg.sender;
        }
        else if (numSignatures == 1) {
            require(msg.sender != stagedSigner, "cannot sign twice");
            require(to == stagedFundsReceiver, "rcv mismatch");
            require(amount == stagedAmount, "amt mismatch");

            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "Payment failed!");

            _resetWithdrawal();
        }
        else {
            revert("impossible");
        }
    }

    function rejectWithdrawal() public onlySigner {
        _resetWithdrawal();
    }

    function _resetTokenWithdrawal() private {
        stagedTokenReceiver = address(0);
        stagedTokenAmount = 0;
        stagedTokenAddress = address(0);
        numTokenSignatures = 0;
        stagedTokenSigner = address(0);
    }

    function withdrawTokens(address to, uint256 amount, address tokenAddress) public onlySigner {
        if (numTokenSignatures == 0) {
            stagedTokenReceiver = to;
            stagedTokenAmount = amount;
            stagedTokenAddress = tokenAddress;
            numTokenSignatures = 1;
            stagedTokenSigner = msg.sender;
        }
        else if (numTokenSignatures == 1) {
            require(msg.sender != stagedTokenSigner, "cannot sign twice");
            require(to == stagedTokenReceiver, "t_rcv mismatch");
            require(amount == stagedTokenAmount, "t_amt mismatch");
            require(tokenAddress == stagedTokenAddress, "t_addr mismatch");

            IERC20(tokenAddress).transfer(to, amount);

            _resetTokenWithdrawal();
        }
        else {
            revert("t_impossible");
        }
    }

    function rejectTokenWithdrawal() public onlySigner {
        _resetTokenWithdrawal();
    }

    /********/

    receive() external payable {}
}

////////////////////

abstract contract CrudeBorneEggs {
    function balanceOf(address owner) public view virtual returns (uint256);
}

//////////

abstract contract PuzzleProto {
    function checkSolution(string[] calldata solution) public view virtual returns (bool);
}

//////////

abstract contract StorageLayerProto {
    uint256 public _nextToMint;

    function storage_balanceOf(
        bool active,
        address owner
    ) public view virtual returns (uint256);

    function storage_ownerOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (address);

    function storage_colorOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (HeartColor);

    function storage_parentOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (address);

    function storage_lineageDepthOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint256);

    function storage_numChildrenOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint256);

    function storage_rawGenomeOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint256);

    function storage_genomeOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (string memory);

    function storage_lastShifted(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint64);

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_approve(
        address msgSender,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_getApproved(
        bool active,
        uint256 tokenId
    ) public view virtual returns (address);

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool _approved
    ) public virtual;

    function storage_isApprovedForAll(
        bool active,
        address owner,
        address operator
    ) public view virtual returns (bool);

    /********/

    function storage_totalSupply(bool active) public view virtual returns (uint256);

    function storage_tokenOfOwnerByIndex(
        bool active,
        address owner,
        uint256 index
    ) public view virtual returns (uint256);

    function storage_tokenByIndex(
        bool active,
        uint256 index
    ) public view virtual returns (uint256);

    /********/

    function mint(
        address to,
        HeartColor color,
        uint256 lineageToken,
        uint256 lineageDepth,
        address parent
    ) public virtual returns (uint256);

    function storage_activate(uint256 tokenId) public virtual;

    function storage_batchActivate(uint256[] calldata tokenIds) public virtual;

    function storage_burn(uint256 tokenId) public virtual;

    function storage_batchBurn(uint256[] calldata tokenIds) public virtual;

    /********/

    function _exists(bool active, uint256 tokenId) public view virtual returns (bool);
}

//////////

abstract contract BurnRewardsProto {
    function storeReward(uint256 heartId) public payable virtual;

    function disburseBurnReward(uint256 heartId, address to) public virtual;

    function batchStoreReward(uint256[] calldata heartIds) public payable virtual;

    function batchDisburseBurnReward(uint256[] calldata heartIds, address to) public virtual;
}

//////////

abstract contract ImageDataGetterProto {
    function getImageData(HeartColor color) public view virtual returns (string memory);
}

////////////////////////////////////////

/********************
/===================\
|    ,d88b.d88b,    |
|    88888888888    |
|    `Y8888888Y'    |
|      `Y888Y'      |
|        `Y'        |
\===================/
********************/