// SPDX-License-Identifier: MIT


//  o       o  o-o  o--o  o--o  o     o--o o--o  o   o  o-o  
//  |       | o   o |   | |   | |     |    |   | |   | o     
//  o   o   o |   | O--o  O--o  |     O-o  O--o  |   | |  -o 
//   \ / \ /  o   o |   | |   | |     |    |   | |   | o   | 
//    o   o    o-o  o--o  o--o  O---o o--o o--o   o-o   o-o  

// www.wobblebug.space
// www.twitter.com/wobblebug

// Wobblebug Team:

// Co-Founder | Music Producer: Kris Barman | @Wuki
// Co-Founder | Creative Director: Florian Tappeser | @digitalflowercg
// Project Manager | Blockchain Dev: Nick Zeigler | @AlphaMediaLabs
// 2D Artist | Co-Music Producer: Levi | @Rawtek
// Community Driver: Gabe Perez | @gabe__perez
// Creative Manager: JSTJR | @JSTJR
// Brand Manager: Courtney Roxanne | @roxanneonfilm
// Community Driver: Kaku | @Kakuberry

// Launched with Top Dog LaunchPad: https://topdogbeachclub.com/launchpad/

// By minting Wobblebugs, you are agreeing to our Terms of Service on our website
// as https://www.wobblebug.space/terms

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Wobblebug is ERC721Enumerable, Ownable, ReentrancyGuard {
    enum WhitelisterStatus { Invalid, Unclaimed, Claimed }
    struct SaleConfig {
        uint16 MAX_WOBBLEBUGS;
        uint8 DEV_RESERVED;
        uint128 WOBBLEBUG_PRICE;
        uint8 PUBLIC_SALE_MAX_PURCHASE;
        uint8 PRE_SALE_MAX_PURCHASE;
        bool PUBLIC_SALE_IS_ACTIVE;
        bool PRE_SALE_IS_ACTIVE;
    }

    string public WOBBLEBUGS_PROVENANCE;
    SaleConfig private _config;
    bool private _canReserve = true;
    string private _baseTokenURI;

    mapping (address => WhitelisterStatus) private _whitelistedAddresses;

    constructor (string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _config = SaleConfig(
            10000, // supply
            150, // team reserve
            0.063 ether, // mint price
            20, // max mint public
            10, // max mint presale
            false, // public sale active
            false // pre sale active
        );
        _baseTokenURI = baseTokenURI;
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0x435Cd3902d1b4f4E842F2C0fd5028EEE71dd099C).transfer(((balance * 50) / 10) / 100);
        payable(0x0cB121E3e18c364F318A1FB97bd304e5855c8250).transfer(((balance * 50) / 10) / 100);
        payable(0x927e093B623F90a0311C03009aA1D1DF4cf08634).transfer(((balance * 200) / 10) / 100);
        payable(0x0048D02963b97445a012Ad6D44Bd38A0239C5B88).transfer(((balance * 200) / 10) / 100);
        payable(0x491dc513212E0b896690B6Fb4483929f0Abde975).transfer(((balance * 200) / 10) / 100);
        payable(0x0f075aC7186A8D43c1b6A819B5BCEff7c936d7Cf).transfer(((balance * 125) / 10) / 100);
        payable(0xe1Db3822239a27451b68a0cfFC19a9160EE36f75).transfer(((balance * 175) / 10) / 100);
    }

    function emergencyWithdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance), ":-(");
    }
    
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        WOBBLEBUGS_PROVENANCE = provenanceHash;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function togglePublicSale() external onlyOwner {
        _config.PUBLIC_SALE_IS_ACTIVE = !_config.PUBLIC_SALE_IS_ACTIVE;
    }

    function togglePreSale() external onlyOwner {
        _config.PRE_SALE_IS_ACTIVE = !_config.PRE_SALE_IS_ACTIVE;
    }

    function isPublicSaleActive() external view returns (bool status) {
        return _config.PUBLIC_SALE_IS_ACTIVE;
    }

    function isPreSaleActive() external view returns (bool status) {
        return _config.PRE_SALE_IS_ACTIVE;
    }

    function isWhitelisted(address wallet) external view returns (bool status) {
        return _whitelistedAddresses[wallet] != WhitelisterStatus.Invalid;
    }
    
    function updateWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistedAddresses[addresses[i]] = WhitelisterStatus.Unclaimed;
        }
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);

            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }

            return result;
        }
    }
    
    function mintWobblebugs(uint numberOfTokens) external payable nonReentrant() {
        require(_config.PUBLIC_SALE_IS_ACTIVE || _config.PRE_SALE_IS_ACTIVE, "Sale must be active to mint Wobblebugs");
        require(msg.value == numberOfTokens * _config.WOBBLEBUG_PRICE, "Ether value sent is not correct");
        
        if (_config.PRE_SALE_IS_ACTIVE) {
            require(numberOfTokens > 0 && numberOfTokens <= _config.PRE_SALE_MAX_PURCHASE, "Can only mint max 10 tokens at a time");
            require(_whitelistedAddresses[msg.sender] != WhitelisterStatus.Claimed, "You've already minted");
            require(_whitelistedAddresses[msg.sender] == WhitelisterStatus.Unclaimed, "You are not whitelisted, wait for the public mint");
        }
        else if (_config.PUBLIC_SALE_IS_ACTIVE) {
            require(numberOfTokens > 0 && numberOfTokens <= _config.PUBLIC_SALE_MAX_PURCHASE, "Can only mint max 20 tokens at a time");
        }

        _mintMultiple(msg.sender, numberOfTokens);
        if (_config.PRE_SALE_IS_ACTIVE) _whitelistedAddresses[msg.sender] = WhitelisterStatus.Claimed;
    }

    function reserve(address to, uint256 amount) external onlyOwner {
        require(amount > 0 && amount <= _config.DEV_RESERVED);

        _mintMultiple(to, amount);
        _config.DEV_RESERVED = _config.DEV_RESERVED - uint8(amount);
    }

    function _mintMultiple(address owner, uint256 amount) private {
        require(totalSupply() + amount <= _config.MAX_WOBBLEBUGS, "Mint would exceed max supply of Wobblebugs");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(owner, totalSupply());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}