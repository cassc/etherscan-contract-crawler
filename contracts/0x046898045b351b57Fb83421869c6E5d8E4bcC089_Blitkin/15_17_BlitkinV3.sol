// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./interfaces/IBlitkinRenderV3.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract Blitkin is ERC721, OwnableUpgradeable, UUPSUpgradeable, DefaultOperatorFiltererUpgradeable{

    mapping(bytes32 => bool) private tokenPairs;
    mapping(uint8 => uint8) public mintedPerComposition;
    IBlitkinRenderV3 public blitkinRender; 

    event CombinationMinted(uint8 indexed composition, uint8 indexed palette);

    bytes32 public ALRoot;
    bytes32 public teamRoot;
    uint256 public mintStatus; 
    address public splitter;
    uint256 constant public MAX_SUPPLY = 1600;
    uint256 constant public MAX_PER_WALLET = 5;
    uint256 constant public MAX_ALLOW_LIST = 2;

    error PublicMintNotStarted();
    error PayMintPrice();
    error ALMintNotStarted();
    error NotOnAL();
    error MaxSupplyMinted();
    error NoContracts();
    error DoNotMintOriginals();
    error OnlyCombineOriginals();
    error ScrambleAlreadyMinted();
    error AlreadyMintedAllowance();
    error MaxLimitPerComposition();
    error SplitterNotSet();

    //Constructor / Initializer

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Blitkin", "BLITKIN", 1);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();
    }

    /// Admin setters

    function setBlitkinRender(address _newRender) external onlyOwner {
        blitkinRender = IBlitkinRenderV3(_newRender);
    }
    
    function setMintStatus(uint256 _newStatus) external onlyOwner {
        mintStatus = _newStatus;
    }

    function setALRoot(bytes32 _newRoot) external onlyOwner {
        ALRoot = _newRoot;
    }

    function setTeamRoot(bytes32 _newRoot) external onlyOwner {
        teamRoot = _newRoot;
    }

    function setSplitter(address _splitter) external onlyOwner {
        splitter = _splitter;
    }

    /// Mint function

    function mint(uint8 compositionId, uint8 paletteId) public payable {
        if(msg.value != 0.05 ether) revert PayMintPrice();
        if(mintStatus != 2) revert PublicMintNotStarted();
        if(_balanceOf[msg.sender].minted + 1 > MAX_PER_WALLET) revert AlreadyMintedAllowance();

        _mintScramble(compositionId, paletteId);
    }

    function allowlistMint(uint8 compositionId, uint8 paletteId, bytes32[] calldata _proof) public payable {
        if(msg.value != 0.05 ether) revert PayMintPrice();
        if(mintStatus != 1) revert ALMintNotStarted();
        if(_balanceOf[msg.sender].minted + 1 > MAX_ALLOW_LIST) revert AlreadyMintedAllowance();
        verify(_proof, msg.sender, ALRoot);

        _mintScramble(compositionId, paletteId);
    }

    function teamMint(uint8 compositionId, uint8 paletteId, bytes32[] calldata _proof) public payable {
        if(_balanceOf[msg.sender].minted > 0) revert AlreadyMintedAllowance();
        verify(_proof, msg.sender, teamRoot);

        _mintScramble(compositionId, paletteId);
    }

    function _mintScramble(uint8 compositionId, uint8 paletteId) internal {
        if(totalSupply() + 1 > MAX_SUPPLY) revert MaxSupplyMinted();
        if(msg.sender != tx.origin) revert NoContracts();
        if(compositionId == paletteId) revert DoNotMintOriginals(); 
        if(compositionId > 99 || paletteId > 99) revert OnlyCombineOriginals();
        if(mintedPerComposition[compositionId] + 1 > 16) revert MaxLimitPerComposition();

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(compositionId, '-', paletteId));
        if(tokenPairs[pairHash]) revert ScrambleAlreadyMinted();
        
        tokenPairs[pairHash] = true;
        unchecked {
            mintedPerComposition[compositionId]++;
        }

        emit CombinationMinted(compositionId, paletteId);

        _mintAndSet(msg.sender, compositionId, paletteId);
    }

    //Helper functions

    function pairIsTaken(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        return tokenPairs[pairHash];
    }

    function amountMinted(address _user) public view returns(uint16) {
        return _balanceOf[_user].minted;
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function verify(
        bytes32[] memory proof,
        address addr,
        bytes32 _root
    ) internal pure {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        require(MerkleProofUpgradeable.verify(proof, _root, leaf), "Invalid proof");
    }

    //TokenURI
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if(tokenId == 0 || tokenId > tokenIndex) revert();
        return blitkinRender.tokenURI(tokenId, _ownerOf[tokenId].compositionId, _ownerOf[tokenId].paletteId);
    }

    //
    function withdraw() external onlyOwner {
        if(splitter == address(0)) revert SplitterNotSet();
        payable(splitter).transfer(address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return blitkinRender.getContractInfo();
    }

    //////////////////////// Operatorfilter overrides ////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,
        address to,
        uint256 id) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom( address from,
        address to,
        uint256 id,
        bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, data);
    }
}