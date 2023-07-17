// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OneDayBae is ERC721, Ownable {

    uint public constant MAX_NFT_SUPPLY = 10000;
    uint public constant NFT_PRICE = 0.01 ether;

    string private baseURI;

    bool public isSaleActive;

    uint public maxFreeNFTPerWallet;
    uint public maxNFTPerWallet;
    uint public totalSupply;

    mapping(address => uint) public mintedNFTs;

    constructor () ERC721("One Day Bae", "ODB") {
    }

    function setSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setBaseUri(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function startSale(uint _maxNFTPerWallet, uint _maxFreeNFTPerWallet) external onlyOwner {
        maxNFTPerWallet = _maxNFTPerWallet;
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
        isSaleActive = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintPrice(uint amount) public view returns (uint) {
        uint minted = mintedNFTs[msg.sender];
        uint remainingFreeMints = maxFreeNFTPerWallet > minted ? maxFreeNFTPerWallet - minted : 0;
        if (remainingFreeMints >= amount) {
            return 0;
        } else {
            return (amount - remainingFreeMints) * NFT_PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(isSaleActive, "Sale has not started.");
        require(amount > 0, "Amount of tokens must be positive");
        require(totalSupply + amount <= MAX_NFT_SUPPLY, "MAX_NFT_SUPPLY constraint violation");

        require(mintedNFTs[msg.sender] + amount <= maxNFTPerWallet, "maxNFTPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value.");

        mintedNFTs[msg.sender] += amount;

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance * 100 / 14 * 3 / 100;
        payable(0x50131231dE9E36B3838c5F4B9D80D07e45FDD7Ae).transfer(share1);
        payable(0xA07b8d8B5526337C7242F7EBCA1Bccb063cD4a20).transfer(balance - share1);
    }

}