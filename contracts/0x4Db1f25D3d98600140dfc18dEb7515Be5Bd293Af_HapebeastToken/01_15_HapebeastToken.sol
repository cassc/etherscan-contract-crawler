// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title:  HAPE PRIME
// @desc:   NEXT-GEN, HIGH FASHION HAPES
// @artist: https://twitter.com/DigimentalLDN
// @team:   https://twitter.com/TheCarlbrutal
// @team:   https://twitter.com/_trouvelot
// @author: https://twitter.com/rickeccak
// @url:    https://www.hapeprime.com/

/*
* ██╗░░██╗░█████╗░██████╗░███████╗
* ██║░░██║██╔══██╗██╔══██╗██╔════╝
* ███████║███████║██████╔╝█████╗░░
* ██╔══██║██╔══██║██╔═══╝░██╔══╝░░
* ██║░░██║██║░░██║██║░░░░░███████╗
* ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚══════╝
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./IHapebeastToken.sol";
import "./IHapebeastMetadata.sol";

contract HapebeastToken is IHapebeastToken, IERC2981, Ownable {

    // ======== Supply =========
    uint256 public tokenSupply;

    // ======== Provenance =========
    string public provenanceHash;
    uint256 public startingIndex;
    bool public isStartingIndexLocked;

    // ======== Metadata =========
    // Seperate contract to allow eventual move to on-chain metadata. "The Future".
    IHapebeastMetadata public metadata;
    bool public isMetadataLocked = false;

    // ======== Minter =========
    address public minter;
    bool public isMinterLocked = false;

    // ======== Burning =========
    bool public isBurningActive = false;

    // ======== Royalties =========
    address public royaltyAddress;
    uint256 public royaltyPercent;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }
    
    // ======== Constructor =========
    constructor(address metadataAddress) ERC721("HAPE PRIME", "HAPE") {
        metadata = IHapebeastMetadata(metadataAddress);
        royaltyAddress = owner();
        royaltyPercent = 5;
    }

    // ======== Minting =========
    function mint(uint256 _count, address _recipient) public override onlyMinter {
        uint256 supply = totalSupply();
        for (uint i = 1; i <= _count; i++) {
            tokenSupply++;
            _safeMint(_recipient, supply + i);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return tokenSupply;
    }

    // ======== Minter =========
    function updateMinter(address _minter) external override onlyOwner {
        require(!isMinterLocked, "Minter ownership renounced");
        minter = _minter;
    }

    function lockMinter() external override onlyOwner {
        isMinterLocked = true;
    }

    // ======== Metadata =========
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return metadata.tokenURI(tokenId);
    }

    function updateMetadata(address _metadata) external onlyOwner {
        require(!isMetadataLocked, "Metadata ownership renounced");
        metadata = IHapebeastMetadata(_metadata);
    }

    function lockMetadata() public onlyOwner {
        isMetadataLocked = true;
    }

    // ======== Provenance =========
    function setProvenanceHash(string memory _provenanceHash) public override onlyOwner {
        provenanceHash = _provenanceHash;
    }

    /**
    * Set a random starting index for the collection. We could have included something with user provided entropy, but that doesn't
    * make it any more random in practice. There's still nothing exclusively on-chain we can use for completely undeterminstic randomness 
    * - only VRF. But with a provenance hash this should provide the basis for verifiable and transparent random metadata assignment. 
    *
    * NOTE: Ahead of time an agreed date/timestamp will be selected with the community for when the transaction for `setStartingIndex`
    * is submitted, this is to avoid scenarios such as waiting for a favourable blockhash + submitting a high gas tx.
    */
    function setStartingIndex() public override onlyOwner {
        require(!isStartingIndexLocked, "Starting index set");
        isStartingIndexLocked = true;
        startingIndex = uint(blockhash(block.number - 1)) % totalSupply();
    }

    // ======== Burning =========
    function burn(uint256 tokenId) public {
        require(isBurningActive, "Burning not active");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller not owner or approved");
        _burn(tokenId);
    }
    
    function toggleBurningActive() public onlyOwner {
        isBurningActive = !isBurningActive;
    }

    // ======== Royalties =========
    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // ======== Withdraw =========
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }
}