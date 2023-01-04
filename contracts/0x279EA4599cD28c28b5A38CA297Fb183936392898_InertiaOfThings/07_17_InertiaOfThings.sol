// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract InertiaOfThings is
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC1967UpgradeUpgradeable
{
    uint256 public constant MAX_SUPPLY = 671;

    address public admin;
    uint256 public maxMintPerWallet;
    uint256 public energyRequirement;
    string public baseTokenURI;
    bool isMoving;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier mintCompliance(uint256 p) {
        require(msg.sender == tx.origin, "no bots");
        require(totalSupply() + p <= MAX_SUPPLY, "max supply reached");
        require(_numberMinted(msg.sender) + p <= maxMintPerWallet, "max mint per wallet reached");
        _;
    }

    modifier priceCompliance(uint256 p) {
        require(msg.value >= p * energyRequirement, "insufficient funds");
        _;
    }

    function initialize() external initializerERC721A initializer {
        __ERC721A_init("Inertia of Things", "Inertia20x3");

        admin = msg.sender;
        energyRequirement = 0.01 ether;
        maxMintPerWallet = 3;
    }

    function giveMomentum(uint256 p) external payable mintCompliance(p) priceCompliance(p) {
        require(isMoving, "initial momentum is zero for stationary objects");
        _safeMint(msg.sender, p);
    }

    function ownerMint(uint256 amount, address to) external onlyAdmin {
        require(amount + totalSupply() <= MAX_SUPPLY, "max supply reached");
        _safeMint(to, amount);
    }

    function ownerBurn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function giveInitialPush(bool move) external onlyAdmin {
        isMoving = move;
    }

    function setEnergyRequirement(uint256 joules) external onlyAdmin {
        energyRequirement = joules;
    }

    function setBaseURI(string memory uri) external onlyAdmin {
        baseTokenURI = uri;
    }

    function withdraw() external onlyAdmin {
        (bool success, ) = admin.call{ value: address(this).balance }("");
        require(success, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}