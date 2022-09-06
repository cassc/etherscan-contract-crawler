pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";

contract This69 is ERC721A, Ownable {
    using Strings for uint256;

    uint256 private _maxPerTx = 8;
    uint256 private _maxPerWallet = 24;
    uint256 private _maxSupply = 6969;
    uint256 private _earySupply = 5000;
    bool private _revealed = false;
    bool private _isStarted = false;
    string private _unrevealURI = "ipfs://bafybeieuoygsuitcadvee5nvfz6leq7wj57qydp52f4mb3ay2so3fdzbqe/unreveal.json";
    string private _baseURL = "";
    mapping(address => uint256) private _walletMintedAmount;

    constructor() ERC721A("This69", "69") {}

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return "";
    }


    function mintedOfOwner(address owner) external view returns (uint256) {
        return _walletMintedAmount[owner];
    }


    function setRevealed(bool value) external onlyOwner  {
        _revealed = value;
    }

    
    function setUnrevealURI(string memory url) external onlyOwner  {
        _unrevealURI = url;
    }

    function setBaseUri(string memory url) external onlyOwner {
        _baseURL = url;
    }

    function setMaxPerTx(uint256 amount) external onlyOwner {
        require(amount < _maxPerTx, "value must be less");
        _maxPerTx = amount;
    }

    function maxPerTx() external view returns (uint256) {
        return _maxPerTx;
    }

    function setMaxPerWallet(uint256 amount) external onlyOwner {
        require(amount < _maxPerWallet, "value must be less");
        _maxPerWallet = amount;
    }

    function maxPerWallet() external view returns (uint256) {
        return _maxPerWallet;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }


    function earySupply() external view returns (uint256) {
        return _earySupply;
    }

    function setEarlySupply(uint256 amount) external onlyOwner {
        _earySupply = amount;
    }

    function setStart(bool started) external onlyOwner {
        require(_isStarted != started, "no change");
        _isStarted = started;
    }

    function isStarted() external view returns (bool) {
        return _isStarted;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function devMint(address to, uint256 amount) external onlyOwner {
        require(_totalMinted() + amount <= _maxSupply, "Exceeds max supply");
        _safeMint(to, amount);
    }

    function truncateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(_maxSupply > newMaxSupply, "new Supply must be less");
        _maxSupply = newMaxSupply;
    }



    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "nonexistent token"
        );
        if(!_revealed) {
            return _unrevealURI;
        }
        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                )
                : "";
    }

    function mint(uint256 signature, uint256 amount) external payable {
        require(_isStarted, "not started");
		require(amount <= _maxPerTx, "Exceeds tx limit");
        require(_totalMinted() + amount <= _maxSupply, "Exceeds max supply");
        require(
            _walletMintedAmount[msg.sender] + amount <= _maxPerWallet,
            "Exceeds max per wallet"
        );
        signature -= 77777;
        require(
            signature <= block.timestamp && signature >= block.timestamp - 400,
            "Bad Signature!"
        );
        _walletMintedAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(_isStarted, "not started");
		require(amount <= _maxPerTx, "Exceed tx limits");
        require(
            _totalMinted() + amount <= _earySupply,
            "Exceeds early supply"
        );
        require(
            _walletMintedAmount[msg.sender] + amount <= _maxPerWallet,
            "Exceeds max per wallet"
        );
        _walletMintedAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
}