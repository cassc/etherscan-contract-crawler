// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../SuperOwnable.sol";

interface IKillaPasses {
    function burn(uint256 typeId, address owner, uint256 n) external;
}

interface IURIManager {
    function getTokenURI(
        uint256 id,
        Token memory token
    ) external view returns (string memory);
}

interface IKILLABITS {
    function detachUpgrade(uint256 token) external;

    function tokenUpgrade(uint256 token) external view returns (uint64);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IKILLAGEAR {
    function detokenize(
        address addr,
        uint256[] calldata types,
        uint256[] calldata amounts
    ) external;
}

struct Token {
    address owner;
    uint16 linkedNext;
    uint16 linkedPrev;
    uint32 stakeTimestamp;
    uint8 generation;
    uint8 incubationPhase;
    uint16 bit;
}

struct Wallet {
    uint16 balance;
    uint16 stakes;
    uint16 linkedMints;
    uint16 batchedMints;
    uint16 allowlistMints;
    uint16 privateMints;
    uint16 holderMints;
    uint16 redeems;
}

struct MintCounters {
    uint16 linked;
    uint16 batched;
    uint16 redeems;
    uint16 stakes;
}

interface IIncubator {
    function add(address owner, uint256[] calldata tokenIds) external;

    function add(address owner, uint256 start, uint256 count) external;

    function remove(address owner, uint256[] calldata tokenIds) external;

    function remove(address owner, uint256 start, uint256 count) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

abstract contract KillaCubsStorage is
    DefaultOperatorFilterer,
    SuperOwnable,
    ERC2981
{
    string public name;
    string public symbol;

    uint256 public activeGeneration = 1;
    uint256 public initialIncubationLength = 8;
    uint256 public remixIncubationLength = 4;

    IIncubator public incubator;

    MintCounters public counters;

    mapping(address => Wallet) public wallets;
    mapping(uint256 => Token) public tokens;
    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    IKILLABITS public bitsContract;
    IKILLAGEAR public gearContract;

    IERC721 public bears;
    IKillaPasses public passes;
    IERC721 public kilton;
    IERC721 public labs;
    bool public claimsStarted;

    mapping(uint256 => bool) public bitsUsed;
    mapping(uint256 => uint256) public laterGenerations;

    address public airdropper;
    address public staker;
    address public claimer;

    IURIManager public uriManager;

    string public baseURI;
    string public baseURIFinalized;
    uint256 public finalizedGeneration;

    mapping(bytes4 => address) extensions;
    mapping(uint256 => address) externalStorage;

    error TransferToNonERC721ReceiverImplementer();
    error NonExistentToken();
    error NotAllowed();
    error Overflow();
    error ClaimNotStarted();

    event BitsAdded(uint256[] indexed tokens, uint16[] indexed bits);
    event BitRemoved(uint256 indexed token, uint16 indexed bit);
    event FastForwarded(uint256[] indexed tokens, uint256 indexed numberOfDays);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(
        address bitsAddress,
        address gearAddress,
        address bearsAddress,
        address passesAddress,
        address kiltonAddress,
        address labsAddress,
        address superOwner
    ) SuperOwnable(superOwner) {
        bitsContract = IKILLABITS(bitsAddress);
        gearContract = IKILLAGEAR(gearAddress);
        bears = IERC721(bearsAddress);
        passes = IKillaPasses(passesAddress);
        kilton = IERC721(kiltonAddress);
        labs = IERC721(labsAddress);
    }

    function setAirdropper(address a) external onlyOwner {
        airdropper = a;
    }

    function setStaker(address a) external onlyOwner {
        staker = a;
    }

    function setClaimer(address a) external onlyOwner {
        claimer = a;
    }

    function setExtension(bytes4 id, address a) external onlyOwner {
        extensions[id] = a;
    }

    function setExternalStorage(uint256 id, address a) external onlyOwner {
        externalStorage[id] = a;
    }

    function _delegatecall(
        address target,
        bytes memory data
    ) internal returns (bool, bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if (!success) {
            if (returndata.length == 0) revert();
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
        return (success, returndata);
    }
}