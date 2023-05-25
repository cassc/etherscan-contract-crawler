// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "hardhat/console.sol";

error MaxSupplyExceeded();
error Overflow(uint256 z, uint256 x);
error MaxSupplyUnderflow(uint256 current, uint256 incoming);
error InvalidQuantity();

contract InPeakGen2 is ERC721, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    event Received(address sender, uint256 amount);

    address public pledgeContractAddress;
    uint256 public maxSupply = 10000;
    uint256 public tokenCounter = 0;
    uint256 public pendingReservedSupply=500;

    mapping(uint8 => string) public tokenURIByLevel;
    mapping(uint256 => uint8) public tokenLevelOf;

     constructor(uint256 pMaxSupply, uint256 pPendingReservedSupply) ERC721("InPeak Gen II", "IPGENII") {
        maxSupply = pMaxSupply;
        pendingReservedSupply = pPendingReservedSupply;
     }

     function pledgeMint(address to, uint8 quantity) external payable {
        if(quantity != 1) revert InvalidQuantity();
        if(tokenCounter + 1 > maxSupply - pendingReservedSupply) revert MaxSupplyExceeded();
        require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
        tokenCounter += 1;
        _mint(to, tokenCounter);
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

    function setTokenURI(uint8 level, string memory pURI) onlyOwner public {
        tokenURIByLevel[level] = pURI;
    }

    function setTokenLevel(uint256 pTokenId, uint8 pLevel) onlyOwner public {
        tokenLevelOf[pTokenId] = pLevel;
    }

    function setTokensLevel(uint256[] calldata pTokenIds, uint8 pLevel) onlyOwner public {
        for(uint256 i; i < pTokenIds.length; i++) {
            tokenLevelOf[pTokenIds[i]] = pLevel;
        }
    }

    function setTokensLevels(uint256[] calldata pTokenIds, uint8[] calldata pLevels) onlyOwner public {
        require(pTokenIds.length == pLevels.length, "invalid array lengths");
        for(uint256 i; i < pTokenIds.length; i++) {
            tokenLevelOf[pTokenIds[i]] = pLevels[i];
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
    /*** VIEWS ***/

       /// @dev Returns the URI of a token.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "invalid token id");
        return tokenURIByLevel[tokenLevelOf[tokenId]];
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