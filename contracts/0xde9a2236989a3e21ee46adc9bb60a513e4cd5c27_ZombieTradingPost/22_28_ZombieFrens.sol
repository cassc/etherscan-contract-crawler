// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {TeiredWhitelist} from "./TeiredWhitelist.sol";
import {IYieldVestment} from "./IYieldVestment.sol";

/// @author tempest-sol
contract ZombieFrens is Ownable, ERC721Enumerable, TeiredWhitelist {

    IYieldVestment public vestmentPool;

    uint256 constant public MAX_ZOMBIES = 9999;

    uint8 constant public PER_WALLET_MINT = 10;
    uint8 constant public MAX_PER_TX = 2;
    uint8 constant public MAXIMUM_RESERVE = 100;
    uint8 public reserveCount;

    bool public publicSaleActive;

    string private baseURI;
    
    mapping(address => uint8) public reserveList;

    event ZombieMinted(address minter, uint8 amount);

    event PublicSaleStatusChanged(bool oldStatus, bool newStatus);

    event ZombieReservedFor(address receiver, uint8 amount);

    constructor() ERC721("ZombieFrens", "ZFREN") { }

    function setVestmentPool(address _vestmentPool) external onlyOwner {
        vestmentPool = IYieldVestment(_vestmentPool);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reserveFor(address to, uint8 amount) external onlyOwner {
        require(to != address(0x0), "zero_address");
        require(amount > 0, "amount_zero");
        require(reserveCount < MAXIMUM_RESERVE && reserveCount + amount <= MAXIMUM_RESERVE, "not_enough_reserve");

        reserveList[to] += amount;
    }

    function setWhitelistSale(WhitelistTeir teir) external onlyOwner {
        require(currentWhitelistSale != teir, "sale_already_active");
        require(!publicSaleActive, "public_sale_active");
        WhitelistTeir oldTeir = currentWhitelistSale;
        currentWhitelistSale = teir;

        emit WhitelistSaleChanged(oldTeir, currentWhitelistSale);
    }

    function claimWhitelist(bytes32[] calldata merkleProof, uint8 amount) external {
        super._claimWhitelist(merkleProof, amount);
        _mintZombie(msg.sender, amount);
        emit WhitelistClaimed(msg.sender, amount);
    }

    function claimReserved() external _hasReserves {
        uint8 reserves = getReserveCount();
        reserveList[msg.sender] -= reserves;
        _mintZombie(msg.sender, reserves);
    }

    function mint(uint8 amount) external _canMint(amount) _publicSale {
        _mintZombie(msg.sender, amount);
    }

    function _mintZombie(address to, uint8 amount) internal {
        uint256 tokenId = totalSupply();
        for(uint8 i = 0; i<amount; i++) {
            _safeMint(to, tokenId + i);
        }
        emit ZombieMinted(msg.sender, amount);
    }

    function flipPublicSale() external onlyOwner {
        currentWhitelistSale = WhitelistTeir.CONCLUDED;
        publicSaleActive = !publicSaleActive;
        emit PublicSaleStatusChanged(!publicSaleActive, publicSaleActive);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override _notVested(tokenId) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getReserveCount() public view returns (uint8 _reserveCount) {
        _reserveCount = reserveList[msg.sender];
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier _canMint(uint8 amount) {
        require(amount <= MAX_PER_TX, "exceeds_tx_limit");
        require(balanceOf(msg.sender) + amount <= PER_WALLET_MINT, "exceeds_wallet_limit");
        _;
    }

    modifier _hasReserves() {
        require(reserveList[msg.sender] > 0, "no_reserves");
        _;
    }

    modifier _notVested(uint256 tokenId) {
        if(address(vestmentPool) != address(0x0)) {
            bool isVested = vestmentPool.isVested(tokenId);
            require(!isVested, "cannot_transfer_vested_token");
        }
        _;
    }

    modifier _publicSale() {
        if(currentWhitelistSale == WhitelistTeir.INACTIVE && !publicSaleActive) revert("no_active_sale");
        require(currentWhitelistSale == WhitelistTeir.CONCLUDED, "whitelist_sale_active");
        require(publicSaleActive, "public_sale_inactive");
        _;
    }
}