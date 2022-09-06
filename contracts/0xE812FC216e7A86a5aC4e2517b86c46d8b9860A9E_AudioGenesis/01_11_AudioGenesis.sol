// SPDX-License-Identifier: None
// AudioGenesis Contracts v0.0.1t
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './ERC721A.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IAudioGenesisRenderer {
    function constructTokenURI(
        string memory websocket,
        string memory jsonRPC,
        address[] memory customListeners,
        string memory customVisualizer,
        string memory customVisualizerName,
        uint256 tokenData
    ) external view returns (string memory);
}

contract AudioGenesis is ERC2981, ERC721A, Ownable {
    event URI(string value, uint256 id);

    IAudioGenesisRenderer constant renderer = IAudioGenesisRenderer(address(0xEE4B4275Fa10E51C64081143282b4933d3c6b788));
    
    uint256 constant ALLOWLIST  = 1 << 8;
    uint256 constant PUBLIC     = 2 << 8;
    uint256 constant MINTED     = 3 << 8;

    uint256 public luftDropReserve = 55;
    uint256 public constant maxSupply = 555;
    uint256 public constant pricePerMint = 0.1 ether;

    uint256 public mintStart = 1662228000;
    bytes32 public merkleRoot = bytes32(uint(0xf06cba1cd6a5081e50548eaee72700c4f3d4ac4fd836a3004826e66c55bc4cd7));

    string public defaultWebsocketAPI = "wss://main-light.eth.linkpool.io/ws";
    string public defaultJSONAPI = "https://main-light.eth.linkpool.io/";

    mapping(address => uint256) private AllowedTokensMinted;

    mapping(uint256 => bool) private tokenOverridesEndpoints;
    mapping(uint256 => string) public tokenToWebsocketEndpoint;
    mapping(uint256 => string) public tokenToJSONEndpoint;
    mapping(uint256 => uint256) public tokenIdToData;
    mapping(uint256 => address[]) public tokenIdToCustomListeners;
    mapping(uint256 => string) public tokenIdToCustomVisualizer;
    mapping(uint256 => string) public tokenIdToCustomVisualizerName;

    string private _contractURI = "data:application/json;base64,ewogICJuYW1lIjogIkF1ZGlvR2VuZXNpcyIsCiAgImRlc2NyaXB0aW9uIjogIkFuIGV4cGVyaW1lbnRhbCAxMDAlIG9uLWNoYWluIG11bHRpbWVkaWEgTkZUIHRoYXQgYXVkaW8tdmlzdWFsaXplcyB0aGUgb24tY2hhaW4gZXZlbnRzIGVtaXR0ZWQgYnkgTkZUIHRyYW5zZmVycyBhbmQgc2FsZXMuIiwKICAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQRDk0Yld3Z2RtVnljMmx2YmowaU1TNHdJaUJsYm1OdlpHbHVaejBpVlZSR0xUZ2lQejRLUEhOMlp5QnpkSGxzWlQwaVltRmphMmR5YjNWdVpDMWpiMnh2Y2pwaWJHRmpheUlnZG1sbGQwSnZlRDBpTUNBd0lERmxNeUF4WlRNaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJK0NqeHpkSGxzWlQ1MFpYaDBJSHNLWm1sc2JEb2dkMmhwZEdVN0NuTjBjbTlyWlRvZ2QyaHBkR1U3Q25OMGNtOXJaUzEzYVdSMGFEb2dOSEI0T3dwbWIyNTBMWE5wZW1VNklEaGxiVHNLWm05dWRDMW1ZVzFwYkhrNklDZERiM1Z5YVdWeUlFNWxkeWNzSUcxdmJtOXpjR0ZqWlRzS2ZRcHlaV04wTG5KbFkzUWdld3AzYVdSMGFEb2dNVEF4Y0hnN0NtaGxhV2RvZERvZ01UQXdNSEI0T3dwOVBDOXpkSGxzWlQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlHWnBiR3c5SWlNNFFqQXdNemdpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU5UQXdPelUxTURzMk1EQTdOalV3T3pZMU1EczJOVEE3TmpBd096WXdNRHMxTlRBN05UQXdPelV3TURzMU1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU1UQXdJaUJtYVd4c1BTSWpaakF3SWo0S1BHRnVhVzFoZEdVZ1lYUjBjbWxpZFhSbFRtRnRaVDBpZVNJZ1kyRnNZMDF2WkdVOUltUnBjMk55WlhSbElpQmtkWEk5SWpBdU5YTWlJSEpsY0dWaGRFTnZkVzUwUFNKcGJtUmxabWx1YVhSbElpQjJZV3gxWlhNOUlqUTFNRHMwTlRBN05UQXdPelV3TURzME5UQTdOREF3T3pRd01Ec3pOVEE3TXpVd096TTFNRHMwTURBN05EVXdJaTgrQ2p3dmNtVmpkRDRLUEhKbFkzUWdZMnhoYzNNOUluSmxZM1FpSUhnOUlqSXdNQ0lnWm1sc2JEMGlJMFpHT0VNd01DSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0kwTURBN05EQXdPek0xTURzek1EQTdNalV3T3pJMU1Ec3lOVEE3TXpBd096TXdNRHN6TlRBN016VXdPelF3TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0l6TURBaUlHWnBiR3c5SWlORVJFUTNNREFpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU5EQXdPelF3TURzek5UQTdNekF3T3pJeU1Ec3lNakE3TWpJd096TXdNRHN6TURBN016VXdPek0xTURzME1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU5EQXdJaUJtYVd4c1BTSWpNekJGUlRNd0lqNEtQR0Z1YVcxaGRHVWdZWFIwY21saWRYUmxUbUZ0WlQwaWVTSWdZMkZzWTAxdlpHVTlJbVJwYzJOeVpYUmxJaUJrZFhJOUlqQXVOWE1pSUhKbGNHVmhkRU52ZFc1MFBTSnBibVJsWm1sdWFYUmxJaUIyWVd4MVpYTTlJalExTURzME5UQTdOVEF3T3pVd01EczBOVEE3TkRBd096TTFNRHN6TlRBN016VXdPelF3TURzME1EQTdORFV3SWk4K0Nqd3ZjbVZqZEQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlIZzlJalV3TUNJZ1ptbHNiRDBpSXpZMlppSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0kyTURBN05qVXdPemN3TURzM05UQTdOelV3T3pjMU1EczNNREE3TmpBd096VTFNRHMxTlRBN05UVXdPell3TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0kyTURBaUlHWnBiR3c5SWlNMFFqQXdPRElpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU9EQXdPemd3TURzNE1EQTdPRFV3T3pnMU1EczRNREE3T0RBd096YzFNRHMzTlRBN056VXdPemd3TURzNE1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU56QXdJaUJtYVd4c1BTSWpPRUl6TXpaQklqNEtQR0Z1YVcxaGRHVWdZWFIwY21saWRYUmxUbUZ0WlQwaWVTSWdZMkZzWTAxdlpHVTlJbVJwYzJOeVpYUmxJaUJrZFhJOUlqQXVOWE1pSUhKbGNHVmhkRU52ZFc1MFBTSnBibVJsWm1sdWFYUmxJaUIyWVd4MVpYTTlJamt5TlRzNU1qVTdPVEkxT3pnM05UczROelU3T0RVd096ZzFNRHM0TlRBN09ESTFPemd5TlRzNE56VTdPVEkxSWk4K0Nqd3ZjbVZqZEQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlIZzlJamd3TUNJZ1ptbHNiRDBpSTJZek5pSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0k1T0RVN09UZzFPems0TlRzNU56VTdPVGN3T3prMk5UczVOalU3T1RZMU96azNNRHM1TnpVN09UZ3dPems0TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0k1TURBaUlHWnBiR3c5SWlObU1EQWlQZ284WVc1cGJXRjBaU0JoZEhSeWFXSjFkR1ZPWVcxbFBTSjVJaUJqWVd4alRXOWtaVDBpWkdselkzSmxkR1VpSUdSMWNqMGlNQzQxY3lJZ2NtVndaV0YwUTI5MWJuUTlJbWx1WkdWbWFXNXBkR1VpSUhaaGJIVmxjejBpT1RrMU96azVOVHM1T1RVN09UazFPems1TURzNU9UQTdPVGcxT3prNE5UczVPRFU3T1Rrd096azVNRHM1T1RVaUx6NEtQQzl5WldOMFBnbzhaeUIwY21GdWMyWnZjbTA5SW5SeVlXNXpiR0YwWlNneU5UQWdNVGMxS1NCelkyRnNaU2d4TGpJMUtTSStDanh3WVhSb0lHUTlJazAwTWpRdU5DQXlNVFF1TjB3M01pNDBJRFl1TmtNME15NDRMVEV3TGpNZ01DQTJMakVnTUNBME55NDVWalEyTkdNd0lETTNMalVnTkRBdU55QTJNQzR4SURjeUxqUWdOREV1TTJ3ek5USXRNakE0WXpNeExqUXRNVGd1TlNBek1TNDFMVFkwTGpFZ01DMDRNaTQyZWlJZ1ptbHNiRDBpSTBaR1JrWkdSa0pDSWk4K0Nqd3ZaejRLUEhSbGVIUWdlRDBpTlRBaUlIazlJakUxTUNJZ2RHVjRkRXhsYm1kMGFEMGlPVEFsSWo1QlZVUkpUend2ZEdWNGRENDhkR1Y0ZENCNFBTSTFNQ0lnZVQwaU9UVXdJaUIwWlhoMFRHVnVaM1JvUFNJNU1DVWlQa2RGVGtWVFNWTThMM1JsZUhRK1BDOXpkbWMrIiwKICAiZXh0ZXJuYWxfbGluayI6ICJodHRwczovL3R3aXR0ZXIuY29tL0ltcG9zc2libGVORlQiLAogICJzZWxsZXJfZmVlX2Jhc2lzX3BvaW50cyI6IDEwMDAsCiAgImZlZV9yZWNpcGllbnQiOiAiMHhjRDRhNzE1NzcwNjBjMzgwQzM3NTU1NGNBOTlCNDBENDQ4NEQyYTA1Igp9";

    constructor()
        ERC721A("AudioGenesis", "AG")
    {
        _setDefaultRoyalty(owner(), 750);
    }

    function setMerkleRoot(uint256 _merkleRoot) external onlyOwner {
        merkleRoot = bytes32(_merkleRoot);
    }

    function pauseMint() external onlyOwner {
        mintStart = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    function setAllowlistStart(uint256 timestamp) external onlyOwner {
        mintStart = timestamp;
    }

    function startPublicMint() external onlyOwner {
        mintStart = block.timestamp - 1 days;
    }

    function mintForCreator() external onlyOwner {
        //Mint for Creator
        require(_numberMinted(address(0x2DDB405238368695f34d30a80AB60c449aa5cE48)) == 0, "ALREADY_MINTED");
        _calcSeeds(5, address(0x2DDB405238368695f34d30a80AB60c449aa5cE48));
        _safeMint(address(0x2DDB405238368695f34d30a80AB60c449aa5cE48), 5);
    }

    function mintForLuftballons(uint256 quantity) external onlyOwner {
        if(luftDropReserve >= quantity) luftDropReserve -= quantity;
        else luftDropReserve = 0;
        require(totalSupply() + quantity - 1 < maxSupply, "MINTED_OUT");
        _calcSeeds(quantity, address(0x356E1363897033759181727e4BFf12396c51A7E0));
        _safeMint(address(0x356E1363897033759181727e4BFf12396c51A7E0), quantity);
    }

    function verifyMerkleProof(bytes32 leaf, bytes32[] memory merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function mint(uint256 quantity, uint256 maxAllowed, bytes32[] memory merkleProof) external payable {
        require(msg.sender == tx.origin, "NO_CONTRACT_MINTS");
        require(totalSupply() + quantity - 1 < maxSupply - luftDropReserve, "MINTED_OUT");
        require(msg.value == pricePerMint * quantity, "INCORRECT_PAYMENT");
        require(mintStart < block.timestamp, "NOT_MINTING");
        if(mintStart + 1 days < block.timestamp) {
            require(_numberMinted(_msgSenderERC721A()) == 0, "ALREADY_MINTED");
            require(quantity == 1, "EXCEEDS_ALLOWED");
        } else{
            require(maxAllowed >= quantity + _numberMinted(_msgSenderERC721A()), "EXCEEDS_ALLOWED");
            bytes32 leaf = keccak256(abi.encodePacked(maxAllowed,_msgSenderERC721A()));
            require(verifyMerkleProof(leaf, merkleProof), "BAD_PROOF");
        }

        _calcSeeds(quantity,_msgSenderERC721A());
        _safeMint(_msgSenderERC721A(),quantity);
        
        payable(owner()).transfer(msg.value);
    }
    
    uint256 private constant pulseModWeights = 0x0101054B64C864644B4B4B191919190A0A0A0A0A0A0505050503DB19;
    uint256 private constant pulseModOptions = 0x0305070B0A1113171D1F25292B2F353B3D4347494F53596165;
    uint256 private constant lowPulseWeights = 0x010103030201000B06;
    uint256 private constant lowPulseOptions = 0x01020406080C;
    uint256 private constant lfoModulWeights = 0x07060504030201001c07;
    uint256 private constant lfoModulOptions = 0x07060504030201;
    uint256 private constant timeModuWeights = 0x07060504030201001c07;
    uint256 private constant timeModuOptions = 0x07060504030201;
    uint256 private constant visualizWeights = 0x020202050a0a0505050a0a0a004c0c;
    uint256 private constant visualizOptions = 0x0b0a09080706050403020100;
    uint256 private constant filterTpWeights = 0x0505050a0a0a0a0a004108;
    uint256 private constant filterTpOptions = 0x0706050403020100;
    uint256 private constant filterFrWeights = 0x01020304030201001007;
    uint256 private constant filterFrOptions = 0x06050403020100;
    uint256 private constant filter_QWeights = 0x02051e1e1e140a007f07;
    uint256 private constant filter_QOptions = 0x643219140f0a05;
    uint256 private constant channel_Weights = 0x0102020105030a001807;
    uint256 private constant channel_Options = 0x06050403020100;

    function weightedRand(uint256 seed, uint256 weights, uint256 options) internal pure returns (uint256 choice) {
        uint256 length = weights & 0xFF;
        uint256 weightSum = (weights>>8) & 0xFFFF;
        uint256 r = seed%weightSum;
        uint256 sum=0;
        for (uint i = 0; i < length; i++) {
            sum += (weights >> (24+8*i)) & 0xFF;
            if (r <= sum){
                choice = (options>>(i*8)) & 0xFF;
                break;
            }
        }
    }

    function _calcSeeds(uint256 minted, address minter) private {
        uint256 token = _nextTokenId();
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number-1),minter, token)));
        while(token < _nextTokenId()+minted) {
            uint256 tokenData   = 0;
            tokenData |= weightedRand(seed, pulseModWeights, pulseModOptions);      seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, lowPulseWeights, lowPulseOptions)<<8;   seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%6)<<16;                                              seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, lfoModulWeights, lfoModulOptions)<<24;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, timeModuWeights, timeModuOptions)<<32;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filterFrWeights, filterFrOptions)<<40;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%50)<<48;                                             seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filter_QWeights, filter_QOptions)<<56;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (2*(((seed%1000)**2)/1000))<<64;                           seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (500+10*(((seed%1000)**3)/1000000))<<80;                   seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%5)<<96;                                              seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%4)<<104;                                             seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, visualizWeights, visualizOptions)<<112; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filterTpWeights, filterTpOptions)<<120; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, channel_Weights, channel_Options)<<128; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= token<<136;

            tokenIdToData[token] = tokenData;

            token++;
        }
    }

    function setDefaultRoyalty(uint96 basisPoints) external onlyOwner {
        _setDefaultRoyalty(owner(), basisPoints);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setDefaultEndpoints(string memory websocketEndpoint, string memory jsonRPCEndpoint) external onlyOwner {
        defaultJSONAPI = jsonRPCEndpoint;
        defaultWebsocketAPI = websocketEndpoint;
    }

    function setCustomEndpoints(uint256 tokenID, string memory websocketEndpoint, string memory jsonRPCEndpoint) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenToWebsocketEndpoint[tokenID] = websocketEndpoint;
        tokenToJSONEndpoint[tokenID] = jsonRPCEndpoint;
        tokenOverridesEndpoints[tokenID] = true;
    }

    function clearCustomEndpoints(uint256 tokenID) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenOverridesEndpoints[tokenID] = false;
    }

    function setCustomVisualizer(uint256 tokenID, string memory fragmentShaderSrc, string memory visualizerName) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomVisualizer[tokenID] = fragmentShaderSrc;
        tokenIdToCustomVisualizerName[tokenID] = visualizerName;
    }

    function clearCustomVisualizer(uint256 tokenID) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomVisualizer[tokenID] = "";
        tokenIdToCustomVisualizerName[tokenID] = "";
    }

    function addCustomListener(uint256 tokenID, address listenerAddress) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomListeners[tokenID].push(listenerAddress);
    }

    function removeCustomListener(uint256 tokenID, uint256 listenerIndex) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        uint256 length = tokenIdToCustomListeners[tokenID].length;
        require(listenerIndex < length);
        if(length > 1) tokenIdToCustomListeners[tokenID][listenerIndex] = tokenIdToCustomListeners[tokenID][length-1];
        tokenIdToCustomListeners[tokenID].pop();
    }

    function mintStatus() public view returns (uint256 status) {
        if(totalSupply() >= maxSupply - luftDropReserve) status += MINTED;
        else if(mintStart + 1 days < block.timestamp) status += PUBLIC;
        else if(mintStart < block.timestamp) status += ALLOWLIST; 
        return status + _numberMinted(_msgSenderERC721A());
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        if(tokenOverridesEndpoints[tokenID]) {
            return renderer.constructTokenURI(
                tokenToWebsocketEndpoint[tokenID],
                tokenToJSONEndpoint[tokenID],
                tokenIdToCustomListeners[tokenID],
                tokenIdToCustomVisualizer[tokenID],
                tokenIdToCustomVisualizerName[tokenID],
                tokenIdToData[tokenID]);
        }

        return renderer.constructTokenURI(
                defaultWebsocketAPI,
                defaultJSONAPI,
                tokenIdToCustomListeners[tokenID],
                tokenIdToCustomVisualizer[tokenID],
                tokenIdToCustomVisualizerName[tokenID],
                tokenIdToData[tokenID]);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId); 
    }
}