// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

interface APE_TOKEN {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
}

contract KodaCapital is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer{
    using Strings for uint256;

    APE_TOKEN public ape;

    uint256 public MAX_SUPPLY = 2000;
    uint256 public ETH_COST = .2 ether;
    uint256 public APE_COST = 55 ether;

    bool public ETH_ACTIVE = false;
    bool public APE_ACTIVE = false;

    string public baseURI;
    string public baseExtension = ".json";
    address public payoutWallet;

    struct Stake {
        address owner;
        uint256 timestamp;
    }

    mapping(uint256 => Stake) public staked;

    constructor(address _ape) ERC721A("Koda Capital", "KC"){
        ape = APE_TOKEN(_ape);
        payoutWallet = msg.sender;
    }

    function eth_mint(uint256 _amount) external payable nonReentrant{
        require(ETH_ACTIVE == true, "ETH mint is not active");
        require(_amount > 0, "Invalid amount");
        require(_amount + this.totalSupply() <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == _amount * ETH_COST, "Not enough eth");
        _safeMint(msg.sender, _amount);
    }

    function ape_mint(uint256 _amount) external nonReentrant{
        require(APE_ACTIVE == true, "Ape mint is not active");
        require(_amount > 0 , "Invalid amount");
        uint256 cost = APE_COST * _amount;
        require (ape.allowance(msg.sender, address(this)) >= cost, "Not enough allowance");
        require (ape.balanceOf(msg.sender) >= cost, "Not enough ape");
        require(_amount + this.totalSupply() <= MAX_SUPPLY, "Max Supply reached");
        ape.transferFrom(msg.sender, address(this), cost);
        _safeMint(msg.sender, _amount);
    }

    function stake(uint256 _token_id) external{
        require (this.ownerOf(_token_id) == msg.sender, "Not owner");
        staked[_token_id] = Stake(msg.sender, block.timestamp);
    }

    function unstake(uint256 _token_id) external{
        require(staked[_token_id].owner == msg.sender, "Not owner");
        staked[_token_id] = Stake(address(0x0), 0);
    }

    function setETHActive(bool _state) external onlyOwner{
        ETH_ACTIVE = _state;
    }

    function setApeActive(bool _state) external onlyOwner{
        APE_ACTIVE = _state;
    }

    function setETHCost(uint256 _cost) external onlyOwner{
        ETH_COST = _cost;
    }

    function setApeCost(uint256 _cost) external onlyOwner{
        APE_COST = _cost;
    }

    function setPayoutWallet(address _wallet) external onlyOwner{
        payoutWallet = _wallet;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _extension) public onlyOwner{
        baseExtension = _extension;
    }

    function tokenURI(uint _token_id) public view override returns(string memory){
        return string(abi.encodePacked(baseURI, _token_id.toString(), baseExtension));
    }

    function withdraw() external payable onlyOwner{
        uint256 balance = ape.balanceOf(address(this));
        ape.approve(address(this), balance);
        ape.transferFrom(address(this), payoutWallet, balance);
        payable(payoutWallet).transfer(address(this).balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        require(staked[startTokenId].timestamp == 0, "Cannot transfer - currently staked");
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}