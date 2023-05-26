// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './ERC721Tradable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Alfie
 * @author Alfie Core Team
 * @notice ERC721 contract that supports Alfie World Co.
 */
contract ALFIE is ERC721Tradable, ReentrancyGuard {
    using Address for address;
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];
    using SafeERC20 for IERC20;
    using Strings for uint256;

    string public baseTokenURI;

    /**
     * @notice Root of the merkle tree used for presale access
     */
    bytes32 public merkleRoot;

    /**
     * @notice Alfie mint price
     */

    uint256 public AlfiePrice = .05 ether;

    /**
     * @notice Max number of Alfies that can be purchased during presale
     */
    uint256 public constant maxAlfiePurchasePresale = 5;

    /**
     * @notice Max number of Alfies that can be purchased during sale
     */
    uint256 public constant maxAlfiePurchase = 10;

    /**
     * @notice Total Alfies supply
     */
    uint256 public constant maxAlfies = 8888;

    uint256 private alfieReserve = 500;

    /**
     * @notice Presale start time
     */
    uint256 public presaleStartTime = 1653242400;

    /**
     * @notice Sale start time
     */
    uint256 public startTime = 1653249600;

    string private _name;

    string private _symbol;

    Counters.Counter private _alfiesId;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(address _proxyRegistryAddress) ERC721Tradable('Alfie World Co.', 'ALFIE', _proxyRegistryAddress) {
        _alfiesId.increment();
    }

    /**
     * @notice Update merkle root for presale access
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Recover function
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice ERC20 Recover function
     */
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
    }

    /**
     * @notice Getter to access Alfie current supply
     */
    function totalSupply() external view returns (uint256) {
        return _alfiesId.current() - 1;
    }

    /**
     * @notice Function to mint Alfies for the core team
     */
    function reserveAlfies(address _to, uint256 _reserveAmount) public onlyOwner {
        uint256 currentSupply = _alfiesId.current() - 1;
        uint256 _startTime = startTime;
        require(_startTime > 0 && block.timestamp >= _startTime, 'Sale must be active to mint Alfies');
        require(_reserveAmount > 0 && _reserveAmount <= alfieReserve, 'Not enough reserve left for team');
        require(currentSupply + _reserveAmount <= maxAlfies, 'Purchase would exceed max supply of Alfies');
        for (uint256 i = 1; i <= _reserveAmount; i++) {
            _safeMint(_to, currentSupply + i);
            _alfiesId.increment();
        }
        alfieReserve = alfieReserve - _reserveAmount;
    }

    /**
     * @notice Set the sale start time
     */
    function setStartTime(uint256 _startTime) public onlyOwner {
        // require(_startTime > block.timestamp - 1000, 'Sale should start in the future');
        startTime = _startTime;
    }

    /**
     * @notice Set the presale start time
     */
    function setPresaleStartTime(uint256 _presaleStartTime) public onlyOwner {
        presaleStartTime = _presaleStartTime;
    }

    /**
     * @notice Set the price of Alfie
     */
    function setAlfiePrice(uint256 _AlfiePrice) public onlyOwner {
        AlfiePrice = _AlfiePrice;
    }

    /**
     * @notice Mint Alfies during presale
     */
    function presaleMintAlfie(uint256 numberOfTokens, bytes32[] memory proof) public payable nonReentrant {
        uint256 supply = _alfiesId.current() - 1;
        require(presaleStartTime > 0 && block.timestamp >= presaleStartTime, 'Presale must be active to mint Alfies');
        require(merkleRoot != 0, 'No existent WL at the moment');
        require(
            numberOfTokens > 0 && numberOfTokens + balanceOf(msg.sender) <= maxAlfiePurchasePresale,
            'Can only mint 5 Alfies during presale'
        );
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))), 'MerkleDistributor: Invalid proof');
        require(msg.value >= AlfiePrice * numberOfTokens, 'Ether value sent is not correct');
        require(supply + numberOfTokens <= maxAlfies, 'Purchase would exceed max supply of Alfies');
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            _alfiesId.increment();
        }
    }

    /**
     * @notice Mint Alfies during main sale
     */
    function mintAlfie(uint256 numberOfTokens) public payable nonReentrant {
        uint256 supply = _alfiesId.current() - 1;
        require(startTime > 0 && block.timestamp >= startTime, 'Sale must be active to mint Alfies');
        require(numberOfTokens > 0 && numberOfTokens <= maxAlfiePurchase, 'Can only mint 10 Alfies per transaction');
        require(supply + numberOfTokens <= maxAlfies, 'Purchase would exceed max supply of Alfies');
        require(msg.value >= AlfiePrice * numberOfTokens, 'Ether value sent is not correct');
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            _alfiesId.increment();
        }
    }

    /**
     * @notice Access the Alfies'id(s) owned by an `address`
     */
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokensId = new uint256[](ownerTokenCount);
        uint256 curTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && curTokenId < _alfiesId.current()) {
            address curTokenOwner = ownerOf(curTokenId);
            if (curTokenOwner == _owner) {
                ownedTokensId[ownedTokenIndex] = curTokenId;
                ownedTokenIndex++;
            }
            curTokenId++;
        }
        return ownedTokensId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), string('.json'))) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
}