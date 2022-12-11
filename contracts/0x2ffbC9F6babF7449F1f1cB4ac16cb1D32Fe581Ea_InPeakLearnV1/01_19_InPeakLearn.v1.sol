/**
 * InPeak Soulbound Tokens (non transferable)
 *
 * Author: juanu.eth
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IRenderModule.sol";
// import "hardhat/console.sol";

error MaxSupplyExceeded();
error Overflow(uint256 z, uint256 x);
error MaxSupplyUnderflow(uint256 current, uint256 incoming);
error InvalidQuantity();
error NonTransferableToken();

contract InPeakLearnV1 is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using MerkleProof for bytes32[];
    using Strings for uint256;
    using Strings for uint8;
    IRenderModule public renderModule;

    struct Token {
        uint256 expiration;
        uint8 level;
        uint8 subLevel;
    }

    event Received(address sender, uint256 amount);
    mapping(uint256 => Token) public tokens;
    

    string public baseTokenURI;
    address public pledgeContractAddress;
    uint256 public maxSupply;
    uint256 public tokenCounter;
    uint256 public pendingReservedSupply;
    uint256 public tokenDuration;

     /// @dev Initializer function for upgradeable contract
    function initialize(uint256 pMaxSupply, uint256 pPendingReservedSupply) public initializer {
        __ERC721_init("InPeak Learn", "IPLEARN");
        __Ownable_init();
        maxSupply = pMaxSupply;
        pendingReservedSupply = pPendingReservedSupply;
        _transferOwnership(_msgSender());
    }

     /// @dev Transfers are restricted to be made by the contract owner as long as they are approved by the token owner.
     function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Execute transfer only of called is owner of contract (Stil lrequires approval)
        if(msg.sender == owner()) {
            super.transferFrom(from, to, tokenId);
        }
        else
            revert NonTransferableToken();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // Execute transfer only of called is owner of contract (Stil lrequires approval)
        if(msg.sender == owner()) {
            super.safeTransferFrom(from, to, tokenId, data);
        }
        else
            revert NonTransferableToken();
    }

     /*** MINTING ****/

    /// @dev Minting from Pledge Mint
     function pledgeMint(address to, uint8 quantity) external payable {
        if(quantity != 1) revert InvalidQuantity();
        if(tokenCounter + 1 > maxSupply - pendingReservedSupply) revert MaxSupplyExceeded();
        require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
        tokenCounter += 1;
        _mint(to, tokenCounter);
        tokens[tokenCounter] = Token ({
            level: 0,
            expiration: block.timestamp + tokenDuration,
            subLevel: 0
        });
    }

    function setPledgeContractAddress(address _pledgeContractAddress) public onlyOwner {
        pledgeContractAddress = _pledgeContractAddress;
    }
    
    /// @dev Mint 1 token to each `recipient` of `recipients`.
    function mintReserved(address[] memory recipients) onlyOwner external {
        require(recipients.length > 0, "invalid number of recipients");
        require(pendingReservedSupply >= recipients.length, "not enough reserved supply");
        require(maxSupply -tokenCounter > 0, "max supply reached");

        for(uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenCounter + i + 1);
        }
        tokenCounter += recipients.length;
        pendingReservedSupply -= recipients.length;
    }

    function withdraw() nonReentrant public {
        require(address(this).balance > 0, "no balance to withdraw");
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }

    /*** SETTERS ***/

    function setBaseTokenURI(string memory pURI) onlyOwner public {
        baseTokenURI = pURI;
    }

    function setTokenLevel(uint256 pTokenId, uint8 pLevel) onlyOwner public {
        tokens[pTokenId].level = pLevel;
    }

    function setTokensLevel(uint256[] calldata pTokenIds, uint8 pLevel) onlyOwner public {
        for(uint256 i; i < pTokenIds.length; i++) {
            tokens[pTokenIds[i]].level = pLevel;
        }
    }

    function setTokensLevels(uint256[] calldata pTokenIds, uint8[] calldata pLevels) onlyOwner public {
        require(pTokenIds.length == pLevels.length, "invalid array lengths");
        for(uint256 i; i < pTokenIds.length; i++) {
            tokens[pTokenIds[i]].level = pLevels[i];
        }
    }

    function setMaxSupply(uint256 pMaxSupply) onlyOwner public {
        require(pMaxSupply - tokenCounter - pendingReservedSupply > 0, "invalid max supply");
        maxSupply = pMaxSupply;
    }

    /// @dev Set the reserved supply for marketing.
    function setPendingReservedSupply(uint256 pPendingReservedSupply) onlyOwner public {
        require(tokenCounter + pPendingReservedSupply <= maxSupply, "cant reserve more than maximum supply");
        pendingReservedSupply = pPendingReservedSupply;
    }
    /// @dev sets the duration of each token. When a token is minted, expiration date is based on timestamp + tokenDuration
    function setTokenDuration(uint256 pDuration) onlyOwner public {
        tokenDuration = pDuration;
    }


    // @dev setter for renderModule. Render module can be removed by setting to address 0x0
    function setRenderModule(address _contractAddress) public onlyOwner {
        renderModule = IRenderModule(_contractAddress);
    }

    /*** VIEWS ***/

    /// @dev Returns the token metadata URI. Uses on-chain level data if renderModule is not set.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "invalid token id");

        // if module contract address is set, returns URI from that contract
        if (address(renderModule) != address(0)) {
            return renderModule.tokenURI(tokenId);
        }

        // if no module is set, return as normal
        Token memory token = tokens[tokenId];
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, token.level.toString(),"_", token.subLevel.toString())) : "";
        // return tokenURIByLevel[tokens[tokenId].level];
    } 

    /// @dev expiration is initially calculated from `tokenDuration`.  If expioration is 0, it means it doesnt expire.
    function isExpired(uint256 tokenId) public view returns (bool) {
        return tokens[tokenId].expiration != 0 && block.timestamp > tokens[tokenId].expiration;
    }

    function getExpirationDate(uint256 tokenId) public view returns (uint256) {
        return tokens[tokenId].expiration;
    }

    /// @dev Returns the remaining supply for public mints
    function getPublicRemainingSupply() public view returns (uint256) {
        return maxSupply - tokenCounter - pendingReservedSupply;
    }

    /// @dev Returns the remaining real remaining supply without considering pending reserved
    function getRemainingSupply() public view returns (uint256) {
        return maxSupply - tokenCounter;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


}