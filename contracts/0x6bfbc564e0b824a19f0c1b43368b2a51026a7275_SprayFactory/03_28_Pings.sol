// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "base64-sol/base64.sol";
import "./IPingMetadata.sol";
import "./PingData.sol";
import "./PingAtts.sol";


contract Pings is ERC721ABurnable, ReentrancyGuard, Ownable, IValidatable {
    using Strings for uint;
    using Strings for uint8;

    enum SalePhase {
        Locked,
        Claim,
        Public
    }

    event MintedEvent(uint256 numMinted, uint256 newTotalSupply);

    uint256 public numClaimsPerParent = 2;
    uint256 public publicMaxSupply = 1110;
    uint256 public maxSupply = 555*numClaimsPerParent + publicMaxSupply;
    uint256 public maxMintsPerWallet = 10;
    mapping (address => uint8) public pubMintedByWallet;
    mapping (uint256 => bool) public claimedByPlanesId;
    mapping (uint256 => bool) public claimedByAttrs;

    uint256 public publicTotalMinted = 0;

    uint256 public price = 0.03 ether;
    IPingMetadata public _metadata;
    ERC721 public _skies;
    SalePhase public phase = SalePhase.Locked;
    bool public burnEnabled;
    string _contractURI = "https://skies.wtf/nft/pings_contractURI.json";

    mapping(uint256 => PingAtts) attsById;


    constructor() ERC721A("Pings by BlockMachine", "PINGS") {}

    function tokenURI(uint256 tokenId) override(IERC721A, ERC721A) public view returns (string memory) {
        require(_exists(tokenId), "unknown id");

        IPingMetadata metadata = IPingMetadata(_metadata);
        PingAtts memory params = attsById[tokenId];
        return metadata.genMetadata(tokenId, params);
    }

    function setSkiesAddr(address addr) external onlyOwner {
        _skies = ERC721(addr);
    }

    function setMetadata(address metadataAddr) external onlyOwner {
        _metadata = IPingMetadata(metadataAddr);
    }

    function getAttsById(uint256 tokenId) external view returns (PingAtts memory atts){
        return attsById[tokenId];
    }

    function validateContract() external view returns (string memory){
        if(address(_skies) == address(0)) {return 'No Parent';}
        if(address(_metadata) == address(0)) {return "No metadata addr";}
        IPingMetadata metadata = IPingMetadata(_metadata);
        return(metadata.validateContract());
    }

    function mint(PingAtts[] calldata paramCombos) external nonReentrant payable {
        require(phase >= SalePhase.Public, 'Not Public');
        uint num = paramCombos.length;
        require(publicTotalMinted + num <= publicMaxSupply, "Public Sold out");
        require(pubMintedByWallet[msg.sender] + num <= maxMintsPerWallet, "Maxed per wallet");
        require(num * price <= msg.value, "Wrong price");
        require(!Address.isContract(msg.sender), "No contracts");

        pubMintedByWallet[msg.sender] += uint8(num);
        publicTotalMinted += num;

        validateParams(paramCombos);
        uint pingId = totalSupply();
        for (uint paramIdx; paramIdx < paramCombos.length; paramIdx++) {
            claimParamCombo(pingId++, paramCombos[paramIdx], paramIdx);
        }

        _mint(msg.sender, num);
        emit MintedEvent(num, totalSupply());
    }

    function claimMint(uint256[] calldata parentIds, PingAtts[] calldata paramCombos) external nonReentrant payable {
        require(phase >= SalePhase.Claim, 'Claim Not Open');
        uint numToClaim = parentIds.length * numClaimsPerParent;
        uint numToBuy = paramCombos.length - numToClaim;
        if(numToBuy > 0) {
            require(numToBuy * price <= msg.value, "Wrong price");
            require(pubMintedByWallet[msg.sender] + numToBuy <= maxMintsPerWallet, "Maxed per wallet");
        }
        require(numToBuy >= 0, "Claim short");

        uint totalToMint = paramCombos.length;
        require(totalSupply() + totalToMint <= maxSupply, "Sold out");

        validateParams(paramCombos);

        uint pingId = totalSupply();
        uint paramIdx = 0;
        for (uint i; i < parentIds.length; i++) {
            require(_skies.ownerOf(parentIds[i]) == msg.sender, string.concat("not owner ",  parentIds[i].toString()));
            require(!claimedByPlanesId[parentIds[i]], string.concat("already claimed ", parentIds[i].toString()));

            claimedByPlanesId[parentIds[i]] = true;

            claimParamCombo(pingId++, paramCombos[paramIdx++], paramIdx);
            claimParamCombo(pingId++, paramCombos[paramIdx++], paramIdx);
        }

        //claim extras if any
        if(numToBuy > 0) {
            for (; paramIdx < paramCombos.length; paramIdx++) {
                claimParamCombo(pingId++, paramCombos[paramIdx], paramIdx);
            }
            pubMintedByWallet[msg.sender] += uint8(numToBuy);
        }

        _mint(msg.sender, totalToMint);
        emit MintedEvent(totalToMint, totalSupply());
    }

    function claimParamCombo(uint tokenId, PingAtts calldata atts, uint paramsIndex) internal {
        uint hash = uint(keccak256(abi.encode(atts)));
        require(!claimedByAttrs[hash], string.concat("attribute already claimed.", paramsIndex.toString()));
        claimedByAttrs[hash] = true;
        attsById[tokenId] = atts;
    }

    function validateParams(PingAtts[] calldata paramCombos) internal pure {
        for (uint256 i; i < paramCombos.length; i++) {
            validateParams(paramCombos[i]);
        }
    }

    function validateParams(PingAtts calldata p) internal pure {
        require(p.numX >= 1 && p.numX <= 7, string.concat("bad numX ", p.numX.toString()));
        require(p.numY >= 1 && p.numY <= 7, string.concat("bad numY ", p.numY.toString()));
        require(p.paletteIndex < 19, string.concat("bad pal ", p.paletteIndex.toString()));
        require(p.lineColorIdx < 19, string.concat("bad line ", p.lineColorIdx.toString()));
        require(p.paintIdx < 19, string.concat("bad paint ", p.paintIdx.toString()));
        require(p.shapeColorIdx < 19, string.concat("bad shape ", p.shapeColorIdx.toString()));
        require(p.emitColorIdx < 19, string.concat("bad emitCol ", p.emitColorIdx.toString()));
        require(p.shadowColorIdx < 19, string.concat("bad shadowCol ", p.shadowColorIdx.toString()));
        require(p.nShadColIdx < 19, string.concat("bad nShadColor ", p.nShadColIdx.toString()));
        require(p.shapeSizesDensity >= 1 && p.shapeSizesDensity <= 7, string.concat("bad shapeDensity ", p.shapeSizesDensity.toString()));
        require(p.lineThickness >= 1 && p.lineThickness <= 5, string.concat("bad lineThickness ", p.lineThickness.toString()));
        require(p.emitRate >= 1 && p.emitRate <= 10, string.concat("bad emitRate ", p.emitRate.toString()));
        require(p.wiggleSpeedIdx < 3, string.concat("bad wiggleSpeed ", p.wiggleSpeedIdx.toString()));
        require(p.wiggleStrengthIdx < 4, string.concat("bad wiggleStrength ", p.wiggleStrengthIdx.toString()));
        require(p.paint2Idx < 19, string.concat("bad paint2Idx ", p.paint2Idx.toString()));
        require(p.extraParams.length == 0, string.concat("bad eP ", p.extraParams.length.toString()));
    }

    function reset(uint256 numIds) external onlyOwner {
        for (uint256 i; i < numIds; i++) {
            delete claimedByPlanesId[i];
        }
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        maxSupply = max;
    }

    function setPubMaxSupply(uint256 max) external onlyOwner {
        publicMaxSupply = max;
    }

    function setMaxMintsPerWallet(uint8 max) external onlyOwner {
        numClaimsPerParent = max;
    }

    function setPhase(SalePhase newPhase) external onlyOwner {
        phase = newPhase;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function enableBurn(bool state) external onlyOwner {
        burnEnabled = state;
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC721A, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        require(to != address(0) || burnEnabled, "burn disabled");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

}