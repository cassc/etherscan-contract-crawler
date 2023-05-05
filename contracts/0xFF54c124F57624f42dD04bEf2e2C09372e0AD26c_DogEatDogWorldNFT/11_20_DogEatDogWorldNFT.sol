// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract DogEatDogWorldNFT is
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable,
    ERC721AUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    uint256 public startingTime;
    address public owner;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant WL_MAX_LIMIT = 3;
    uint256 public constant MAX_LIMIT = 10;
    uint256 public constant MINT_FEE_WL = 0.006 ether;
    uint256 public constant MINT_FEE = 0.009 ether;

    // Base URL string
    string private baseURL;

    //Merkel tree root for whitelisting addresses
    bytes32 private merkleRoot;

    mapping(address => uint256) public ogListed;

    bool public isRevealed;

    enum PhasesEnum {
        WHITELIST,
        PUBLIC
    }

    PhasesEnum currentPhase;

    error MAX_SUPPLY_REACHED();
    error NOT_MINT_0_NFT();
    error MINTING_IS_NOT_ALLOWED();
    error INSUFFICIENT_FUNDS();
    error USER_NOT_WHITELISTED();
    error NOT_MINT_MORE_THAN_3();
    error NOT_MINT_MORE_THAN_10();

    function initialize() public initializerERC721A {
        __ERC721A_init("Dog Eat Dog World", "DEDW");
        owner = msg.sender;
        isRevealed = false;
        currentPhase = PhasesEnum.WHITELIST;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner{
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) public onlyOwner{
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Returns the token URL of the NFT .
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (isRevealed) {
            return
                bytes(baseURL).length > 0
                    ? string(
                        abi.encodePacked(baseURL, tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return
                bytes(baseURL).length > 0
                    ? string(abi.encodePacked(baseURL, "unRevealed.json"))
                    : "";
        }
    }

    /**
     * @dev Set the base URL of the NFT .
     * Can only be called by owner.
     */
    function setbaseURI(string memory _uri) external onlyOwner {
        baseURL = _uri;
    }

    function startMinting() external onlyOwner {
        startingTime = block.timestamp;
    }

    function updateTime(uint256 _time) external onlyOwner {
        startingTime = _time;
    }

    /**
     * @dev Sets merkelRoot varriable.
     * Only owner can call it.
     */
    function setMerkelRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkelRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function safeMint(
        bytes32[] calldata _merkleProof,
        uint256 quantity
    ) public payable {
        if (quantity == 0) revert NOT_MINT_0_NFT();
        if (startingTime == 0) revert MINTING_IS_NOT_ALLOWED();
        if (totalSupply().add(quantity) > MAX_SUPPLY)
            revert MAX_SUPPLY_REACHED();

        if (
            currentPhase == PhasesEnum.WHITELIST &&
            block.timestamp >= startingTime + 2 hours
        ) {
            currentPhase = PhasesEnum.PUBLIC;
        }

        if (currentPhase == PhasesEnum.WHITELIST) {
            if (msg.value != MINT_FEE_WL.mul(quantity))
                revert INSUFFICIENT_FUNDS();
            if (
                MerkleProofUpgradeable.verify(
                    _merkleProof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ) == false
            ) revert USER_NOT_WHITELISTED();
            if ((ogListed[msg.sender] + quantity) > WL_MAX_LIMIT)
                revert NOT_MINT_MORE_THAN_3();
            ogListed[msg.sender] = (ogListed[msg.sender] + quantity);
            _mint(msg.sender, quantity);
        } else if (currentPhase == PhasesEnum.PUBLIC) {
            if (msg.value != MINT_FEE.mul(quantity))
                revert INSUFFICIENT_FUNDS();
            if (quantity > MAX_LIMIT) revert NOT_MINT_MORE_THAN_10();
            _mint(msg.sender, quantity);
        }
    }

    // Withdraw ether balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function getPrice() external view returns (uint256) {
        if (currentPhase == PhasesEnum.WHITELIST) {
            return MINT_FEE_WL;
        } else if (block.timestamp >= startingTime + 2 hours) {
            return MINT_FEE;
        } else {
            return 0;
        }
    }

    function reveal(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    // Overrides new functions royality enforement

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}