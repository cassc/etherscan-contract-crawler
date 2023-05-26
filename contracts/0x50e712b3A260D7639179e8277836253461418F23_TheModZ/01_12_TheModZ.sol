// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheModZ is ERC721, Ownable {

    using ECDSA for bytes32;

    // base configuration
    uint constant public MAX_SUPPLY = 5555;
    uint constant public PRICE = 0.05 ether;

    string public baseURI;
    uint public reservedSupply;
    uint public maxMintsPerTransaction;
    uint public mintingStartTimestamp;

    // presale
    uint public presaleStartTimestamp;
    uint public presalePerWalletLimit;
    address public authorizedSigner;
    mapping(address => uint) public mintedOnPresale;

    uint public totalSupply;

    constructor() ERC721("The ModZ", "MODZ") {
        presaleStartTimestamp = 1634763600;
        mintingStartTimestamp = 1635109200;
    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOwner {
        reservedSupply = _reservedSupply;
    }

    function setMaxMintsPerTransaction(uint _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }

    function setMintingStartTimestamp(uint _mintingStartTimestamp) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
    }

    function setPresaleStartTimestamp(uint _presaleStartTimestamp) external onlyOwner {
        presaleStartTimestamp = _presaleStartTimestamp;
    }

    function setPresalePerWalletLimit(uint _presalePerWalletLimit) external onlyOwner {
        presalePerWalletLimit = _presalePerWalletLimit;
    }

    function setAuthorizedSigner(address _authorizedSigner) external onlyOwner {
        authorizedSigner = _authorizedSigner;
    }


    function configure(
        uint _reservedSupply,
        uint _maxMintsPerTransaction,
        uint _mintingStartTimestamp,
        uint _presaleStartTimestamp,
        uint _presalePerWalletLimit,
        address _authorizedSigner
    ) external onlyOwner {
        reservedSupply = _reservedSupply;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        mintingStartTimestamp = _mintingStartTimestamp;
        presaleStartTimestamp = _presaleStartTimestamp;
        presalePerWalletLimit = _presalePerWalletLimit;
        authorizedSigner = _authorizedSigner;
    }

    // endregion

    // region
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    //endregion

    //
    function hashTransaction(address minter) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, bytes memory signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    // Mint and Claim functions
    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    function presale(uint amount, bytes memory signature) external payable {
        require(block.timestamp >= presaleStartTimestamp, "Presale is not available");
        require(amount * PRICE == msg.value, "Wrong ethers value");
        require(mintedOnPresale[msg.sender] + amount <= presalePerWalletLimit, "Max mints per wallet constraint violation");
        require(recoverSignerAddress(msg.sender, signature) == authorizedSigner, "You have not access to presale");

        mintedOnPresale[msg.sender] += amount;
        mintNFTs(msg.sender, amount);
    }

    function mint(uint amount) external payable {
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(amount * PRICE == msg.value, "Wrong ethers value");
        require(amount <= maxMintsPerTransaction, "Max mints per transaction constraint violation");

        mintNFTs(msg.sender, amount);
    }

    function mintNFTs(address to, uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
        }
    }
    //endregion

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = 15 * balance / 100;
        uint share2 = 5 * balance / 100;
        payable(0x897B7cf41d1D7C22bc4F44C0C61dC53F63a4149E).transfer(share1);
        payable(0xc0Ad7a7686A12a6E75e2A03F4985FaFF1A761388).transfer(share2);
        payable(0xDF747Ffb322215491cC839efC5E7fe47Bf878643).transfer(balance - share1 - share2);
    }

}