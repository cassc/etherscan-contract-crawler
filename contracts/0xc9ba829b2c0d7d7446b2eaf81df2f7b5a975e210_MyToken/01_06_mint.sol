// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MyToken is ERC721A, Ownable, ReentrancyGuard {

    uint8 public paused = 1;
    uint8 public devWithdrawPercent = 3;

    uint256 public mintLimit;
    string public baseURI;
    string public imageURI;

    uint256 public immutable cost;
    uint256 public immutable maxSupply;

    mapping(address => uint256[]) public mintTokenIdsMap;

    mapping(address => bool) public ogAddrMap;
    mapping(address => bool) public wlAddrMap;

    constructor(
        string memory baseURI_,
        string memory imageURI_,
        uint256 mintLimit_,
        uint256 cost_,
        uint256 maxSupply_,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        cost = cost_;
        maxSupply = maxSupply_;
        mintLimit = mintLimit_;
        baseURI = baseURI_;
        imageURI = imageURI_;
    }

    function setPaused(uint8 paused_) public onlyOwner {
        paused = paused_;
    }

    function setDevWithdrawPercent(uint8 devWithdrawPercent_) public onlyOwner {
        require(devWithdrawPercent_ > 3, 'devWithdrawPercent_ invalid');
        devWithdrawPercent = devWithdrawPercent_;
    }

    function setBaseURIAndImageURI(string memory baseURI_, string memory imageURI_) public onlyOwner {
        baseURI = baseURI_;
        imageURI = imageURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintLimit(uint256 mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateOgWlAddrMap(address[] memory ogAddrs, address[] memory wlAddrs) public onlyOwner {
        for (uint i; i < ogAddrs.length; i++) {
            ogAddrMap[ogAddrs[i]] = true;
        }

        for (uint i; i < wlAddrs.length; i++) {
            wlAddrMap[wlAddrs[i]] = true;
        }
    }

    function getCost(address msgSender) public view returns (uint256) {
        if (ogAddrMap[msgSender]) {
            return 0;
        }
        return cost;
    }

    function checkPaused(address msgSender) public view {
        if (!wlAddrMap[msgSender]) {
            require(paused != 1, 'The contract is paused!');
        }
    }

    function getTokenIds(address msgSender) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function mintEntrance() external payable {
        address msgSender = _msgSender();

        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= getCost(msgSender), 'Insufficient funds!');
        require(mintTokenIdsMap[msgSender].length < mintLimit, 'Max mints per wallet met');
        checkPaused(msgSender);

        _doMint(msgSender);
        mintTokenIdsMap[msgSender].push(totalSupply() - 1);
    }

    function _doMint(address to) private {
        require(totalSupply() < maxSupply, 'Max supply exceeded!');
        require(to != address(0), 'Cannot have a non-address as reserve.');
        _safeMint(to, 1);
    }

    function airdrop(address[] memory mintAddresses) public onlyOwner {
        for (uint i; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i]);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 toDev = balance * devWithdrawPercent / 10;
        uint256 toOwner = balance - toDev;
        address dev = 0x1eb4097DB23b6960eF7f7223207a3C87B99b9125;

        payable(dev).call{value: toDev}('');
        payable(owner()).call{value: toOwner}('');
    }
}