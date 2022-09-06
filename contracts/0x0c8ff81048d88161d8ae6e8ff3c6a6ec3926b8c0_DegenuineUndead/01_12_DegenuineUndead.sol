// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegenuineUndead is ERC721A, Ownable {

    uint constant public MAX_SUPPLY = 10000;

    string public baseURI = "ipfs://__/";

    uint public price = 0.002 ether;
    uint public maxPublicMintsPerWallet = 30;

    mapping(address => uint) public mintedNFTs;

    bool osAutoApproveEnabled = false;
    address public openseaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor() ERC721A("Degenuine Undead", "DEGUN", 10) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _price,
        uint _maxPublicMintsPerWallet,
        bool _osAutoApproveEnabled
    ) external onlyOwner {
        price = _price;
        maxPublicMintsPerWallet = _maxPublicMintsPerWallet;
        osAutoApproveEnabled = _osAutoApproveEnabled;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint amount) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(amount > 0, "Zero amount to mint");
        require(totalSupply() + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        require(mintedNFTs[msg.sender] + amount <= maxPublicMintsPerWallet, "Too much mints for this wallet!");
        require(price * amount == msg.value, "Wrong ethers value");

        mintedNFTs[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function devAirdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled && operator == openseaConduit) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0x6086174cc0805a3135d21400147Cb1dB4389FF6C).transfer(balance * 5 / 100);
        payable(0x9Eb19056ADdacfB9eA25C156379382c79aaB7886).transfer(balance * 10 / 100);
        payable(0xd27b09df7eFf79c0ffC0Dda228235cB3a3C4C577).transfer(balance * 10 / 100);
        payable(0xB6809e6082c368C4eC5183D356A5390ad372997F).transfer(balance * 75 / 100);
    }

}