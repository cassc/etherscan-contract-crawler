// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../lib/TokenizedContract.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IDelegationRegistry {
    function checkDelegateForContract (address delegate, address vault, address contract_) external view returns(bool);
    function checkDelegateForToken (address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);

}

interface ICustomAttributes {
    function getCustomAttributes () external view returns (bytes memory);
}

interface ICloakNetMetadata {
    function signalMetadata (uint peer, Signal memory local, Signal memory peer1, Signal memory peer2) external view returns (string memory);
    function adjustTypeface (address _typefaceAddress, uint256 weight, string memory style) external;
    function setB64EncodeURI (bool active) external;
}

interface ITransponders {
    function balanceOf (address lawless, uint256 id) external view returns (uint256);
}

struct Signal {
    uint16 tokenId;
    uint8 style;
    uint32 startBlock;
    address sender;
    uint40 message1;
    uint256 message2;
}

/*
 * @title CloakNet
 * @author Ponderware Ltd
 * @dev "Burns" ERC-1155 Transponders into ERC-721 Signalling Transponders
 */
contract CloakNet is TokenizedContract, IERC721Enumerable {

    string public name = "cloaknet";
    string public symbol = unicode"📻";

    /* */

    ICloakNetMetadata Metadata;

    address immutable TranspondersAddress;

    constructor (uint256 tokenId) TokenizedContract(tokenId) {
        TranspondersAddress = ICodex(CodexAddress).tokenAddress(1);
        addRole(owner(), Role.Uploader);
        addRole(owner(), Role.Beneficiary);
        addRole(owner(), Role.Censor);
        addRole(owner(), Role.Jammer);
        addRole(owner(), Role.Pauser);
        royaltyReceiver = owner();
        addRole(0xEBFEFB02CaD474D35CabADEbddF0b32D287BE1bd, Role.CodeLawless);
    }

    bool internal initialized = false;

    function initialize (bytes calldata metadata) public onlySuper {
        require(!initialized, "initialized");
        initialized = true;
        Metadata = ICloakNetMetadata(Create2.deploy(0, 0, abi.encodePacked(metadata, abi.encode(address(this), CodexAddress))));
    }

    IDelegationRegistry constant dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    bool public delegationEnabled = true;

    bool public jammed = true;

    function jam (bool value) public onlyBy(Role.Jammer) {
        jammed = value;
    }

    uint constant validChars = 10633823807823001964213349086429970432; // space ! ' - . 0-9 ? a-z

    function parseData (bytes memory data) internal pure returns (uint chroma, uint256 message1, uint256 message2) {
        chroma = uint8(data[0]);
        require (chroma < 5, "incompatible power supply");
        require (data.length <= 38, "data overload");
        for (uint i = 1; i < data.length; ++i) {
            uint b = uint8(data[i]);
            require(((1 << b) & validChars) > 0, "failed to decode signal");
            if (i < 6) {
                message1 <<= 8;
                message1 += b;
            } else {
                message2 <<= 8;
                message2 += b;
            }
        }
        if (data.length <= 6) {
            message1 <<= ((5 - (data.length - 1)) * 8);
        } else {
            message2 <<= ((32 - (data.length - 6)) * 8);
        }
    }

    bytes4 constant onERC1155ReceivedSelector = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));

    function onERC1155Received(address /*operator*/, address from, uint256 id, uint256 amount, bytes memory data) public returns (bytes4) {
        require(msg.sender == TranspondersAddress, "unrecognized transponder");
        require(!jammed, "jammed");
        require(amount == 1, "too much interference");
        (uint chroma, uint256 message1, uint256 message2) = parseData(data);
        _handleMint(from, id, chroma, message1, message2);
        return onERC1155ReceivedSelector;
    }

    function bootstrapCloaknet(address[] calldata seeders, uint[] calldata models, bytes[] memory data) public onlyBy(Role.CodeLawless) {
        require(seeders.length == 6, "invalid bootstrap group");
        require(totalSupply == 0, "cloaknet live");
        jammed = false;
        paused = false;
        for (uint i = 0; i < seeders.length; i++) {
            (uint chroma, uint256 message1, uint256 message2) = parseData(data[i]);
            _handleMint(seeders[i], models[i], chroma, message1, message2);
        }
    }

    uint public priceOfIndecisionAndRequiredMaterials = 0.1 ether;

    function reevaluate (uint signalId, bytes memory data) public payable {
        address lawless = ownerOf(signalId);
        require (ownerOf(signalId) == lawless
                 && (lawless == msg.sender
                     || isApprovedForAll(lawless, msg.sender)
                     || (delegationEnabled
                         && (dc.checkDelegateForContract(msg.sender, lawless, address(this))
                             || dc.checkDelegateForToken(msg.sender, lawless, address(this), signalId)))),
                 "unauthorized access detected");

        require(msg.value >= priceOfIndecisionAndRequiredMaterials, "parts aren't free");
        (uint chroma, uint256 message1, uint256 message2) = parseData(data);

        Signal storage s = SignalsByOwner[lawless][OwnerTokenIndex[signalId]];
        s.message1 = uint40(message1);
        s.message2 = message2;
        s.style = uint8((chroma << 4) + (s.style & 15));
        s.sender = lawless;
    }

    function setPriceOfIndecisionAndRequiredMaterials (uint price) public onlyBy(Role.Fixer) {
        priceOfIndecisionAndRequiredMaterials = price;
    }

    function redact (uint signalId, bytes memory data) public onlyBy(Role.Censor) {
        address lawless = ownerOf(signalId);
        Signal storage s = SignalsByOwner[lawless][OwnerTokenIndex[signalId]];
        (, uint256 message1, uint256 message2) = parseData(data);
        s.message1 = uint40(message1);
        s.message2 = message2;
        s.style |= 128;
    }

    function setB64EncodeURI (bool value) public onlyBy(Role.Fixer) {
        Metadata.setB64EncodeURI(value);
    }

    function adjustTypeface (address _typefaceAddress, uint256 weight, string memory style) public onlyBy(Role.Maintainer) {
        Metadata.adjustTypeface(_typefaceAddress, weight, style);
    }

    uint public peerConnectionDuration = 75;

    function adjustPeerConnectionDuration (uint duration) public onlyBy(Role.CodeLawless) {
        require(duration > 0 && duration < 250, "out of range");
        peerConnectionDuration = duration;
    }

    uint constant PRIME = 81918643972203779099;

    function scan (uint salt, uint signalId) internal view returns (Signal memory) {
        uint b = block.number - (block.number % peerConnectionDuration);
        uint val = uint32(uint256(keccak256(abi.encodePacked(salt, signalId, blockhash(b - 2)))));
        address lawless = Owners[(val * PRIME) % totalSupply];
        val = uint32(uint256(keccak256(abi.encodePacked(lawless, signalId, blockhash(b - 2)))));
        return SignalsByOwner[lawless][(val * PRIME) % SignalsByOwner[lawless].length];
    }

    function tokenURI (uint256 tokenId) public view returns (string memory) {
        require(tokenExists(tokenId), "No signal");
        address lawless = Owners[tokenId];
        uint index = OwnerTokenIndex[tokenId];
        return Metadata.signalMetadata(tokenId, SignalsByOwner[lawless][index], scan(1, tokenId), scan(2, tokenId));
    }

    function smashFlask () public onlyBy(Role.Ponderware) {
        delegationEnabled = false;
    }

    /* Custom Attributes */

    uint internal blocksPerMinute = 5;

    function setBPM (uint bpm) public onlyBy(Role.Curator) {
        require(bpm > 0, "invalid");
        blocksPerMinute = bpm;
    }

    function getCustomAttributes () external view returns (bytes memory) {
        string memory peerSwitchTime = string(abi.encodePacked(Strings.toString(peerConnectionDuration/blocksPerMinute), " min"));
        string memory netState = !initialized ? "pending" : jammed ? "jammed" : "available";
        string memory coveragePCT;
        uint coverage = totalSupply * 1000 / totalTransponders;
        bytes memory temp = bytes(Strings.toString(coverage));
        if (coverage < 10) {
            coveragePCT = string(abi.encodePacked("0.", temp, "%"));
        } else if (coverage < 100) {
            coveragePCT = string(abi.encodePacked(temp[0], ".", temp[1], "%"));
        } else if (coverage < 1000) {
            coveragePCT = string(abi.encodePacked(temp[0], temp[1], ".", temp[2], "%"));
        } else {
            coveragePCT = "100%";
        }

        return abi.encodePacked(ICodex(CodexAddress).encodeStringAttribute("peers", Strings.toString(totalSupply)),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("coverage", coveragePCT),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("peer dur.", peerSwitchTime),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("net state", netState),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("token type", "ERC-721"));
    }

    /* View Helper */

    function getSignal (uint256 signalId) public view returns (uint8 model, uint8 chroma, uint32 startBlock, address sender, bool redacted, string memory message) {
        require(tokenExists(signalId), "signal not found");
        address lawless = Owners[signalId];
        Signal storage s = SignalsByOwner[lawless][OwnerTokenIndex[signalId]];
        model = s.style & 7;
        chroma = (s.style >> 4) & 7;
        redacted = (s.style >> 7) == 1;
        startBlock = s.startBlock;
        sender = s.sender;
        bytes5 m1 = bytes5(s.message1);
        bytes32 m2 = bytes32(s.message2);
        uint messageLength = 0;
        for (; messageLength < 37; messageLength++) {
            if (messageLength < 5) {
                if (uint8(m1[messageLength]) == 0) break;
            } else if (uint8(m2[messageLength - 5]) == 0) break;
        }
        bytes memory temp = new bytes(messageLength);
        for (uint i = 0; i < messageLength; i++) {
            if (i < 5) temp[i] = m1[i];
            else temp[i] = m2[i - 5];
        }
        message = string(temp);
    }

    /* Strength */

    function signalStrength (address lawless) public view returns (uint) {
        return (ITransponders(TranspondersAddress).balanceOf(lawless, 0)
                + ITransponders(TranspondersAddress).balanceOf(lawless, 1)
                + ITransponders(TranspondersAddress).balanceOf(lawless, 2)
                + ITransponders(TranspondersAddress).balanceOf(lawless, 3)
                + ITransponders(TranspondersAddress).balanceOf(lawless, 4)
                + (balanceOf(lawless) * 3));
    }

    function signalStrength (uint signalId) public view returns (uint) {
        require(tokenExists(signalId), "failed to tune");
        return signalStrength(Owners[signalId]);
    }

    /* ERC-721 */

    uint256 internal constant totalTransponders = 20685 + 6; // 4176 + 3629 + 3574 + 3702 + 5606 + 6
    uint256 public totalSupply = 0;

    address[totalTransponders] private Owners;
    mapping (address => Signal[]) internal SignalsByOwner;
    uint16[totalTransponders] internal OwnerTokenIndex;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private TokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    function _transfer(address from,
                       address to,
                       uint256 tokenId) private whenNotPaused {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint16 valueIndex = OwnerTokenIndex[tokenId];
        // uint256 toDeleteIndex = valueIndex - 1;
        Signal memory signal = SignalsByOwner[from][valueIndex];
        uint256 lastIndex = SignalsByOwner[from].length - 1;
        if (lastIndex != valueIndex) {
            Signal memory lastSignal = SignalsByOwner[from][lastIndex];
            SignalsByOwner[from][valueIndex] = lastSignal;
            OwnerTokenIndex[lastSignal.tokenId] = valueIndex;
        }
        SignalsByOwner[from].pop();
        OwnerTokenIndex[tokenId] = uint16(SignalsByOwner[to].length);
        SignalsByOwner[to].push(signal);
        Owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _handleMint(address to, uint transponderType, uint chroma, uint256 message1, uint256 message2) internal {
        uint tokenId = totalSupply;
        totalSupply++;
        OwnerTokenIndex[tokenId] = uint16(SignalsByOwner[to].length);
        SignalsByOwner[to].push(Signal(uint16(tokenId), uint8((chroma << 4) + transponderType), uint32(block.number), to, uint40(message1), message2));
        Owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return (tokenId < totalSupply);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenExists(tokenId), "ERC721: Nonexistent token");
        return Owners[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return SignalsByOwner[owner].length;
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        if (msg.sender == CodexAddress) {
            return
                interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                interfaceId == type(ICustomAttributes).interfaceId;
        } else {
            return
                interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
                interfaceId == 0x780E9D63 || // ERC165 Interface ID for ERC721Enumerable
                interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
                interfaceId == 0x2A55205A || // ERC165 Interface ID for ERC2981
                interfaceId == type(ICustomAttributes).interfaceId;
        }
    }

    function _approve(address to, uint256 tokenId) internal {
        TokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public  {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
                msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not owner nor approved for all"
                );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenId < totalSupply, "ERC721: approved query for nonexistent token");
        return TokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    function setApprovalForAll(
                               address operator,
                               bool approved
                               ) external virtual {
        require(msg.sender != operator, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
        size := extcodesize(account)
                }
        return size > 0;
    }

    function _checkOnERC721Received(
                                    address from,
                                    address to,
                                    uint256 tokenId,
                                    bytes memory _data
                                    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                            }
                }
            }
        } else {
            return true;
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(tokenId < totalSupply, "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(
                          address from,
                          address to,
                          uint256 tokenId
                          ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
                              address from,
                              address to,
                              uint256 tokenId
                              ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
                              address from,
                              address to,
                              uint256 tokenId,
                              bytes memory _data
                              ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(
                           address from,
                           address to,
                           uint256 tokenId,
                           bytes memory _data
                           ) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /* Enumerable */

    function tokenByIndex(uint256 tokenId) public view returns (uint256) {
        require(tokenExists(tokenId), "Nonexistent Token");
        return tokenId;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return SignalsByOwner[owner][index].tokenId;
    }

    /* Royalty Bullshit */

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

}