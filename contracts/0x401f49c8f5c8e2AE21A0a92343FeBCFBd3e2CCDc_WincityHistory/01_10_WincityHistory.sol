// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";
import "./IERC1155Balance.sol";

error InvalidClaimInput();
error AlreadyClaimed();
error NotCardOwner();
error ClaimNotOpened();
error NoSupplyLeft();
error InsufficientAmount();

contract WincityHistory is ERC721A, Ownable, Pausable {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constants
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint16 public constant RARITY_RANGE1_LASTID = 1;
    uint16 public constant RARITY_RANGE2_LASTID = 11;
    uint16 public constant RARITY_RANGE3_LASTID = 111;
    uint16 public constant RARITY_RANGE4_LASTID = 1111;
    uint16 public constant MAX_SUPPLY = 3333;
    address private constant wincityParis =
        0x326374475908FC640C3DDE59981C721CafF9c828;
    address private constant wincityLille =
        0x220C8189bf9D816E1891aF3e68dDe37412165A36;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Storage
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 public claimStartTimestamp;

    mapping(bytes32 => bool) internal _claimed;
    string private _tokenBaseURI;
    uint256 public publicMintPrice = 0.05 ether;
    uint256 public publicMaxSupply;
    uint256 public publicCurrentSupply;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Events
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    event Claimed(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Constructor
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721A(_name, _symbol) {
        _tokenBaseURI = _uri;

    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Modifiers
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier whenClaimActive() {
        if (!isClaimActive()) {
            revert ClaimNotOpened();
        }
        _;
    }

    function isClaimActive() public view returns (bool) {
        return
            claimStartTimestamp > 0
                ? block.timestamp >= (claimStartTimestamp)
                : false;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Admin
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string calldata _newURI) external onlyOwner {
        _tokenBaseURI = _newURI;
    }

    function setClaimStartTimestamp(uint256 _timestamp) external onlyOwner {
        claimStartTimestamp = _timestamp;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        publicMintPrice = _price;
    }

    function setPublicSupply(uint256 _supply) external onlyOwner {
        publicMaxSupply = _supply;
    }

    function adminMint(address recipient, uint256 count) external onlyOwner {
        if (totalSupply() + count > MAX_SUPPLY) {
            revert NoSupplyLeft();
        }

        _mint(recipient, count);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Getters
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function checkClaimStatus(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool isClaimed)
    {
        isClaimed = _claimed[
            keccak256(abi.encodePacked(contractAddress, tokenId))
        ];
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Claim
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function claim(address contractAddress, uint256 tokenId)
        external
        whenClaimActive
        whenNotPaused
    {
        if (
            contractAddress != wincityParis && contractAddress != wincityLille
        ) {
            revert InvalidClaimInput();
        }

        uint256 cardBalance = IERC1155Balance(contractAddress).balanceOf(
            msg.sender,
            tokenId
        );
        if (cardBalance < 1) {
            revert NotCardOwner();
        }

        uint8 claimableCount = 1;
        if (contractAddress == wincityParis) {
            if (tokenId <= RARITY_RANGE1_LASTID) {
                claimableCount = 4;
            } else if (tokenId <= RARITY_RANGE2_LASTID) {
                claimableCount = 3;
            } else if (tokenId <= RARITY_RANGE3_LASTID) {
                claimableCount = 2;
            }
        }

        if (totalSupply() + claimableCount > MAX_SUPPLY - publicMaxSupply) {
            revert NoSupplyLeft();
        }

        bytes32 claimedMapKey = keccak256(
            abi.encodePacked(contractAddress, tokenId)
        );

        if (_claimed[claimedMapKey]) {
            revert AlreadyClaimed();
        }
        _claimed[claimedMapKey] = true;

        _mint(msg.sender, claimableCount);
        emit Claimed(contractAddress, tokenId, claimableCount);
    }


    function purchase(uint256 _count)
        external
        payable
        whenClaimActive
        whenNotPaused
    {

        if (publicCurrentSupply + _count > publicMaxSupply) {
            revert NoSupplyLeft();
        }

        if ( msg.value < _count * publicMintPrice ) {
            revert InsufficientAmount();
        }
        publicCurrentSupply += _count;
        _mint(msg.sender, _count);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function withdrawAmount(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        (bool succeed,) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }
}