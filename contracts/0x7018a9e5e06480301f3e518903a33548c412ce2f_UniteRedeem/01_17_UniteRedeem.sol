// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract UniteRedeem is
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    event Redeem(address indexed sender, uint256 indexed tokenId);

    string private _baseTokenURI;
    bool public canRedeem;

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseUri) external onlyOwner {
        _baseTokenURI = baseUri;
    }

    // Batch Airdrop
    function batchAirdrop(
        address[] calldata recipients,
        uint64[] calldata nums
    ) external onlyOwner {
        uint256 length = recipients.length;
        require(length > 0, "No Accounts Provided");
        require(length == nums.length, "Invalid Arguments");

        for (uint256 i = 0; i < length; ) {
            _safeMint(recipients[i], nums[i]);
            unchecked {
                i++;
            }
        }
    }

    // Airdrop
    function airdrop(address to, uint32 num) external onlyOwner {
        _safeMint(to, num);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether to withdraw!");
        payable(msg.sender).transfer(balance);
    }

    function setCanRedeem(bool b) external onlyOwner {
        canRedeem = b;
    }

    function redeem(uint256 tokenId) external nonReentrant {
        require(canRedeem, "redeem not open!");
        _burn(tokenId, true);
        emit Redeem(msg.sender, tokenId);
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    /**
     * OpenSea DefaultOperatorFilterer
     */
    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}