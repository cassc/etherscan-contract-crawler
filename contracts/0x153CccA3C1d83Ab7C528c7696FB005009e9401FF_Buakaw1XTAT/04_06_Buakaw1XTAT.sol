// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Buakaw1XTAT is ERC721A, Ownable, ReentrancyGuard {
    event WithdrawMoney(
        uint256 indexed blocktime,
        uint256 indexed amount,
        address indexed sender
    );

    uint256 public immutable collectionSize;
    address public immutable mainCollectionAddress;

    address public immutable vaultAddress;
    // address public immutable bridgeAddress;
    mapping(address => bool) public NotEOAAddresses;

    constructor(address mainColllectionAddr, address _vaultAddress)
        ERC721A("Buakaw1XTAT", "BK1TAT")
    {
        mainCollectionAddress = mainColllectionAddr;
        collectionSize = IERC721A(mainColllectionAddr).totalSupply();
        vaultAddress = _vaultAddress;
    }

    function setNotEOAAddresses(address _addr, bool isEOA) external onlyOwner {
        NotEOAAddresses[_addr] = isEOA;
    }

    function setBatchNotEOAAddresses(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            NotEOAAddresses[addresses[i]] = true;
        }
    }

    function airdrop(uint256 amount) public nonReentrant onlyOwner {
        require(
            totalSupply() + amount <= collectionSize,
            "Max supply exceeded"
        );

        uint256 currentTokenId = _nextTokenId();
        for (uint256 i = currentTokenId; i < currentTokenId + amount; i++) {
            address tokenOwner = IERC721A(mainCollectionAddress).ownerOf(i);
            if (NotEOAAddresses[tokenOwner]) {
                _mint(vaultAddress, 1);
            } else {
                _mint(tokenOwner, 1);
            }
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        emit WithdrawMoney(block.timestamp, address(this).balance, msg.sender);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    receive() external payable {}
}