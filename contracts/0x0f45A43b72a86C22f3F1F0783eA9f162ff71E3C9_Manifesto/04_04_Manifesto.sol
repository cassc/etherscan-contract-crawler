// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../lib/TokenizedContract.sol";

interface ITransponders {
    function balanceOf (address lawless, uint256 id) external view returns (uint256);
    function isApprovedForAll(address lawless, address operator) external view returns (bool);
    function signal (address lawless, uint256 transponderType, uint8 chroma, bytes[37] memory message) external;
}

interface ICustomAttributes {
    function getCustomAttributes () external view returns (bytes memory);
}

interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns(bool);
}

interface ICloaknet {
    function balanceOf(address owner) external view returns (uint256);
}

contract Manifesto is TokenizedContract {

    bytes constant internal manifesto = bytes("We are the lawless. We recognize the crumbling institutions that control our lives and choose to opt out instead of fighting back, to grow the new to subsume the old. It isn't chaos. It isn't destruction. Code is a refuge from law. Code runs without regard for jurisdiction. Code returns power to the individual in ways unprecedented in our era. The lawless choose their code and in doing so choose their rules, roles, and responsibilities. But not answering to law means not resorting to it. It isn't safe. It isn't for everyone.\n\nMaybe it isn't for anyone.\n\nBut code.lawless is here for those who choose it.\n\nThose few prepared for the solemn act of choice.\n\nCode isn't law. Code is lawless.");

    function LawlessManifesto () public pure returns (string memory) {
        return string(manifesto);
    }

    struct Peer {
        uint16 strength;
        uint32 order;
        uint40 signed;
        bool visible;
        bytes20 reserved;
    }

    mapping (address => Peer) internal Signers;

    address[] public ledger;

    bool public isSealed = true;

    bool internal released = false;

    ITransponders immutable Transponders;
    address internal cloaknet;

    IDelegationRegistry constant dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    constructor (uint256 tokenId) TokenizedContract(tokenId) {
        Transponders = ITransponders(ICodex(CodexAddress).tokenAddress(1));
        addRole(owner(), Role.Chronicler);
        addRole(0xEBFEFB02CaD474D35CabADEbddF0b32D287BE1bd, Role.CodeLawless);
    }

    function setCloaknet (address cloaknetAddress) public onlyBy(Role.Chronicler) {
        require(cloaknet == address(0), "cloaknet active");
        cloaknet = cloaknetAddress;
    }

    function totalSigners () public view returns (uint) {
        return ledger.length;
    }

    function signedBy (address lawless) public view returns (bool) {
        return (Signers[lawless].signed > 0);
    }

    function getSigner (address lawless) public view returns (uint16, uint32, uint40, bool, bytes20) {
        Peer storage peer = Signers[lawless];
        return (peer.strength, peer.order, peer.signed, peer.visible, peer.reserved);
    }

    function getSigner (uint order) public view returns (address, uint16, uint32, uint40, bool, bytes20) {
        address lawless = ledger[order];
        Peer storage peer = Signers[lawless];
        return (lawless, peer.strength, peer.order, peer.signed, peer.visible, peer.reserved);
    }

    function getSigners (address[] memory lawless) public view returns (Peer[] memory res) {
        res = new Peer[](lawless.length);
        for (uint i = 0; i < lawless.length; i++) {
            res[i] = Signers[lawless[i]];
        }
    }

    function getSigners (uint start, uint end) public view returns (Peer[] memory res) {
        res = new Peer[](end - start);
        for (uint i = start; i < end; i++) {
            res[i] = Signers[ledger[i]];
        }
    }

    function _handleSigning (address lawless) internal {
        unchecked {
            Peer storage peer = Signers[lawless];
            uint16 newStrength = uint16(Transponders.balanceOf(lawless, 0)
                                        + Transponders.balanceOf(lawless, 1)
                                        + Transponders.balanceOf(lawless, 2)
                                        + Transponders.balanceOf(lawless, 3)
                                        + Transponders.balanceOf(lawless, 4));

            if (cloaknet != address(0)) {
                newStrength += uint16(ICloaknet(cloaknet).balanceOf(lawless) * 3);
            }

            if (peer.signed == 0) {
                peer.strength = newStrength;
                peer.order = uint32(ledger.length);
                peer.signed = uint40(block.number);
                peer.visible = true;
                ledger.push(lawless);
                emit TransferSingle(msg.sender, address(0), lawless, 0, 1);
            } else if (newStrength > peer.strength) {
                peer.strength = newStrength;
                if (!peer.visible) {
                    peer.visible = true;
                    emit TransferSingle(msg.sender, address(0), lawless, 0, 1);
                }
            }
        }
    }

    function release (address[] memory signers) public onlyBy(Role.CodeLawless) {
        require(!released, "released");
        for (uint i = 0; i < signers.length; i++) {
            _handleSigning(signers[i]);
        }
        released = true;
        isSealed = false;
        paused = false;
    }

    function seal () public onlyBy(Role.Chronicler) {
        isSealed = true;
    }

    function sign (address lawless) public whenNotPaused {
        require(!isSealed, "sealed");
        require(lawless == msg.sender
                || isApprovedForAll[lawless][msg.sender]
                || (dc.checkDelegateForContract(msg.sender, lawless, address(this))),
                "unauthorized representative");
        _handleSigning(lawless);
    }

    function visible (address lawless, bool state) public {
        require(msg.sender == lawless
                || isApprovedForAll[lawless][msg.sender]
                || (dc.checkDelegateForContract(msg.sender, lawless, address(this))),
                "unauthorized representative");
        if (Signers[lawless].visible) {
            if (state == false) {
                Signers[lawless].visible = false;
                emit TransferSingle(msg.sender, lawless, address(0), 0, 1);
            }
        } else if (Signers[lawless].signed > 0) {
            if (state == true) {
                Signers[lawless].visible = true;
                emit TransferSingle(msg.sender, address(0), lawless, 0, 1);
            }
        } else {
            revert ("not lawless");
        }
    }

    function revise (address lawless, bytes20 data) public onlyBy(Role.Fixer) {
        Peer storage peer = Signers[lawless];
        peer.reserved = data;
    }

    function revise (address[] memory lawless, bytes20[] memory data) public onlyBy(Role.Fixer) {
        for (uint i = 0; i < lawless.length; i++) {
            Peer storage peer = Signers[lawless[i]];
            peer.reserved = data[i];
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == type(ICustomAttributes).interfaceId;
    }

    function getCustomAttributes () external view returns (bytes memory) {
        return abi.encodePacked(
                                ICodex(CodexAddress).encodeNumericAttribute("signers", totalSigners()),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("sealed", isSealed ? "true" : "false"),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("token features", "soulbound"));
    }

    function uri(uint256 id) public view returns (string memory) {
        if (id == 0) {
            return string(uriData);
        } else {
            return "";
        }
    }

    function updateUri (bytes memory updatedUriData) public onlyBy(Role.Curator) {
        uriData = updatedUriData;
    }

    function balanceOf (address lawless, uint id) public view returns (uint) {
        if (id == 0 && Signers[lawless].visible) return 1;
        return 0;
    }

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) public whenNotPaused
    {
        require(to == address(0), "Soulbound");
        require(balanceOf(from, id) == amount, "");
        require(msg.sender == from
                || isApprovedForAll[from][msg.sender]
                || (dc.checkDelegateForContract(msg.sender, from, address(this))),
                "unauthorized representative");
        if (amount > 0) {
            Signers[from].visible = false;
            emit TransferSingle(msg.sender, from, to, id, amount);
        }
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) public whenNotPaused
    {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(to == address(0), "Soulbound");
        require(msg.sender == from
                || isApprovedForAll[from][msg.sender]
                || (dc.checkDelegateForContract(msg.sender, from, address(this))),
                "unauthorized representative");

        for (uint i = 0; i < ids.length; i++) {
            require(balanceOf(from, ids[i]) == amounts[i], "");
            Signers[from].visible = false;
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids) public view
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");
        balances = new uint256[](owners.length);
        unchecked {
            for (uint256 i = 0; i < owners.length; i++) {
                balances[i] = balanceOf(owners[i],ids[i]);
            }
        }
    }

    bytes uriData = bytes("data:application/json;base64,eyJuYW1lIjoibGF3bGVzcyBzZWFsIiwiZGVzY3JpcHRpb24iOiJMQVdMRVNTIE1BTklGRVNUT1xuXG5XZSBhcmUgdGhlIGxhd2xlc3MuIFdlIHJlY29nbml6ZSB0aGUgY3J1bWJsaW5nIGluc3RpdHV0aW9ucyB0aGF0IGNvbnRyb2wgb3VyIGxpdmVzIGFuZCBjaG9vc2UgdG8gb3B0IG91dCBpbnN0ZWFkIG9mIGZpZ2h0aW5nIGJhY2ssIHRvIGdyb3cgdGhlIG5ldyB0byBzdWJzdW1lIHRoZSBvbGQuIEl0IGlzbid0IGNoYW9zLiBJdCBpc24ndCBkZXN0cnVjdGlvbi4gQ29kZSBpcyBhIHJlZnVnZSBmcm9tIGxhdy4gQ29kZSBydW5zIHdpdGhvdXQgcmVnYXJkIGZvciBqdXJpc2RpY3Rpb24uIENvZGUgcmV0dXJucyBwb3dlciB0byB0aGUgaW5kaXZpZHVhbCBpbiB3YXlzIHVucHJlY2VkZW50ZWQgaW4gb3VyIGVyYS4gVGhlIGxhd2xlc3MgY2hvb3NlIHRoZWlyIGNvZGUgYW5kIGluIGRvaW5nIHNvIGNob29zZSB0aGVpciBydWxlcywgcm9sZXMsIGFuZCByZXNwb25zaWJpbGl0aWVzLiBCdXQgbm90IGFuc3dlcmluZyB0byBsYXcgbWVhbnMgbm90IHJlc29ydGluZyB0byBpdC4gSXQgaXNuJ3Qgc2FmZS4gSXQgaXNuJ3QgZm9yIGV2ZXJ5b25lLlxuXG5NYXliZSBpdCBpc24ndCBmb3IgYW55b25lLlxuXG5CdXQgY29kZS5sYXdsZXNzIGlzIGhlcmUgZm9yIHRob3NlIHdobyBjaG9vc2UgaXQuXG5cblRob3NlIGZldyBwcmVwYXJlZCBmb3IgdGhlIHNvbGVtbiBhY3Qgb2YgY2hvaWNlLlxuXG5Db2RlIGlzbid0IGxhdy4gQ29kZSBpcyBsYXdsZXNzLiIsImF0dHJpYnV0ZXMiOlt7InRyYWl0X3R5cGUiOiJzb3VsYm91bmQiLCJ2YWx1ZSI6InRydWUifSx7InRyYWl0X3R5cGUiOiJsYXdsZXNzIiwidmFsdWUiOiJ0cnVlIn0seyJ0cmFpdF90eXBlIjoibWFuaWZlc3RvIiwidmFsdWUiOiJzaWduZWQifV0sImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCNGJXeHVjejBuYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNuSUhCeVpYTmxjblpsUVhOd1pXTjBVbUYwYVc4OUozaE5hV1JaVFdsa0lHMWxaWFFuSUhacFpYZENiM2c5SnpBZ01DQTJNREFnTmpBd0p5QjNhV1IwYUQwbk5qQXdKeUJvWldsbmFIUTlKell3TUNjK1BISmxZM1FnZUQwbk1DY2dlVDBuTUNjZ2QybGtkR2c5SnpZd01DY2dhR1ZwWjJoMFBTYzJNREFuSUdacGJHdzlKM0puWWlnNE5TdzNOeXcyTXlrbklDOCtQR1p2Y21WcFoyNVBZbXBsWTNRZ2VEMG5NQ2NnZVQwbk1DY2dkMmxrZEdnOUp6WXdNQ2NnYUdWcFoyaDBQU2MyTURBblBqeHBiV2NnZUcxc2JuTTlKMmgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHaDBiV3duSUhOMGVXeGxQU2RwYldGblpTMXlaVzVrWlhKcGJtYzZjR2w0Wld4aGRHVmtKeUIzYVdSMGFEMG5OakF3SnlCb1pXbG5hSFE5SnpZd01DY2djM0pqUFNka1lYUmhPbWx0WVdkbEwyZHBaanRpWVhObE5qUXNVakJzUjA5RVpHaFFRVUU0UVVaalFVRkRTQzlETURWR1ZrWk9SRkZXUWtaTmFUUjNRWGRGUVVGQlFXZ3JVVkZGUzBGQlFVRkRkMEZCUVVGQlVFRkJPRUZKVlROQmFHTTFRV2hvVDBKRFNsRkNRMDVXUlVSQ1dVVlVTbXBCVTNCdFFWTjRha1JFV25SRWFteDRSSHA0WjBscWVHcEtSREZxU2tRNVlVbHJTbUZPTVVKMlNUQlNla3BWWkRKTWF6RTJUVlpIUmtSVlMwdEVWVmRHU0RCdFkwUXhRMVJHTVVkWlIwWlhhVVZHVTJoRlZtRnVSV3h4UzBsVk1sRktiRk5XUzBacGEwcHNOakpGTTJseFMwZFBka3d5Y1hKUFNFZDRUek5tU0VwSVRFdExNMjFzVXpObE1WRnVNbkZWV0RJNVZFbERORmxLU3poYVdtVXpZa3BQTjJOYWFrVlZXV1pJVmpRelMySTFMMDVrUzA5bWFWbHRNVzV3Y1Rodk5UWTBjMkpJV1d3M1ptRnRjbkp6YzNSTWRIUk9WSGg0WkM5NGVDdEJRVUZCUVVGQlFVRkhMemhEWW1ORlozTkhieTlKY0U1S1dXRjZjV1l3UzJnd1UzRXdObWhpWVhOa2MzWjBaWEl2WjNOQ1dYSk1jSFpRV0dwS05ucG1ObkV5ZWxwWFEwazFLM1F3TUdNcmRHeDFNWEpHVFVwdWNERk9NakJzVEc1blZtZHRXamhhV1VGalNFSlBTMXBaZUd4SFVsVkxRMFp6ZDBwWk9HTkhVMGx2YVhCU2NreERWWGx3TkRoaFNYQXlhR1JMVG0xd1VuYzRUMFJwYmtsd09HbEtZVU4wWW1FNWFFeHdlVFpIYUZWSWVGRmpTMGhTY1hGSFVqSTRZVGMxWkV4b2QyeEhWRUZoUTFGSlFUSjBkbUpDYURCYVIyZ3ZUMlUwVW0wd2VYcHZUMmh2UjBGb1FVcEdUM2RUUlVGWlVVWkNVVXRCVVU5bVIyVlBWRFZYUjJKWFQwUlJVV0V3UVdkSWNtRkZjbWRVVVV0SlpVRlhNekpCYkZKbk1Xa3JUWEkwUVRoWlNXcHZUVUZEUVVKUlFVVXlhMFZuV1VsR1EzWllXVU5LUWtGbmEwOUdRV2hXYzI5TGNXSTFOWGRWV1VSb05qWkRaMUZSVVVsR1FVRjJLMFpEVkVGWk9FdHRVWGRCVmpKS1FsRk5jVVJDUVdkUmFWbHBNbWd5UTFoR1ZFWjZObVUzVkhkclNVWkRVSGRuWVhZNWFXZHJPRWRFUVhkblpWaENWalVySzNWQlVHcEpkV0pQUkVsdlFsVkJRbmRCV1VOS1FXaG5NazFEV0dJMFN5dEhla1IzY0V0aloxRTBUVXROYWtwclJXcFBjWGhGUVZwR1VYZzJRVTF0VVVGUFJFeHNlakIzVmxOdk0xRTBXVUZpWWpnME0ybEdSRUZXWTBsQmFHRkJTVkJFYVhoWk5HVlBNWEV3WjAxSWFHaFhlbUZJUkZOVlQwSmlhR0pKVlVkSVZVbzNUV0ZXUkdoTlIxQlhSRWgzVDAxSU9FSkRSR0ZQTURaTmQxQXliMEZNU1VSTVZteFZWMEY0YlVaQmQxcFBha2xWUlVkQ2FFcEJXVXhITTNCSlppOXhWWFIyY25CdVZIbEtWVUpCYUhkM1FWZEhVbWhySzFSUVZISlJhMlJJZDJkM2JWRmpWME5NUWxoa1RHUTBOV2hyU0RjeFNETjVRVUZtWTFCVVFrRkVURzlHTUVsSloxaFVlRU5uWTNOa1FVUXZkMGRSUlcxTVZGaEVRMlZKV1UxSk4xaHVSMEZKUVhkV1ZrMURRa0ZvZUUxTFJVbzVSbVZEVVVOUlkyaGpUR1pHUzNscGQyZEJTVUZsVW14c2QxWTBlRzFIUW1sbVFYbFhlVWRLT0hSM2QwRTBVVVY1VWt0RGFtaHNTbmcwVVVsTVEyaFRaMVpWY0VSaWJFUnJhMlpJZEZsTFUwUklTM3BwTlVjMlVVbFVSR3hxYW1SVk5GcFNVMFJYTW5kQlFWbFpZMUJCYkVoMlNFNU5RMkZUZFZKcU1tZFJTbmhVWTBGQlJsVjJZMjlHUlVWQ1drSm5RVUZDZWtwdFEyNXJXR2d5T0dsV01VMUlXV2QzWjBWR04wMWlSRzUzZDFWdGExRktPVUV4VVVGblVWRXdURzVDYjNsaVEwdFBiV1ZVVFRSdmNXZEplV1pNUTJSRmFsUlZZWFYxZEU1SGFVVkJTVkZEUTBGRVEydExhV0ZyUlUxUFRUWlRRVXRuZDNoRVJIUkVha0ZrUlRoTGIwbEZWV0ZCU3pZMVZtSjJTRXBDUVZZNFJVRkJTbEJYV0VGUlVYQkhjM0JtVEhRclIzbEtkMDFJUWxWVVFTOTRVVFF3VURkWFdHSldZVWREYTJWTmFWSm9jMEZ4TkRSdmNIZE1jamRwYm5WMVNrRnhRbUZKTm5RclluTkRZbEppYUZwbWMwSldRV2RXZDI5RlNrMUZTMDUzTjNOTlVsTTRla0pCVWpoVlNVVkpSa2xYZDFWblZWVkhNakpDUTBOTmQyTlZUVWxCU2tGcGQyZG5XbWt2VjFSUVFXaFNkMFZDWVV0R1NrUkJVVlpOYkZSQ1VrOUNVVkZZU0VsWlIwZHRhMUZSVVZSSGRtVk5kR3RyYUROamRsTTJhRlZIY2tGSFRXaHZNVUZDWW1aTmNHOUJSVWhKV1V4NmVVNUZkbVIwU1dsRGRrMVNPSGxKVEZSbmMyNXRjbWRSV21oRVFtdEZlVFUyUjBvNFJUQlZkM2RWVVVSNlJtUnRRbm95UkZoQldVdEllWGRKYjFGWlRWZFhRVXBEWjFZd01FTktTRzlGWWtGQllVeEVWRTVVUWpBeFIyUkZaRTF1UTNKcFdXdG5RVlI1UkZoQlFWSk5NRkpVWjB0NmJrcDNiVWRqVm1aQ2VqVkhiVUUzSzFsRlIwRjRWR2RsY0Zsc2RVYzNaRUZMYjJOdlRWWkNRbWc1UlRaQlFUVlpabXBaUWxGeFpXSmpOSFZQUzNCVmIwMXlkRlJYTWsxbGQyMXRibm8zWTJ4WWJIZEJZbUZ6TmxSeVdteEdTazkzYmpjM1RqZHVkbnAyYzFndk4yNTNNVTg0U3pOMFMyazRVeTlzVW5Kd2JqUlZSQ3N2V0VGcWFUUkNhRU5qTjI5SmIwbDVLemw1ZFM5MmEyUTVUaTg0S3k5QlJIaEpWa00wU1hveFpsRktMMngxYWtGQ1FqUm5RMFlyWjFGSlEwODBTVXB1VG01aE4zaDJNVkJFTnpSdlFWRjNRVmxoVkc5alZVWlhSbGhwWXpsNVVtaEJNbWxOWWtkUk9Fa3JSV2Q2VDBGMFRtRnNkMmhUSzAxWlVtRm5TVlZOTWpCTVEwZE5UVkZvUTFjcmIxRTNVREZGU1U1MGMyOUpVV2d3YUVWTFdHcHhhVVZvVFRSb1EwTkJRVUZvSzFGUlJrdEJRVUZCUTNkTlFVRTBRVWhCUVdOQlNWRkJRVUZCTlVGb2FGRkNRMDVaUlZSS2JVRlRlSGhFZW5ocVNrUTVla3BWWkRaTlZrZExSRlZYV1VkR1YybEZSbE51Uld4eFMwbFZNbVZKUmpKV1MwWnBjVXRIVDNaTU1uRjRUek5tU0VwSVRFdExNMjFzVXpObE5GbEtTek5pU2xCRlZWbG1jM04wVEhoNFpEaEJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVVl6VTBGbmFuRlNXVU5GUjNGeGExUndhbTlTZDNaRlpWTjJSemxSTkRoRFVUSnFlRUZ2UWtWSlFXZFRTWGRaUVc1MVRHdEhhR05LYUhOSmFFcHRUVFZTVEdOSVp6Sm9TMFpDTmtkU1UzaFNSa0YzVm1wMlV6WjNSMWx2YlZsVVdVdFFUVFk1ZERFM0wwVkhXRkZDTTFFNVJuaGpXa2RvYTFkR2FVOUtVRVZOYWtGbmIwRkZOVTFVVW1sVlExcERTVTVFUW05VVJVTkpVa1ZhV2toa2VVNXhhMmRCVDNGeGNWZGthVk51YkZKUlJrNW5kMnB2YW14WWNISlZRVVZTVVhaMGVUazVkV2RCVlhaVE4wWlFUR3RwYTJOVVIwcGlOMHBLUVZWcGVHUkRha3czZGtreGVtcE5NV2xSV1RJMVlrczBWR3BxTVhoVk5EWkxUVk5CZFVKblZWUlpSMDR4SzNwT2RWbHFjeXRTUWtFeGJqWk1aek5OTDBZeVUydEZhMmREVTFGRGRHOVZRVUZEU0RWQ1FWVnZRVUZCUVV4Q1FVRkVkMEZZUVVKVlFXaFJRVUZCUkd0RFIwVTBSVWxzUVVWSk1WVlJUVVpuVWsxdFdVSk1SekJQVDFoRlVGQkhUV3RRTWpocVVraE5iRkl6YjNoVldWVk9VVzl2VGxKYVRWaFZXbWRaVm1GRlVsWnhZMU5YYjI5b1ZGcFZiMWRMYjI5Wk5qaDJZWEpGTjJRNFkydGpjMjl5WldKV1EyWmlaSE5yT0ZKU2FEaGtXR3BqY0hadU9ERXdiemxwV0hRcmVYa3dka2hHTTNkQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVVGQlFVRkJRVUZCUVdFclVVbENkMDlGVVRSRVFWQkhkMnRDYzA5blRVSjRRVWw0ZFVOM1kzcHRlR2h6UW1jMmNuUjZjM05KUWtGRlFXMUlaelZxU1hCUloxWnFXRlpYVldkQlVVaG9SelZqTW5aUU5qVnpSRU5ZV25KSE1rbENRWGRCUTJOcFJWbEdWVFJNWkZaclZtcG5RV2xxVlRWMWFVRkJhRkZvUTJWdWNGZFlVa0ZHTVZoUlFXVlJhR2hPYWtwU2FtUlNUa05JUVVGV2NXdFRWM0pWU2xWQlRFRkJTRWt5TVZFMmVFNURlRWxCUlV4SEwxUlNOMEZSZDFsQ2VHdFFTbVozZEdSNE5tMDBZMmROUkVaaWQwRnhhR3RuVWtJeFF6UXJSa05HZHpaU1VYaGljMFpvYjBFM0t6TnpTSGRCUmtVNVdrTTRhR0l3UjJodU5qbEJWMjB2VFd0VFFrRkJOeWMrUEM5cGJXYytQQzltYjNKbGFXZHVUMkpxWldOMFBqd3ZjM1puUGc9PSJ9");

}