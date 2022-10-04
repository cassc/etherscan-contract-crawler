// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@ Hopperz Minting Contract @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@,,@@@@@@@@@@@@@@@@@@@@@@@@@,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@%,,@@@@@@@,,,,,,,,,,,,,,@@@@@@%,,,,,,,,,,,,,,,#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@,,,@@@@@@@,,,,,,,@@,,,,,@@@@@@@,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@,,,,@@@,,,,,,,,,,,,,,,,,*@@@,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./IHopperzCarrot.sol";


contract Hopperz is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {

    string public baseURI;

    uint256 public maxSupply = 3333;
    uint256 public walletLimit = 6;

    uint256 public publicPrice = 0.0069 ether;
    uint256 public txLimit = 2;
    bool public publicSale;

    address public HopperzCarrot;

    mapping (address => bool) public HopperzWhitelistClaimed;

    constructor(
        address[] memory payees, 
        uint256[] memory shares
    ) 
    ERC721A("Hopperz", "HOPZ") 
    PaymentSplitter(payees, shares) {}

    
    modifier senderCheck() {
        require(tx.origin == msg.sender);
        _;
    }

    modifier saleActive() {
        require(isMintLive(), "Sale is not live");
        _;
    }

    function mint(uint256 amount) 
    external 
    payable
    nonReentrant
    senderCheck
    saleActive {
        uint256 qtyMinted = _numberMinted(msg.sender);

        require(qtyMinted + amount <= walletLimit, "You have already minted a max of 5 Hopperz!");
        require(totalSupply() + amount <= maxSupply, "Sorry, Sold out!");
        require(msg.value == amount * publicPrice, "Please send the correct amount of ether.");
        require(amount <= txLimit, "You can only mint 2 Hopperz per transaction!");
    
        _mint(msg.sender, amount);
    }
    
    function burnHop(uint256[] calldata tokenIds) external nonReentrant {
        for(uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function isMintLive() public view returns (bool) {
        return _totalMinted() < maxSupply && publicSale;
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        require(totalSupply() + amount <= maxSupply);

        _mint(msg.sender, amount);
    }

    function togglePublicSaleState() external onlyOwner {
        publicSale = !publicSale;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }


    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      walletLimit = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from != address(0)) {
            IHopperzCarrot(HopperzCarrot).stopDripping(from, uint128(quantity));
        }

        if (to != address(0)) {
            IHopperzCarrot(HopperzCarrot).startDripping(to, uint128(quantity));
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setHopperzTokenAddress(address _hopperzToken) external onlyOwner {
        HopperzCarrot = _hopperzToken;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}