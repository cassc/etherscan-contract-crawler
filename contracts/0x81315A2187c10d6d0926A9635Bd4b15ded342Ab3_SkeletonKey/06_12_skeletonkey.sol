// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract SkeletonKey is ERC721A, Ownable, Pausable, DefaultOperatorFilterer {
    uint256 public constant _maxCarryWeight = 444;
    uint256 public _chestSize = 444;
    bool public _safePassageActive = true;
    bool public _walkThePlankActive = false;
    bytes32 public _friendlyShipsRoster;
    mapping(address => uint256) public _lootCounter;
    uint256 public _lootCost = 0.69 ether;

    constructor() ERC721A("SkeletonKey", "DD") {
        _pause();
    }

    function setFriendlyShipsRoster(bytes32 roster) external onlyOwner {
        _friendlyShipsRoster = roster;
    }

    function setLootCost(uint256 cost) external onlyOwner {
        _lootCost = cost;
    }

    function payTribute(address to, uint256 quantity) external onlyOwner {
        _checkScuttlebutt(quantity);
        _safeMint(to, quantity);
    }

    function loot(
        uint256 quantity,
        uint256 totalQuantity,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(
            _isAllowedPassage(msg.sender, totalQuantity, merkleProof),
            "Yer address be not on th' safe passage list, matey."
        );

        _checkLootPrice(quantity, msg.value);
        _checkScuttlebuttQuantity(msg.sender, quantity, totalQuantity);
        _checkScuttlebutt(quantity);

        _safeMint(msg.sender, quantity);
        _lootCounter[msg.sender] += quantity;
    }

    function isAllowedPassage(
        address addr,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        return _isAllowedPassage(addr, quantity, merkleProof);
    }

    function setSafePassage(bool whitelistActive) external onlyOwner {
        _safePassageActive = whitelistActive;
    }

    function lowerTheAnchor() external onlyOwner {
        _pause();
    }

    function raiseTheAnchor() external onlyOwner {
        _unpause();
    }

    function _isAllowedPassage(
        address addr,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                _friendlyShipsRoster,
                keccak256(abi.encodePacked(addr, quantity))
            );
    }

    function _checkLootPrice(uint256 quantity, uint256 bribe) internal view {
        require(
            bribe == quantity * _lootCost,
            "Arrr, ye scurvy dog! Ye sent the wrong amount! Walk the plank ye shall!"
        );
    }

    function _checkScuttlebutt(uint256 quantity) internal view {
        require(
            quantity > 0,
            "Avast ye! The amount must be greater than 0, me hearty!"
        );
        require(
            quantity <= _chestSize - totalSupply(),
            "Shiver me timbers! Thar be not enough tokens left in the chest, ye scallywag. Check yer booty and see if ye have enough."
        );
    }

    function _checkScuttlebuttQuantity(
        address addr,
        uint256 quantity,
        uint256 totalQuantity
    ) internal view {
        require(
            quantity > 0,
            "Avast ye! The amount must be greater than 0, me hearty!"
        );

        uint256 totalMinted = (_lootCounter[addr]) + (quantity);
        require(
            (totalMinted <= totalQuantity),
            "Ahoy, me hearties! The token chest be runnin' low, and we don't have enough for yer ship."
        );
    }

    function plunder(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function toggleWalkThePlank() external onlyOwner {
        _walkThePlankActive = !_walkThePlankActive;
    }

    function walkThePlank(uint256 tokenId) external payable {
        require(_walkThePlankActive, "Walk the plank is not allowd mate!");
        _burn(tokenId, true);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _contractBaseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function _toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function deposit() external payable {}

    using SafeMath for uint256;
    string public _contractBaseURI = "ipfs://kackmahaaaa/";
}