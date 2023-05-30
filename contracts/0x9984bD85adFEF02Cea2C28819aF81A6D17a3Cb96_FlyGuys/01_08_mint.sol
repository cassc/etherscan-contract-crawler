// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract FlyGuys is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint256 public immutable maxSupply = 8888;

    uint8 public paused = 1;

    string public baseURI = 'https://static-resource.dirtyflies.xyz/metadata/';
    uint256 public freeMintQuantity = 1;
    uint256 public maxFreeMintQuantity = 2000;
    uint256 public mintLimit = 5;
    uint256 public cost = 3300000000000000; // 0.0033
    mapping(address => bool) public whitelistMap;

    mapping(address => uint256[]) public mintTokenIdsMap;
    uint256 public freeMintQuantityCounter = 0;

    constructor(uint8 paused_) ERC721A('Fly Guys', 'FG') {
        paused = paused_;
    }

    function updatePaused(uint8 paused_) public onlyOwner {
        paused = paused_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateFreeMintQuantity(uint256 freeMintQuantity_) public onlyOwner {
        freeMintQuantity = freeMintQuantity_;
    }

    function updateMaxFreeMintQuantity(uint256 maxFreeMintQuantity_) public onlyOwner {
        maxFreeMintQuantity = maxFreeMintQuantity_;
    }

    function updateMintLimit(uint256 mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint256 cost_) public onlyOwner {
        cost = cost_;
    }

    function updateWhitelistMap(address[] memory addAddrs, address[] memory delAddrs) public onlyOwner {
        for (uint i; i < addAddrs.length; i++) {
            whitelistMap[addAddrs[i]] = true;
        }

        for (uint i; i < delAddrs.length; i++) {
            whitelistMap[delAddrs[i]] = false;
        }
    }

    function getCost(address msgSender) public view returns (uint256) {
        if (whitelistMap[msgSender]) {
            return 0;
        }
        return cost;
    }

    function calculateCost(address msgSender, uint256 quantity) public view returns (uint256) {
        if (freeMintQuantity > mintTokenIdsMap[msgSender].length && freeMintQuantityCounter < maxFreeMintQuantity) {
            uint256 remainFreeMintQuantity = freeMintQuantity - mintTokenIdsMap[msgSender].length;
            if (remainFreeMintQuantity >= quantity) {
                return 0;
            } else {
                return (quantity - remainFreeMintQuantity) * getCost(msgSender);
            }
        } else {
            return quantity * getCost(msgSender);
        }
    }

    function checkPaused() public view {
        require(paused != 1, 'The contract is paused!');
    }

    function getTokenIds(address msgSender) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function mint(uint256 quantity) external payable {
        address msgSender = _msgSender();
        uint256 expectedCost = calculateCost(msgSender, quantity);
        uint256 freeMintQuantityCounterIncr = ((quantity * getCost(msgSender)) - expectedCost) / cost;

        checkPaused();
        require(quantity > 0, 'Invalid quantity!');
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= expectedCost, 'Insufficient funds!');
        require(mintTokenIdsMap[msgSender].length + quantity <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, quantity);
        for (uint i; i < quantity; i++) {
            mintTokenIdsMap[msgSender].push(totalSupply() - quantity + i);
        }
        freeMintQuantityCounter = freeMintQuantityCounter + freeMintQuantityCounterIncr;
    }

    function airdrop(address[] memory mintAddresses, uint256[] memory mintCounts) public onlyOwner {
        for (uint i; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint256 quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded!');
        require(to != address(0), 'Cannot have a non-address as reserve.');
        _safeMint(to, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}