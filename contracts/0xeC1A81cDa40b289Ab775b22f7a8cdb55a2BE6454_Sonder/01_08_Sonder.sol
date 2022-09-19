// 𝑠𝑜𝑛𝑑𝑒𝑟:
//   𝑡ℎ𝑒 𝑝𝑟𝑜𝑓𝑜𝑢𝑛𝑑 𝑓𝑒𝑒𝑙𝑖𝑛𝑔 𝑜𝑓 𝑟𝑒𝑎𝑙𝑖𝑧𝑖𝑛𝑔 𝑡ℎ𝑎𝑡 𝑒𝑣𝑒𝑟𝑦𝑜𝑛𝑒,
//   𝑖𝑛𝑐𝑙𝑢𝑑𝑖𝑛𝑔 𝑠𝑡𝑟𝑎𝑛𝑔𝑒𝑟𝑠 𝑝𝑎𝑠𝑠𝑖𝑛𝑔 𝑖𝑛 𝑡ℎ𝑒 𝑠𝑡𝑟𝑒𝑒𝑡,
//   ℎ𝑎𝑠 𝑎 𝑙𝑖𝑓𝑒 𝑎𝑠 𝑐𝑜𝑚𝑝𝑙𝑒𝑥 𝑎𝑠 𝑜𝑛𝑒'𝑠 𝑜𝑤𝑛,
//   𝑤ℎ𝑖𝑐ℎ 𝑡ℎ𝑒𝑦 𝑎𝑟𝑒 𝑐𝑜𝑛𝑠𝑡𝑎𝑛𝑡𝑙𝑦 𝑙𝑖𝑣𝑖𝑛𝑔 𝑑𝑒𝑠𝑝𝑖𝑡𝑒 𝑜𝑛𝑒'𝑠
//   𝑝𝑒𝑟𝑠𝑜𝑛𝑎𝑙 𝑙𝑎𝑐𝑘 𝑜𝑓 𝑎𝑤𝑎𝑟𝑒𝑛𝑒𝑠𝑠 𝑜𝑓 𝑖𝑡.
//
// 𝑎 𝑔𝑒𝑛𝑒𝑟𝑎𝑡𝑖𝑣𝑒 𝑎𝑟𝑡 𝑒𝑥𝑝𝑒𝑟𝑖𝑚𝑒𝑛𝑡 𝑓𝑟𝑜𝑚 𝑏𝑢𝑧𝑧𝑦.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticketed.sol";

contract Sonder is ERC721A, Ownable, Ticketed {
    string public _baseTokenURI;
    bool public saleActive = false;
    bool public publicSaleActive = false;
    bool public goldSaleActive = false;
    uint public price = 0.01 ether;
    uint public discountedPrice = 0.005 ether;
    uint supply = 85;
    address private buzz = 0xFa24220e5Fc440DC548b1dD08d079063Adf93f28;
    mapping(address => bool) public claimed;

    constructor(string memory baseURI) ERC721A("sonder", "sndr") {
        _baseTokenURI = baseURI;
    }

    function mintAllowlist(
        bytes calldata signature,
        uint256 spotId
    ) external payable {
        require(saleActive, "Sale is not active");
        require(
            totalSupply() + 1 <= supply,
            "Mint would go past max supply"
        );
        require(!claimed[msg.sender], "Address already minted");

        uint256 p = goldSaleActive ? discountedPrice : price;
        require(msg.value == p, "Invalid price");

        _claimAllowlistSpot(signature, spotId);

        _mint(msg.sender, 1);

        claimed[msg.sender] = true;
    }

    function mintPublic() external payable {
        require(saleActive, "Sale is not active");
        require(publicSaleActive, "Public sale is not active");
        require(
            totalSupply() + 1 <= supply,
            "Mint would go past max supply"
        );
        require(!claimed[msg.sender], "Address already minted");
        require(msg.value == price, "Invalid price");

        _mint(msg.sender, 1);

        claimed[msg.sender] = true;
    }

    function airdrop(address receiver, uint256 qty) external onlyOwner {
        require(
            totalSupply() + qty <= supply,
            "Mint would go past max supply"
        );
        _mint(receiver, qty);
    }

    function setSaleState(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPublicSaleState(bool active) external onlyOwner {
        publicSaleActive = active;
    }

    function setGoldSaleState(bool active) external onlyOwner {
        goldSaleActive = active;
    }

    function setClaimGroups(uint256 num) external onlyOwner {
        _setClaimGroups(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        _setClaimSigner(_signer);
    }

    function withdraw() external onlyOwner {
        (bool s, ) = buzz.call{value: (address(this).balance)}("");
        require(s, "withdraw failed");
    }
}