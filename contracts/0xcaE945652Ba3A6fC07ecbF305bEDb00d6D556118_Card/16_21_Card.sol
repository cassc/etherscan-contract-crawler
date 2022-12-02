// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {
    DefaultOperatorFilterer1155Upgradeable
} from "./DefaultOperator/DefaultOperatorFilterer1155Upgradeable.sol"; 
import './RandomlyAssigned.sol';

interface IPack {
    function burnPack(uint256 _tokenId) external returns(bool);
    function burn(uint256 _tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}
contract Card is ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC2981Upgradeable, DefaultOperatorFilterer1155Upgradeable {
    using StringsUpgradeable for uint256;

    uint256 constant COMMON_1_SUPPLY = 125;
    uint256 constant RARE_1_SUPPLY = 25;
    uint256 constant RARE_2_SUPPLY = 50;
    uint256 constant LEGENDARY_SUPPLY = 10;
    uint256 constant MYTHICS_SUPPLY = 5;

    uint256 constant COMMON_1_COUNT = 146;
    uint256 constant RARE_1_COUNT = 198;
    uint256 constant RARE_2_COUNT = 18;
    uint256 constant LEGENDARY_COUNT = 40;
    uint256 constant MYTHICS_COUNT = 8;
    
    address public packContract;

    uint256 common1_lastNumber;
    uint256 rare1_lastNumber;
    uint256 rare2_lastNumber;
    uint256 legendary_lastNumber;
    uint256 mythics_lastNumber;

    mapping(address => mapping(uint256 => uint256)) mintedAmounts;
    mapping(uint256 => address[]) twoMintedAddresses;

    string baseURI;

    RandomlyAssigned public characterRandomlyAssigned;

    function initialize(address _packContract)  public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __DefaultOperatorFilterer1155_init();
        packContract = _packContract;
       
        common1_lastNumber = COMMON_1_COUNT * COMMON_1_SUPPLY;
        rare1_lastNumber = common1_lastNumber + RARE_1_COUNT * RARE_1_SUPPLY;
        rare2_lastNumber = rare1_lastNumber + RARE_2_COUNT * RARE_2_SUPPLY;
        legendary_lastNumber = rare2_lastNumber + LEGENDARY_COUNT * LEGENDARY_SUPPLY;
        mythics_lastNumber = legendary_lastNumber + MYTHICS_COUNT * MYTHICS_SUPPLY;
        
        characterRandomlyAssigned = new RandomlyAssigned(mythics_lastNumber, address(this));
    }

    function burnPack(uint256 _packId) public whenNotPaused{
        require(IPack(packContract).ownerOf(_packId) == msg.sender, "You are not the owner of this pack");
        IPack(packContract).burn(_packId);

        _mintCards();
    }

    function _mintCards() private {
        for (uint256 i = 0; i < 3; i++) {
            uint256 randomCharacterNumber = characterRandomlyAssigned.nextToken();
            uint256 characterTokenId;

            if (randomCharacterNumber <= common1_lastNumber) {
                characterTokenId = randomCharacterNumber % COMMON_1_COUNT + 1;
            } else if (randomCharacterNumber <= rare1_lastNumber) {
                characterTokenId = randomCharacterNumber % RARE_1_COUNT + 1 + COMMON_1_COUNT;
            } else if (randomCharacterNumber <= rare2_lastNumber) {
                characterTokenId = randomCharacterNumber % RARE_2_COUNT + 1 + COMMON_1_COUNT + RARE_1_COUNT;
            } else if (randomCharacterNumber <= legendary_lastNumber) {
                characterTokenId = randomCharacterNumber % LEGENDARY_COUNT + 1 + COMMON_1_COUNT + RARE_1_COUNT + RARE_2_COUNT;
            } else {
                characterTokenId = randomCharacterNumber % MYTHICS_COUNT + 1 + COMMON_1_COUNT + RARE_1_COUNT + RARE_2_COUNT + LEGENDARY_COUNT;
            }

             mintedAmounts[msg.sender][characterTokenId] += 1;
             if (mintedAmounts[msg.sender][characterTokenId] >= 2) {
                    twoMintedAddresses[characterTokenId].push(msg.sender);
             }
            _mint(msg.sender, characterTokenId, 1, "");
        }
    }

    function getTwoMintedAddresses(uint256 _tokenId) public view returns(address[] memory) {
        return twoMintedAddresses[_tokenId];
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function operatorInitialize() public reinitializer(2) onlyOwner {
        __DefaultOperatorFilterer1155_init();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}