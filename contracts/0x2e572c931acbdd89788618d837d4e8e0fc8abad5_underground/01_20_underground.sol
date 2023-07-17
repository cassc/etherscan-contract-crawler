// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./AccessUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract underground is AccessUpgradeable, ERC721EnumerableUpgradeable, DefaultOperatorFiltererUpgradeable {

    string private _baseTokenURI;
    bytes32 private merkleRoot;
    uint256 private initialCredit;

    bool public isTransferRestricted;
    mapping (address id => bool) public minted;

    enum Months {
        Three,
        Six,
        Twelve
    }

    struct Subscription {
        bool minted;
        uint256 expiration;
        uint256 lock;
    }

    mapping (uint256 id => Subscription) public subscription;

    mapping (Months => uint256 cost) public mintTable;
    mapping (Months => uint256 cost) public mintTableDiscount;

    mapping (Months value => uint256 cost) public renewTable;
    mapping (Months value => uint256 cost) public renewTableDiscount;
    
    mapping (address => uint256) public credit;

    event Mint(address indexed sender, uint256 id, uint256 expiration, Months addedLock);
    event Renew(address indexed sender, uint256 id, uint256 expiration, Months addedMonths);

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __ERC721_init("underground", "ug");
        __ERC721Enumerable_init();
        __Context_init();
        __ERC165_init();
        __DefaultOperatorFilterer_init();

        _transferOwnership(owner);

        isTransferRestricted = true;

        mintTable[Months.Three] = 1 ether;
        mintTable[Months.Six] = 1.75 ether;
        mintTable[Months.Twelve] = 3 ether;

        mintTableDiscount[Months.Three] = 0.9 ether;
        mintTableDiscount[Months.Six] = 1.5 ether;
        mintTableDiscount[Months.Twelve] = 2.5 ether;

        renewTable[Months.Three] = 1 ether;
        renewTable[Months.Six] = 1.75 ether;
        renewTable[Months.Twelve] = 3 ether;

        renewTableDiscount[Months.Three] = 0.9 ether;
        renewTableDiscount[Months.Six] = 1.5 ether;
        renewTableDiscount[Months.Twelve] = 2.5 ether;

        initialCredit = 0.5 ether;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setIsTransferRestricted(bool restricted) external onlyOwner {
        isTransferRestricted = restricted;
    }

    function editMintTable(Months months, uint256 cost) external onlyOwner {
        mintTable[months] = cost;
    }

    function editMintTableDiscount(Months months, uint256 cost) external onlyOwner {
        mintTableDiscount[months] = cost;
    }

    function editRenewTable(Months months, uint256 cost) external onlyOwner {
        renewTable[months] = cost;
    }

    function editRenewTableDiscount(Months months, uint256 cost) external onlyOwner {
        renewTableDiscount[months] = cost;
    }

    function editCredit(address user, uint256 amount) external onlyOwner {
        credit[user] = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, bytes memory res) = owner().call{value: address(this).balance}("");
        require(success, string(res));
    }

    function setMerkleRoot(bytes32 root) external onlyAdmin {
        merkleRoot = root;
    }

    // in case of member ban
    function grab(address from, address to, uint256 id) external onlyAdmin {
        _safeTransfer(from, to, id, "");
    }

    function setExpiration(uint256 id, uint256 expiration) external onlyAdmin {
        subscription[id].expiration = expiration;
    }

    function setLock(uint256 id, uint256 lock) external onlyAdmin {
        subscription[id].lock = lock;
    }

    function subTransferFrom(address from, address to, uint256 id, bool transferCredit) external onlyAdmin {
        uint256 expiration = subscription[id].expiration;

        if (transferCredit) {
            credit[to] = credit[from];
            credit[from] = 0;
        }

        _safeTransfer(from, to, id, "");

        subscription[id].expiration = expiration;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (msg.sender != owner() && from != address(0)) {
            require(!isTransferRestricted, "Transfer is globally restricted");
            require(block.timestamp >= subscription[firstTokenId].lock, "Transfer is restricted due to mint time constraint");
        }

        subscription[firstTokenId].expiration = 0;
        credit[from] = 0;

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function monthsToSeconds(Months months) internal pure returns(uint256) {
        if (months == Months.Three) {
            return 90 days;
        } else if (months == Months.Six) {
            return 180 days;
        } else if (months == Months.Twelve) {
            return 365 days;
        }

        revert("Invalid months");
    }

    function internalMint(address to) internal returns(uint256) {
        require(!minted[to], "You have already minted a token");
        
        minted[to] = true;

        uint256 id = totalSupply() + 1;
        _mint(to, id);

        return id;
    }

    function devMint(address to, Months lock, Months sub) external onlyOwner {
        require(!minted[to], "You have already minted a token");

        uint256 id = internalMint(to);
        
        subscription[id].minted = true;
        subscription[id].expiration = block.timestamp + monthsToSeconds(lock);
        subscription[id].lock = block.timestamp + monthsToSeconds(sub);

        emit Mint(to, id, subscription[id].expiration, lock);
        emit Renew(to, id, subscription[id].expiration, sub);
    }

    function mint(Months lock, bool discount, bytes32[] calldata merkleProof) external payable {
        require(!minted[msg.sender], "You have already minted a token");

        bytes32 node = keccak256(abi.encode(msg.sender, discount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid merkle proof");

        uint256 cost = discount ? mintTableDiscount[lock] : mintTable[lock];
        require(cost > 0 && msg.value == cost, "Invalid value");

        uint256 id = internalMint(msg.sender);

        credit[msg.sender] = discount ? initialCredit - (mintTable[lock] - mintTableDiscount[lock]) : 0;

        subscription[id].minted = true;
        subscription[id].expiration = block.timestamp + monthsToSeconds(lock);
        subscription[id].lock = block.timestamp + monthsToSeconds(lock);

        emit Mint(msg.sender, id, subscription[id].expiration, lock);
        emit Renew(msg.sender, id, subscription[id].expiration, lock);
    }

   function renew(uint256 id, Months sub) external payable {
        require(msg.sender == ownerOf(id), "You are not the owner of this token");

        uint256 cost = renewTable[sub];
        uint256 creditRemaining = credit[msg.sender];

        if (creditRemaining > 0) {
            uint256 difference = renewTable[sub] - renewTableDiscount[sub];
            if (creditRemaining > difference) {
                cost = renewTableDiscount[sub];
                credit[msg.sender] = creditRemaining - difference;
            } else {
                cost = renewTable[sub] - creditRemaining;
                credit[msg.sender] = 0;
            }
        }

        require(cost > 0 && msg.value == cost, "Invalid value");

        if (subscription[id].expiration < block.timestamp) {
            subscription[id].expiration = block.timestamp + monthsToSeconds(sub);
        } else {
            subscription[id].expiration += monthsToSeconds(sub);
        }

        emit Renew(msg.sender, id, subscription[id].expiration, sub);
    }
}