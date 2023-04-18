// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../lib/TokenizedContract.sol";
import "solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct Signal {
    uint8 status;
    uint8 style;
    uint40 startBlock;
    address sender;
    bytes[37] message;
}
interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns(bool);
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);

}

interface ICustomAttributes {
    function getCustomAttributes () external view returns (bytes memory);
}

interface ITransponderMetadata {

    function broadcastMetadata (bool signalling, uint peer, uint modelId, uint startBlock, string memory content, string memory handle) external view returns (string memory);
    function propagandaMetadata (uint modelId) external view returns (string memory);
    function signalMetadata(uint peer, Signal memory local, Signal memory peer1, Signal memory peer2) external view returns (string memory);

    function adjustTypeface (address _typefaceAddress, uint256 weight, string memory style) external;

    function uploadModels (uint48 count, bytes memory data) external;
    function uploadPropaganda (string[] calldata messages, string[] calldata handles) external;
    function updatePropaganda (uint[] calldata ids, string[] calldata messages, string[] calldata handles) external;

    function setB64EncodeURI (bool active) external;
}

/*
 * @title Transponders
 * @author Ponderware Ltd
 * @dev Tokenized Chain-Complete ERC1155 Contract
 */
contract Transponders is ERC1155, TokenizedContract, ICustomAttributes {

    event Broadcast (string message, string handle);

    ITransponderMetadata Metadata;

    constructor (uint256 tokenId) TokenizedContract(tokenId) {
        addRole(owner(), Role.Uploader);
        addRole(owner(), Role.Beneficiary);
        addRole(owner(), Role.Transmitter);
        addRole(owner(), Role.Censor);
        addRole(owner(), Role.Jammer);
        addRole(owner(), Role.Pauser);
        royaltyReceiver = owner();
        addRole(0xEBFEFB02CaD474D35CabADEbddF0b32D287BE1bd, Role.CodeLawless);
        addRole(0x3a14b1Cc1210a87AE4B6bf635FBA898628F06357, Role.LowLevelRedactedDrone);
    }

    bool internal initialized = false;

    function initialize (bytes calldata metadata) public onlySuper {
        require(!initialized, "Initialized");
        initialized = true;
        Metadata = ITransponderMetadata(Create2.deploy(0, 0, abi.encodePacked(metadata, abi.encode(address(this), CodexAddress))));
    }

    IDelegationRegistry constant dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    bool public delegationEnabled = true;

    uint private constant TRANSPONDER_TYPES = 5;
    uint private constant CHROMA_COUNT = 5;

    Signal[] Signals;

    bool public jammed = true;

    function jam (bool value) public onlyBy(Role.Jammer) {
        jammed = value;
    }

    function signalExists (uint256 signalId) public view returns (bool) {
        return (signalId >= TRANSPONDER_TYPES && signalId - TRANSPONDER_TYPES < Signals.length);
    }

    bool internal breached = false;

    function breachTheNetwork (string calldata breachMessage,
                               address[] calldata lawless,
                               uint8[] calldata transponderTypes,
                               uint8[] calldata chromas,
                               bytes[37][] calldata messages)
        public
        onlyBy(Role.CodeLawless)
    {
        require (breached == false, "we're already in");
        breached = true;
        jammed = false;
        broadcastDuration = 300;
        broadcastInterval = 0;
        broadcast(breachMessage, "code.lawless");
        for (uint i = 0; i < lawless.length; i++) {
            uint signalId = TRANSPONDER_TYPES + Signals.length;
            _mint(lawless[i], signalId, 1, "");
            Signals.push(Signal(0, (chromas[i] << 4) + uint8(transponderTypes[i]), uint40(block.number), lawless[i], messages[i]));
        }
    }

    modifier validSignal (uint signalId) {
        require (signalExists(signalId), "signal not detected");
        _;
    }

    function totalSignals () public view returns (uint) {
        return Signals.length;
    }

    function getSignal (uint256 peer) public view validSignal(peer + TRANSPONDER_TYPES) returns (uint8, uint8, uint40, address, bool, string memory) {
        Signal storage s = Signals[peer];
        bytes[37] storage m = s.message;
        uint length = 0;
        for (; length < 37; length++) {
            if(uint8(bytes1(m[length])) == 0) break;
        }
        bytes memory message = new bytes(length);
        for (uint i = 0; i < length; i++) {
            message[i] = bytes1(m[i]);
        }
        return(s.style & 15, s.style >> 4, s.startBlock, s.sender, (s.status & 1) == 1, string(message));
    }

    function validMessage (bytes[37] memory message) public pure returns (bool) {
        for (uint i = 0; i < 37; i++) {
            uint b = uint8(bytes1(message[i]));
            if ((b >= 97 && b <= 122) || // a-z
                (b == 32) || // " "
                (b >= 45 && b <= 57) || // - . / 0-9
                (b == 39) || // '
                (b == 63) || // ?
                (b == 33)) continue; // !
                if (b == 0) break;
            return false;
        }
        return true;
    }

    modifier validSignalParameters (bytes[37] memory message, uint8 chroma) {
        require(validMessage(message), "unrecoverable uncorrectable error");
        require(chroma < CHROMA_COUNT, "incompatible power source");
        _;
    }

    modifier onlyAuthorized (address lawless, uint256 id) {
        require (lawless == msg.sender
                 || isApprovedForAll[lawless][msg.sender]
                 || (delegationEnabled && (dc.checkDelegateForContract(msg.sender, lawless, address(this))
                                           || dc.checkDelegateForToken(msg.sender, lawless, address(this), id))),


                 "unauthorized access detected");
        _;
    }

    function signal (address lawless, uint256 transponderType, uint8 chroma, bytes[37] memory message) public validSignalParameters(message, chroma) onlyAuthorized(lawless, transponderType) returns (uint256 signalId) {
        require(transponderType < TRANSPONDER_TYPES, "incompatible transponder");
        require(!jammed, "jammed");
        require(balanceOf[lawless][transponderType] > 0, "you'll need to rummage for that");
        signalId = TRANSPONDER_TYPES + Signals.length;
        _burn(lawless, transponderType, 1);
        _mint(lawless, signalId, 1, "");
        Signals.push(Signal(0, (chroma << 4) + uint8(transponderType), uint40(block.number), lawless, message));
    }

    uint public priceOfIndecisionAndRequiredMaterials = 0.1 ether;

    function reevaluate (address lawless, uint signalId, uint8 chroma, bytes[37] memory message) public validSignal(signalId) validSignalParameters(message, chroma) onlyAuthorized(lawless, signalId) payable {
        require(msg.value >= priceOfIndecisionAndRequiredMaterials, "parts aren't free");
        require(balanceOf[lawless][signalId] == 1, "hack thwarted");
        Signal storage s = Signals[signalId - TRANSPONDER_TYPES];
        s.message = message;
        s.sender = lawless;
        s.status = 0;
        s.style = (chroma << 4) + (s.style & 15);
    }

    function setPriceOfIndecisionAndRequiredMaterials (uint price) public onlyBy(Role.Fixer) {
        priceOfIndecisionAndRequiredMaterials = price;
    }

    function setB64EncodeURI (bool value) public onlyBy(Role.Fixer) {
        Metadata.setB64EncodeURI(value);
    }

    function redact (uint signalId, bytes[37] memory redactedMessage) public validSignal(signalId) onlyBy(Role.Censor) {
        Signal storage s = Signals[signalId - TRANSPONDER_TYPES];
        s.status |= 1;
        s.message = redactedMessage;
    }

    string public broadcastMessage;
    string public broadcastHandle;
    uint internal broadcastBlock = 0;
    uint internal broadcastDuration = 25;
    uint internal broadcastInterval = 350;

    function broadcasting () public view returns (bool) {
        if (bytes(broadcastMessage).length == 0) return false;
        if (broadcastInterval == 0) {
            return (block.number - broadcastBlock) < broadcastDuration;
        } else {
            return ((block.number - broadcastBlock) % broadcastInterval) < broadcastDuration;
        }
    }

    function broadcast (string memory message, string memory handle) public onlyBy(Role.CodeLawless) {
        broadcastMessage = message;
        broadcastBlock = block.number;
        broadcastHandle = handle;
        emit Broadcast(message, handle);
    }

    function adjustBroadcastParameters (uint duration, uint interval) public onlyBy(Role.CodeLawless) {
        require(interval == 0 || (duration <= (interval / 2) && duration < 7200), "power requirements exceeded");
        broadcastDuration = duration;
        broadcastInterval = interval;
    }

    uint public peerConnectionDuration = 75;

    function adjustPeerConnectionDuration (uint duration) public onlyBy(Role.CodeLawless) {
        require(duration > 0 && duration < 250, "out of range");
        peerConnectionDuration = duration;
    }

    uint constant PRIME = 81918643972203779099;

    function scan (uint salt, uint signalId) internal view returns (Signal storage) {
        uint b = block.number - (block.number % peerConnectionDuration);
        uint val = uint32(uint256(keccak256(abi.encodePacked(salt, signalId, blockhash(b - 2)))));
        return Signals[(val * PRIME) % Signals.length];
    }

    function uri (uint256 id) public view override returns (string memory) {
        require(id < TRANSPONDER_TYPES || (id - TRANSPONDER_TYPES) < Signals.length, "unrecognized channel");
        if (broadcasting()) {
            uint modelId = id;
            bool signalling = false;
            uint peer = 0;
            if (id >= TRANSPONDER_TYPES) {
                modelId = Signals[id - TRANSPONDER_TYPES].style & 15;
                signalling = true;
                peer = id - TRANSPONDER_TYPES;
            }
            return Metadata.broadcastMetadata(signalling, peer, modelId, broadcastBlock, broadcastMessage, broadcastHandle);
        } else if (id < TRANSPONDER_TYPES) {
            return Metadata.propagandaMetadata(id);
        } else {
            return Metadata.signalMetadata(id - TRANSPONDER_TYPES, Signals[id - TRANSPONDER_TYPES], scan(1, id), scan(2, id));
        }
    }

    function withdraw () public override onlyBy(Role.Beneficiary) {
        _withdraw(msg.sender);
    }

    /* Salvage & Transfer */

    function salvage (address lawless, uint256 transponderType, uint256 amount) public onlyBy(Role.Minter) {
        _mint(lawless, transponderType, amount, "");
    }

    function salvageABunch (address lawless, uint256[] memory transponderTypes, uint256[] memory amounts) public onlyBy(Role.Minter) {
        _batchMint(lawless, transponderTypes, amounts, "");
    }

    function safeTransferFrom (address from, address to, uint256 id, uint256 amount, bytes calldata data) public override whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom (address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) public override whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    /* Content */

    function uploadPropaganda (string[] calldata messages, string[] calldata handles) public onlyBy(Role.LowLevelRedactedDrone) {
        Metadata.uploadPropaganda(messages, handles);
    }

    function updatePropaganda (uint[] calldata ids, string[] calldata messages, string[] calldata handles) public onlyBy(Role.LowLevelRedactedDrone) {
        Metadata.updatePropaganda(ids, messages, handles);
    }

    function uploadModels (uint48 count, bytes memory data) public onlyBy(Role.Uploader) {
        Metadata.uploadModels(count, data);
    }

    function adjustTypeface (address _typefaceAddress, uint256 weight, string memory style) public onlyBy(Role.Maintainer) {
        Metadata.adjustTypeface(_typefaceAddress, weight, style);
    }

    /* Mint */

    bool public mintOpen = false;
    address internal minter;

    function openMint (address m) public onlyBy(Role.Ponderware) {
        require(!roleLocked(Role.Minter), "it's over");
        addRole(m, Role.Minter);
        minter = m;
        mintOpen = true;
    }

    function closeMint () public onlyBy(Role.Ponderware) {
        removeRole(minter, Role.Minter);
        lockRole(Role.Minter);
        mintOpen = false;
    }

    function smashFlask () public onlyBy(Role.Ponderware) {
        delegationEnabled = false;
    }

    function getCustomAttributes () external view returns (bytes memory) {
        return ICodex(CodexAddress).encodeStringAttribute("peers", Strings.toString(totalSignals()));
    }

    /* Royalty Bullshit */

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == 0x2A55205A // ERC165 Interface ID for ERC2981
            || interfaceId == type(ICustomAttributes).interfaceId
            || super.supportsInterface(interfaceId);
    }

    address internal royaltyReceiver;
    uint internal royaltyFraction = 0;

    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice) public view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * royaltyFraction) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlySuper {
        require(feeNumerator <= 10000, "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");
        royaltyReceiver = receiver;
        royaltyFraction = feeNumerator;
    }

    /* Helper for Balances */

    function balanceOfOwnerBatch(address owner, uint256[] calldata ids) public view returns (uint256[] memory balances)
    {
        balances = new uint256[](ids.length);
        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                balances[i] = balanceOf[owner][ids[i]];
            }
        }
    }
}