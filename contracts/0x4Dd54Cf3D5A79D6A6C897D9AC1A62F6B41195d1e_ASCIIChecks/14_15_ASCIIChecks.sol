// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ERC721G } from  "./ERC721G.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

interface IASCIIChecksRender {
    function tokenSVG(uint16[] memory signs, uint8[] memory colors)
        external
        view
        returns (string memory);
    function tokenURI(uint256 tokenId, uint16[] memory signs, uint8[] memory colors) external view returns (string memory);
}

/// @title UinToadz - An on-chain uint + CrypToadz Deriv
/// @author OxDala
/// @notice What could it do? 
contract ASCIIChecks is ERC721G, OwnableUpgradeable, UUPSUpgradeable, DefaultOperatorFiltererUpgradeable {
    
    /// @dev EIP-4096 Event, only emited during update not during minting
    event MetadataUpdate(uint256 _tokenId);

    // Errors
    error MintIsOver();
    error BurnNotStarted();
    error NotTokenOwner();
    error TokenDoesNotExist();
    error MintNotStarted();
    error PayRightAmount();
    error TraitDetailsError();
    error MaxAmountPerTx();
    error TokenMaxedOut();
    error ToadAlreadyExists();
    error ToadAlreadyFixed();

    // Variables / Constants
    IASCIIChecksRender public render;
    uint256 public MINT_PRICE;
    uint256 public constant MINT_UNTIL = 16790700; ////////SETTTT THISSSS 72h = 25920 block
    bool public mintActive;

    mapping (uint256 => uint24[]) linkedTokens;

    ////////////////////////  Initializer  /////////////////////////////////

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("ASCII Checks", "ASCIIC", 1);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init(); 
        MINT_PRICE = 0.002 ether;
        mintActive = true;
    }

    ////////////////////////  User Functions  /////////////////////////////////

    function mint(uint256 amount) external payable {
        if(!mintActive) revert MintNotStarted();
        if(block.number > MINT_UNTIL) revert MintIsOver();
        if(msg.value < MINT_PRICE*amount) revert PayRightAmount();
        if(amount > 10) revert MaxAmountPerTx();
        _mint(msg.sender, amount);
    }

    function combine(uint256[] memory tokenIds) external {
        // I wonder what goes here....
    }

    function _getTokenAndInitilizatedDataOf(uint256 tokenId_) internal view
    returns (OwnerStruct memory, uint256) {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");
        
        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (_tokenData[tokenId_].random != 0
            || tokenId_ >= tokenIndex) {
            return (_tokenData[tokenId_], 0);
        }

        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else { unchecked {
            uint256 _lowerRange = tokenId_;
            while (mintIndex[_lowerRange].random == 0) { _lowerRange--; }
            return (mintIndex[_lowerRange], tokenId_ - _lowerRange);
        }}
    }

    ////////////////////////  Management functions  /////////////////////////////////

    function setMintActive() external onlyOwner {
        mintActive = true;
    }

    function setRender( address _newRender) public onlyOwner {
        render = IASCIIChecksRender(_newRender);
    }

    ////////////////////////  TokenURI /////////////////////////////////

    function tokenURI(uint256 tokenId) override public view returns (string memory) { 
        if(tokenId > totalSupply()) revert TokenDoesNotExist();
        (OwnerStruct memory _token, uint256 mintI) = _getTokenAndInitilizatedDataOf(tokenId);
        (uint16[] memory signs, uint8[] memory colors) = getSignsAndColors(_token, mintI);
        return render.tokenURI(tokenId, signs, colors);
    }

    function getSignsAndColors(OwnerStruct memory _token, uint256 mintI) internal pure returns(uint16[] memory signs, uint8[] memory colors) {
        signs = new uint16[](1);
        colors = new uint8[](1);
        signs[0] = (_token.random >> (mintI*12)) % 4 == 0 ? uint16((_token.random >> (mintI*12 + 2)) % 400) : uint16((_token.random >> (mintI*12 + 2)) % 20);
        colors[0] = uint8((_token.random >> (mintI*12 + 8)) % 13);
    }

    function tokenSVG(uint256 tokenId) public view returns (string memory) { 
        if(tokenId > totalSupply()) revert TokenDoesNotExist();
        (OwnerStruct memory _token, uint256 mintI) = _getTokenAndInitilizatedDataOf(tokenId);
        (uint16[] memory signs, uint8[] memory colors) = getSignsAndColors(_token, mintI);

        return render.tokenSVG(signs, colors);
    }

    //////////////////////// Withdraw ////////////////////////

    function withdraw() payable public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    //////////////////////// Upgrade ////////////////////////

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    //////////////////////// Operatorfilter ////////////////////////
    
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

    function safeTransferFrom( address from_, address to_, uint256 tokenId_,
    bytes memory data_)
        public
        override
        onlyAllowedOperator(from_)
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }
}