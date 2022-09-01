// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

import { IPawnBots } from "./IPawnBots.sol";

error PawnBots__AccountNotAllowed();
error PawnBots__MaxPerAccountExceeded();
error PawnBots__MintNotActive();
error PawnBots__MintNotPaused();
error PawnBots__MintPhaseMismatch();
error PawnBots__NonexistentToken();
error PawnBots__NotEnoughMftBalance();
error PawnBots__OffsetAlreadySet();
error PawnBots__RandomnessAlreadyRequested();
error PawnBots__RemainingMintsExceeded();
error PawnBots__RemainingReserveExceeded();
error PawnBots__TooEarlyToReveal();
error PawnBots__VrfRequestIdMismatch();

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;C1.;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;,G8t;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Gt.;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;L:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;i:;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;,t;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,iiifffffLLLLLLGCLL;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;.f;;;,C0888888800000000000000000000GGGGGGGGCCCCCCCLLLLLCCCf;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;.f.;;LGG0GGCLLLLLLLLLLfLLfffffttt11iiiiiiiiiiiiiiiiiiiiiLCf.;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;f,;;CLCGGC1i1111ttttttt1111111iiiiiiiiiiiiii11iiiiiiiiitCf.;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;t,;LLLCGGCi;;;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii1LL.;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;t,;CLLCGGCi;iiiiiiiiiiiiiiiiiiiiiiiiiii;iiiiiiiiiiiiiiiiLL,;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;1itLLLLGGCi;ii;iiiiiiiii;;iiiiiiiiiiiii;iiiiiiiiii;iiiiiLL,;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;LfLLLLGGCi;ii;;;iiiiiiiii;;ii;iiiiiiiiii;iii;;;ii;i;ii:if:;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;.:1f1tLLLCCC1;i;;;;iiiiii::1:,;i;iiiiiii;;;;;;;;;;i;;;...;;i;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;.::1LL;1LLCCC1;;;;;;ii;;i;.;;;;,;;;iiiii;;i;;;;;;;;;;;;.;;;;;i;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;,:,;tG1:fLCCC1;;;;;;iiiii;.;;;;.;;;iiii;;i;;;;;;;;;;;;;.;;;;:i;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;,::::11,1LCCCt;;;;;;;;i;;i,;;;;.;;;iiiiiiii;;;;;;;;;iii;::,:ti.;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;,:::,:i,;LLCCt;;;;;;;;;;;i;::::;;;;;;;;i;;;;;;;;;;;;ii;ii;;tL1.;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;,:::,:i,;LLCCf;;;;;;;;;;;;;i;;i;;;;;;;;;iiii;ii1i;;;;;;iii;1fi;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;.::::i1.;LLCCf;;;;;;;;;;;;;;;;;;;;;;;;;i1111i1111;;;;;;;i;;1fi;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;::,:1;.ifLCCf;;;;;;;;;;;;;;;;;;iiiiiiii11111111iiiiiiii;;;1f1;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;i1i;i:;tfLCCL;;;;;;;iiiiiiiiiiiiiiiiiiii11111iiiiiiiiiiii;tf1;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;f1i;iitfLCCLi;iiiiii11111111i1iiiiiiiiiiiiiiiiiiiii11111tfft;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;:f1i;i1tffCLCfiiiiiiiiiiiiii111111111111111ttttttttt1tt1t1fft;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;.1ft111tffLLLCLLfftttttttttttttttttfffffffffffLLffLL11titiffi;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;.:i11tfffLLLLLLLLLLLLLLLffffffffffffffttttt1111iiii;;;:::,.;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;.,:;itLLffffttt111ii1111iiii;,......;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;......;;;;;;;.,,:::::::,,,,,,,:::::::,,..;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,:::::::::::::::::;;;;;;::::;;;;iii11111111i;.;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;,fLLLfft1ii;;;;;;iiiiiiii1111i;11;11;tLLLLLLLLLLLLLLLLLf,;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;ffffLLCCLLLLLLLLLLLLLCCCCCCCLiiLiiLiiLLLLLCLLLLLLLLLLfLi;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;.:tLLftLLLLGGGGGCCLLCCCCCCCLLLLC1,f1,fi:fLLLftttt11ttttfLL1;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;L088800GLCLLCCCCC:;;:CLCCCCCLLLLCt,1t,1t,tCLLLffffLCCLLLLLLt.;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;.L88888880GCCLLCCCCGi.,;CCCCCCCCCCCCf:iL:if,iCLLCCCCCCCLLLLLLLf,;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;.f0GG00000GGCLLLCCCCCCCCCCCCCCCCCCCCCC;:L;:L;:LCCCCCCCCLLLLLLLLL:;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;:LCCCGGGGCCCLLLLLCCCCCCCCCCCCCCCCCCCCC1,f1,f1,fCCCCCCCCCCCCLLLLLi;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;,fLLLLCCLLLLffLLLCCCGCCCCCCCCCCCCCCCCCf,tf,tf,tCCCCCCCCCCCCCLLLLt;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;fffLLLLLLfffLLLCCCGGCCCCCCCCCCCCCCCCL:iL:;L:iCCCCCCCCCCCCCLLLLf.;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;fffffLLLLLffLLLLCCCGCCCCCCCCCCCCCCCCC;,L;,L;:LCCCCCCCCCCCCLLLLf,;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;tGCCLLfffftitLLLLCCCCCCGCCCCCCCCCCCCCG1.ft.t1.tCCCCCCCCCCCLLLLLf:;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/// @title PawnBots
/// @author Hifi
/// @notice Manages the mint and distribution of the Pawn Bots collection NFTs.
contract PawnBots is IPawnBots, ERC721A, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Strings for uint256;

    /// PUBLIC STORAGE ///

    /// @dev The theoretical collection size.
    uint256 public constant COLLECTION_SIZE = 8888;

    /// @dev The MFT token contract address.
    address public constant MFT = 0xDF2C7238198Ad8B389666574f2d8bc411A4b7428;

    /// @dev The token reserve allocated for contract owner.
    uint256 public constant RESERVE_CAP = 2100;

    /// @inheritdoc IPawnBots
    uint256 public override maxPerAccount;

    /// @inheritdoc IPawnBots
    bool public override mintActive;

    /// @inheritdoc IPawnBots
    uint256 public override mintCap;

    /// @inheritdoc IPawnBots
    mapping(address => uint256) public override minted;

    /// @inheritdoc IPawnBots
    MintPhase public override mintPhase;

    /// @inheritdoc IPawnBots
    uint256 public override offset;

    /// @inheritdoc IPawnBots
    string public override provenanceHash;

    /// @inheritdoc IPawnBots
    uint256 public override reserveMinted;

    /// @inheritdoc IPawnBots
    uint256 public override revealTime;

    /// INTERNAL STORAGE ///

    /// @dev The base token URI.
    string internal baseURI;

    /// @dev The merkle root of private phase allow list.
    bytes32 internal merkleRoot;

    /// @dev The Chainlink VRF fee in LINK.
    uint256 internal immutable vrfFee;

    /// @dev The Chainlink VRF key hash.
    bytes32 internal immutable vrfKeyHash;

    /// @dev The Chainlink VRF request ID.
    bytes32 internal vrfRequestId;

    constructor(
        address chainlinkToken_,
        address vrfCoordinator_,
        uint256 vrfFee_,
        bytes32 vrfKeyHash_
    ) ERC721A("Pawn Bots", "BOTS") VRFConsumerBase(vrfCoordinator_, chainlinkToken_) {
        mintCap = COLLECTION_SIZE - RESERVE_CAP;
        vrfFee = vrfFee_;
        vrfKeyHash = vrfKeyHash_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @dev See {ERC721A-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert PawnBots__NonexistentToken();
        }
        string memory mBaseURI = _baseURI();
        uint256 mOffset = offset;
        if (mOffset == 0) {
            return bytes(mBaseURI).length > 0 ? string(abi.encodePacked(mBaseURI, "box")) : "";
        } else {
            return bytes(mBaseURI).length > 0 ? string(abi.encodePacked(mBaseURI, tokenId.toString())) : "";
        }
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPawnBots
    function burnUnsold(uint256 burnAmount) external override onlyOwner {
        if (mintActive) {
            revert PawnBots__MintNotPaused();
        }
        if (burnAmount + totalSupply() > mintCap + reserveMinted) {
            revert PawnBots__RemainingMintsExceeded();
        }

        unchecked {
            mintCap -= burnAmount;
        }
        emit BurnUnsold(burnAmount);
    }

    /// @inheritdoc IPawnBots
    function mintPrivate(uint256 mintAmount, bytes32[] calldata merkleProof) external override nonReentrant {
        if (!mintActive) {
            revert PawnBots__MintNotActive();
        }
        if (mintPhase != MintPhase.PRIVATE) {
            revert PawnBots__MintPhaseMismatch();
        }
        if (!MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert PawnBots__AccountNotAllowed();
        }
        if (mintAmount + minted[msg.sender] > maxPerAccount) {
            revert PawnBots__MaxPerAccountExceeded();
        }
        if (mintAmount + totalSupply() > mintCap + reserveMinted) {
            revert PawnBots__RemainingMintsExceeded();
        }
        if (IERC20(MFT).balanceOf(msg.sender) < 1e18) {
            revert PawnBots__NotEnoughMftBalance();
        }

        unchecked {
            minted[msg.sender] += mintAmount;
        }

        _safeMint(msg.sender, mintAmount);
        emit Mint(msg.sender, mintAmount, MintPhase.PRIVATE);
    }

    /// @inheritdoc IPawnBots
    function mintPublic(uint256 mintAmount) external override nonReentrant {
        if (!mintActive) {
            revert PawnBots__MintNotActive();
        }
        if (mintPhase != MintPhase.PUBLIC) {
            revert PawnBots__MintPhaseMismatch();
        }
        if (mintAmount + minted[msg.sender] > maxPerAccount) {
            revert PawnBots__MaxPerAccountExceeded();
        }
        if (mintAmount + totalSupply() > mintCap + reserveMinted) {
            revert PawnBots__RemainingMintsExceeded();
        }
        if (IERC20(MFT).balanceOf(msg.sender) < 1e18) {
            revert PawnBots__NotEnoughMftBalance();
        }

        unchecked {
            minted[msg.sender] += mintAmount;
        }

        _safeMint(msg.sender, mintAmount);
        emit Mint(msg.sender, mintAmount, MintPhase.PUBLIC);
    }

    /// @inheritdoc IPawnBots
    function reserve(uint256 reserveAmount, address recipient) external override onlyOwner nonReentrant {
        if (reserveAmount + reserveMinted > RESERVE_CAP) {
            revert PawnBots__RemainingReserveExceeded();
        }

        unchecked {
            reserveMinted += reserveAmount;
        }

        _safeMint(recipient, reserveAmount);
        emit Reserve(reserveAmount, recipient);
    }

    /// @inheritdoc IPawnBots
    function reveal() external override onlyOwner {
        if (block.timestamp < revealTime) {
            revert PawnBots__TooEarlyToReveal();
        }
        if (offset != 0) {
            revert PawnBots__OffsetAlreadySet();
        }
        if (vrfRequestId != 0) {
            revert PawnBots__RandomnessAlreadyRequested();
        }

        vrfRequestId = requestRandomness(vrfKeyHash, vrfFee);
    }

    /// @inheritdoc IPawnBots
    function setBaseURI(string calldata newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
        emit SetBaseURI(newBaseURI);
    }

    /// @inheritdoc IPawnBots
    function setMaxPerAccount(uint256 newMaxPerAccount) external override onlyOwner {
        maxPerAccount = newMaxPerAccount;
        emit SetMaxPerAccount(newMaxPerAccount);
    }

    /// @inheritdoc IPawnBots
    function setMerkleRoot(bytes32 newMerkleRoot) external override onlyOwner {
        merkleRoot = newMerkleRoot;
        emit SetMerkleRoot(newMerkleRoot);
    }

    /// @inheritdoc IPawnBots
    function setMintActive(bool newMintActive) external override onlyOwner {
        mintActive = newMintActive;
        emit SetMintActive(newMintActive);
    }

    /// @inheritdoc IPawnBots
    function setMintPhase(MintPhase newMintPhase) external override onlyOwner {
        mintPhase = newMintPhase;
        emit SetMintPhase(newMintPhase);
    }

    /// @inheritdoc IPawnBots
    function setProvenanceHash(string calldata newProvenanceHash) external override onlyOwner {
        provenanceHash = newProvenanceHash;
        emit SetProvenanceHash(newProvenanceHash);
    }

    /// @inheritdoc IPawnBots
    function setRevealTime(uint256 newRevealTime) external override onlyOwner {
        revealTime = newRevealTime;
        emit SetRevealTime(newRevealTime);
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @dev See {ERC721A-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev See {VRFConsumerBase-fulfillRandomness}.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (offset != 0) {
            revert PawnBots__OffsetAlreadySet();
        }
        if (vrfRequestId != requestId) {
            revert PawnBots__VrfRequestIdMismatch();
        }

        unchecked {
            offset = (randomness % (COLLECTION_SIZE - 1)) + 1;
        }
        emit Reveal();
    }
}