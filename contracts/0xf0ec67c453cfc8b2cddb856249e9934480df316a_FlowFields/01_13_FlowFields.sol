// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract FlowFields is Ownable, ERC721A, ReentrancyGuard {

    // constants
    uint256 constant MAX_FREE_ELEMENT = 250;    // 250
    uint256 constant MAX_ELEMENT_PER_USER = 5;

    uint256 constant MAX_ELEMENTS = 1250;     // 1250
    uint256 constant MAX_ELEMENTS_ONE_TIME = 10;
    uint256 constant PUBLIC_PRICE = 0.03 ether;

    // state variable
    bool public MINTING_PAUSED = true;
    string public baseTokenURI;
    string public _contractURI = "";
    mapping(address => uint256) private freeMemberList;

    constructor(uint256 maxBatchSize_) ERC721A("FlowFields", "FLOWFILDS", maxBatchSize_) {}

    function setPauseMinting(bool _pause) public onlyOwner {
        MINTING_PAUSED = _pause;
    }

    function getMintCount(address _addr) public view returns (uint256) {
        return freeMemberList[_addr];
    }

    function freeMint(uint256 numberOfTokens) external payable {
        require(!MINTING_PAUSED, "Minting is not active");
        require(totalSupply() < MAX_FREE_ELEMENT, 'All free tokens have been minted');
        require(totalSupply() + numberOfTokens <= MAX_FREE_ELEMENT, 'Total free purchase would exceed max(250) supply');
        require(freeMemberList[msg.sender] + numberOfTokens <= MAX_ELEMENT_PER_USER, 'Your free purchase would exceed max(5) supply');

        _safeMint(msg.sender, numberOfTokens);
        freeMemberList[msg.sender] += numberOfTokens;
    }

    function publicMint(uint256 numberOfTokens) external payable {
        require(!MINTING_PAUSED, "Minting is not active");
        require(totalSupply() >= MAX_FREE_ELEMENT, 'Free tokens should be minted');
        require(totalSupply() < MAX_ELEMENTS, 'All tokens have been minted');
        require(totalSupply() + numberOfTokens <= MAX_ELEMENTS, 'Purchase would exceed max supply');
        require(numberOfTokens <= MAX_ELEMENTS_ONE_TIME, "Purchase at a time excessds max allowed.");
        require(PUBLIC_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}