// SPDX-License-Identifier: MIT
/*
      ___           ___           ___                       ___                    ___           ___           ___     
     /\__\         /\__\         /\  \                     /\__\                  /\  \         /\  \         /\__\    
    /:/ _/_       /:/ _/_       /::\  \       ___         /:/ _/_                /::\  \        \:\  \       /:/ _/_   
   /:/ /\  \     /:/ /\__\     /:/\:\__\     /\__\       /:/ /\__\              /:/\:\  \        \:\  \     /:/ /\__\  
  /:/ /::\  \   /:/ /:/ _/_   /:/ /:/  /    /:/__/      /:/ /:/ _/_            /:/  \:\  \   _____\:\  \   /:/ /:/ _/_ 
 /:/_/:/\:\__\ /:/_/:/ /\__\ /:/_/:/__/___ /::\  \     /:/_/:/ /\__\          /:/__/ \:\__\ /::::::::\__\ /:/_/:/ /\__\
 \:\/:/ /:/  / \:\/:/ /:/  / \:\/:::::/  / \/\:\  \__  \:\/:/ /:/  /          \:\  \ /:/  / \:\~~\~~\/__/ \:\/:/ /:/  /
  \::/ /:/  /   \::/_/:/  /   \::/~~/~~~~   ~~\:\/\__\  \::/_/:/  /            \:\  /:/  /   \:\  \        \::/_/:/  / 
   \/_/:/  /     \:\/:/  /     \:\~~\          \::/  /   \:\/:/  /              \:\/:/  /     \:\  \        \:\/:/  /  
     /:/  /       \::/  /       \:\__\         /:/  /     \::/  /                \::/  /       \:\__\        \::/  /   
     \/__/         \/__/         \/__/         \/__/       \/__/                  \/__/         \/__/         \/__/    
                                                       ___           ___           ___           ___                   
     _____                              _____         /\  \         /|  |         /\  \         /\  \                  
    /::\  \         ___                /::\  \       /::\  \       |:|  |        /::\  \        \:\  \                 
   /:/\:\  \       /|  |              /:/\:\  \     /:/\:\  \      |:|  |       /:/\:\  \        \:\  \                
  /:/ /::\__\     |:|  |             /:/  \:\__\   /:/ /::\  \   __|:|  |      /:/ /::\  \   _____\:\  \               
 /:/_/:/\:|__|    |:|  |            /:/__/ \:|__| /:/_/:/\:\__\ /\ |:|__|____ /:/_/:/\:\__\ /::::::::\__\              
 \:\/:/ /:/  /  __|:|__|            \:\  \ /:/  / \:\/:/  \/__/ \:\/:::::/__/ \:\/:/  \/__/ \:\~~\~~\/__/              
  \::/_/:/  /  /::::\  \             \:\  /:/  /   \::/__/       \::/~~/~      \::/__/       \:\  \                    
   \:\/:/  /   ~~~~\:\  \             \:\/:/  /     \:\  \        \:\~~\        \:\  \        \:\  \                   
    \::/  /         \:\__\             \::/  /       \:\__\        \:\__\        \:\__\        \:\__\                  
     \/__/           \/__/              \/__/         \/__/         \/__/         \/__/         \/__/ 
*/


pragma solidity ^0.8.19;

import {IERC721AUpgradeable, ERC721AUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import { IERC2981Upgradeable, ERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";



contract DakanPass is
    ERC721AUpgradeable,
    UUPSUpgradeable, 
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable, 
    AccessControlEnumerableUpgradeable, 
    OperatorFilterer 
{
    using StringsUpgradeable for uint256;

    string private _baseTokenURI;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant TOTAL_SUPPLY_CAP = 10000;
    uint256 public currentSupplyCount = 1;
    uint256 public constant ADMIN_MINT = 500;
    uint256 public mintPrice;
    mapping(address => bool) private _blacklist;
    bool private initialized;
    uint256 public adminMintCount = 0;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    struct SaleState {
        bool soldOut;
        bool publicSaleOpen;
    }
    SaleState public saleState;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!_blacklist[account], "This address is blacklisted");
        _;
    }

    event SoldOut();

    function initialize() initializerERC721A initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(!initialized, "Already initialized");
        initialized = true;
        __ERC721A_init("Dakan Series One", "DS1");
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();
        __AccessControlEnumerable_init();
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        _safeMint(_msgSender(), ADMIN_MINT, "");
        currentSupplyCount += ADMIN_MINT;
    }

    function mint(address to, uint256 quantity) external payable notBlacklisted(msg.sender) nonReentrant {
        require(quantity > 0 && quantity <= 10, "Quantity should be between 1 and 10");
        require(!saleState.soldOut, "Already minted out");
        require(saleState.publicSaleOpen || _isInitializer(msg.sender), "Public sale not started");
        require(currentSupplyCount + quantity <= TOTAL_SUPPLY_CAP - ADMIN_MINT, "Supply exceeded");

        if (!_isInitializer(msg.sender)) {
            require(msg.value == mintPrice * quantity, "Incorrect ether sent");
        }

        _safeMint(to, quantity, "");
        currentSupplyCount += quantity;

        if (currentSupplyCount == TOTAL_SUPPLY_CAP - ADMIN_MINT) {
            saleState.soldOut = true;
            emit SoldOut();
        }
    }

    function adminMint(address to, uint256 quantity) external onlyAdmin {
        require(adminMintCount + quantity <= ADMIN_MINT, "Exceeds admin mint limit");
        
        _safeMint(to, quantity, "");
        adminMintCount += quantity;
    }

    function setMintPrice(uint256 newPrice) external onlyAdmin {
        mintPrice = newPrice;
    }

    function _isInitializer(address user) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }
    
    function togglePublicSale() external onlyAdmin {
        saleState.publicSaleOpen = !saleState.publicSaleOpen;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable) notBlacklisted(msg.sender) notBlacklisted(to) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable) notBlacklisted(msg.sender) notBlacklisted(to) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public payable override(ERC721AUpgradeable) notBlacklisted(msg.sender) notBlacklisted(to) onlyAllowedOperatorApproval(to)  {
        super.approve(to, tokenId);
    }


    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable) notBlacklisted(msg.sender) notBlacklisted(operator) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function setBaseURI(string memory newBaseURI) external onlyAdmin {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "s1pass: NonExistentToken");
        return string(abi.encodePacked(_baseTokenURI));
    }

    function currentSupply() external view returns (uint256) {
        return currentSupplyCount;
    }

    function withdrawFunds() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function addToBlacklist(address account) external onlyAdmin {
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) external onlyAdmin {
        _blacklist[account] = false;
    }

    function isBlacklisted(address account) external view onlyAdmin returns(bool) {
        return _blacklist[account];
    }


    receive() external payable {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, ERC2981Upgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyAdmin {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}