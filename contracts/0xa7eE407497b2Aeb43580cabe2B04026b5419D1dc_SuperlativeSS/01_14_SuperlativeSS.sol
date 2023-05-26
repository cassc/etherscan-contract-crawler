// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SuperlativeSS is ERC721Pausable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_TOKENS = 11_111;
    uint256 public constant MAX_TOKENS_PER_ADDRESS = 222;
    uint256 public constant PRICE = 0.079 ether;

    uint256 private constant mintLimit = 22;

    bool public isPresaleActive = false;
    bool public isSaleActive = false;

    mapping(address => uint256) public presaleList;

    string private mContractURI;
    string private mBaseURI;
    string private mRevealedBaseURI;

    event PresaleMint(address minter, uint256 amount);
    event SaleMint(address minter, uint256 amount);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function togglePresaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function addPresaleList(
        address[] calldata _addrs,
        uint256[] calldata _limit
    ) external onlyOwner {
        require(_addrs.length == _limit.length);
        for (uint256 i = 0; i < _addrs.length; i++) {
            presaleList[_addrs[i]] = _limit[i];
        }
    }

    function presaleMint(uint256 amount) external payable {
        require(isPresaleActive, "Presale is not active");
        require(amount <= mintLimit, "Max mint 22 tokens at a time");

        uint256 senderLimit = presaleList[msg.sender];

        require(senderLimit > 0, "You have no tokens left");
        require(amount <= senderLimit, "Your max token holding exceeded");
        require(
            _tokenIdCounter.current() + amount < MAX_TOKENS,
            "Max token supply exceeded"
        );
        require(msg.value >= amount * PRICE, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            senderLimit -= 1;
        }

        presaleList[msg.sender] = senderLimit;
        emit PresaleMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(isSaleActive, "Sale is not active");
        require(amount <= mintLimit, "Max mint 22 tokens at a time");
        require(
            balanceOf(msg.sender) + amount <= MAX_TOKENS_PER_ADDRESS,
            "Your max token holding exceeded"
        );
        require(
            _tokenIdCounter.current() + amount < MAX_TOKENS,
            "Max token supply exceeded"
        );
        require(msg.value >= amount * PRICE, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        emit SaleMint(msg.sender, amount);
    }

    function gift(address to, uint256 amount) external onlyOwner {
        require(
            _tokenIdCounter.current() + amount < MAX_TOKENS,
            "Max token supply exceeded"
        );
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setContractURI(string calldata URI) external onlyOwner {
        mContractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        mBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata URI) external onlyOwner {
        mRevealedBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return mContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory revealedBaseURI = mRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : mBaseURI;
    }
}