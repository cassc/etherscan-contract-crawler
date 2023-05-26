// SPDX-License-Identifier: MIT
/*
                                                                       
#       ####  #    # ######    #  ####     #       ####  #    # ###### 
#      #    # #    # #         # #         #      #    # #    # #      
#      #    # #    # #####     #  ####     #      #    # #    # #####  
#      #    # #    # #         #      #    #      #    # #    # #      
#      #    #  #  #  #         # #    #    #      #    #  #  #  #      
######  ####    ##   ######    #  ####     ######  ####    ##   ###### 

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoveIsLove is ERC721, Ownable, ReentrancyGuard {
    string public PROVENANCE;
    bool public saleActive = false;

    string private _baseURIextended;

    uint public constant MAX_SUPPLY = 500;
    uint public constant MINT_PRICE = 0.05683 ether;
    uint public constant MAX_PURCHASE_PER_TX = 2;
    uint public immutable NUM_TIERS;

    uint public totalSupply;

    struct TierConfig {
        uint minIndexInclusive;
        uint index;
        uint maxIndexExclusive;
    }

    mapping(uint256 => TierConfig) public tiers;

    constructor(uint[] memory maxSupplyPerTier) ERC721("Love Is Love", "LOVE") {
        NUM_TIERS = maxSupplyPerTier.length;
        uint tierStartIndex = 0;
        for (uint i = 0; i < maxSupplyPerTier.length; i++) {
            tiers[i] = TierConfig(tierStartIndex, tierStartIndex, tierStartIndex + maxSupplyPerTier[i]);
            tierStartIndex += maxSupplyPerTier[i];
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function exists(uint256 tierId) public view returns (bool) {
        return tiers[tierId].maxIndexExclusive > 0;
    }

    function setSaleActive(bool newState) public onlyOwner {
        saleActive = newState;
    }

    function devMint(uint numberOfTokens, uint tierId) public onlyOwner {
        _internalMint(numberOfTokens, tiers[tierId].index, tierId);
    }

    function _internalMint(uint numberOfTokens, uint startIndex, uint tierId) internal {
        require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(exists(tierId), "Mint: tier does not exist");
        require(tiers[tierId].index + numberOfTokens <= tiers[tierId].maxIndexExclusive, "Max purchase supply reached by tier");
        for (uint i = 0; i < numberOfTokens; i++) {
            if (totalSupply < MAX_SUPPLY) {
                totalSupply++;
                _safeMint(msg.sender, startIndex + i);
            }
        }
        tiers[tierId].index = tiers[tierId].index + numberOfTokens;
    }

    function mint(uint numberOfTokens, uint tierId) public payable nonReentrant {
        require(saleActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_PURCHASE_PER_TX, "Max token purchase per tx exceeded");
        require(msg.value == numberOfTokens * MINT_PRICE, "Ether value sent is not correct");

        _internalMint(numberOfTokens, tiers[tierId].index, tierId);
    }

    function tierInfo(uint tierId) external view returns (TierConfig memory) {
        return tiers[tierId];
    }

    function tierSupply(uint tierId) external view returns (uint) {
        require(exists(tierId), "Mint: tier does not exist");
        return tiers[tierId].index - tiers[tierId].minIndexInclusive;
    }

    function getTier(uint tokenId) external view returns (uint) {
        for (uint i = 0; i < NUM_TIERS; i++) {
            if (tokenId >= tiers[i].minIndexInclusive && tokenId < tiers[i].maxIndexExclusive) {
                return i;
            }
        }
        revert("Token id not found");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Allow list

    bool public allowListActive = false;
    mapping(address => uint8) private _allowList;

    function setAllowListActive(bool _allowListActive) external onlyOwner {
        allowListActive = _allowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens, uint tierId) external payable {
        require(allowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max availble to purchase");
        require(numberOfTokens <= MAX_PURCHASE_PER_TX, "Max token purchase per tx exceeded");
        require(msg.value == numberOfTokens * MINT_PRICE, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        _internalMint(numberOfTokens, tiers[tierId].index, tierId);
    }
}