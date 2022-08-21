// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Yakuza Inc - ELITE
 * ERC-721A Minting contract with Token Locking, Burn/Redemption of Yakuza Genesis Tokens.
 * S/O to owl of moistness for locking inspiration, @ChiruLabs for ERC721A.
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

interface ITempura {
    function startDripping(address addr, uint128 multiplier) external;

    function stopDripping(address addr, uint128 multiplier) external;
}

contract YakuzaElite is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct GenLegend {
        bool legendary;
        bool claimed;
    }

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 333;

    IERC721 public constant YAKUZA = IERC721(0x0EE1448F200e6e65E9bad7A335E3FFb674c0f68C);

    ITempura public Tempura;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(uint256 => uint256) public tierByToken;
    mapping(uint256 => uint256) public genTier;
    mapping(uint256 => GenLegend) public genLegendaries;
    mapping(uint256 => bool) public lockStatus;
    mapping(uint256 => uint256) public lockData;

    bool public isSaleActive;
    bool public lockingAllowed;

    uint256 public eliteCounter;

    event Lock(uint256 token, uint256 timeStamp, address user);
    event Unlock(uint256 token, uint256 timeStamp, address user);

    /*
    ================================================
                        MODIFIERS        
    ================================================
*/
    modifier SaleActive() {
        require(isSaleActive, "Sale is not open");
        _;
    }

    constructor() ERC721A("Yakuza Elite", "YKELITE") {}

    /*
    ================================================
            Public/External Write Functions         
    ================================================
*/

    function mintElite(uint256[] calldata tokens) public SaleActive nonReentrant {
        require(eliteCounter < 310, "All regular elites have been Claimed");
        uint256 value = _calculateValue(tokens);
        require(value == 6 || value == 3, "You are not burning the correct number of tokens");
        for (uint256 i; i < tokens.length; i++) {
            YAKUZA.transferFrom(msg.sender, BURN_ADDRESS, tokens[i]);
        }
        if (value == 3) {
            unchecked {
                eliteCounter++;
            }
            _mint(msg.sender, 1);
        }
        if (value == 6) {
            unchecked {
                eliteCounter++;
            }
            tierByToken[_currentIndex] = 1;
            _mint(msg.sender, 1);
        }
    }

    function mintLegendary(uint256 legendary, uint256[] calldata tokens)
        external
        SaleActive
        nonReentrant
    {
        require(_totalMinted() < 333, "All Elites have been claimed");
        require(genLegendaries[legendary].legendary == true, "You must select a valid Legendary");
        require(
            genLegendaries[legendary].claimed == false,
            "This legendary has already claimed their Elite"
        );
        uint256 value = _calculateValue(tokens);
        require(value == 3, "You are not burning the correct number of tokens");
        for (uint256 i; i < tokens.length; i++) {
            YAKUZA.transferFrom(msg.sender, BURN_ADDRESS, tokens[i]);
        }
        tierByToken[_currentIndex] = 2;
        genLegendaries[legendary].claimed = true;
        _mint(msg.sender, 1);
    }

    function ownerMint(uint256 quantity) external nonReentrant onlyOwner {
        require(_totalMinted() < 333, "All Elites have been claimed");
        eliteCounter += quantity;
        _mint(msg.sender, quantity);
    }

    function lockTokens(uint256[] calldata tokenIds) external nonReentrant {
        require(lockingAllowed, "Locking is not currently allowed.");
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            _lockToken(tokenIds[i]);
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
        }
        Tempura.startDripping(msg.sender, value);
    }

    function unlockTokens(uint256[] calldata tokenIds) external {
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
            _unlockToken(tokenIds[i]);
        }
        Tempura.stopDripping(msg.sender, value);
    }

    /*
    ================================================
               ACCESS RESTRICTED FUNCTIONS        
    ================================================
*/
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setTier(uint256[] calldata tokenIds, uint128 tier) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            tierByToken[tokenIds[i]] = tier;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function unlockBadTokens(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            uint128 value;
            if (tierByToken[tokens[i]] != 0) value += 20;
            else value += 10;
            Tempura.stopDripping(ownerOf(tokens[i]), value);
            _unlockToken(tokens[i]);
        }
    }

    function setGenTierData(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            genTier[tokens[i]] = 1;
        }
    }

    function setLegendaries(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            genLegendaries[tokens[i]].legendary = true;
        }
    }

    function setTempura(address tempura) external onlyOwner {
        Tempura = ITempura(tempura);
    }

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function toggleLocking() external onlyOwner {
        lockingAllowed = !lockingAllowed;
    }

    /*
    ================================================
                Internal Write Functions         
    ================================================
*/

    function _lockToken(uint256 tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "You must own a token in order to lock it");
        lockStatus[tokenId] = true;
        lockData[tokenId] = block.timestamp;
        emit Lock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _unlockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        lockStatus[tokenId] = false;
        lockData[tokenId] = 0;
        emit Unlock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        bool lock = false;
        for (uint256 i; i < quantity; i++) {
            if (lockStatus[startTokenId + i] == true) {
                lock = true;
            }
        }
        require(lock == false, "Token Locked");
    }

    /*
    ================================================
                    VIEW FUNCTIONS        
    ================================================
*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function _calculateValue(uint256[] calldata tokens) internal view returns (uint256) {
        uint256 value;
        for (uint256 i; i < tokens.length; i++) {
            uint256 tokenVal = genTier[tokens[i]];
            if (tokenVal == 0) {
                unchecked {
                    value += 1;
                }
            } else {
                unchecked {
                    value += 2;
                }
            }
        }
        return value;
    }
}