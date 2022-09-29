// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FFU is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 5555;

    string public baseURI = "ipfs://__/";

    uint public presalePrice = 0.005 ether;
    uint public publicPrice = 0.0065 ether;

    uint public reservedSupply = 70;
    uint public maxPresaleMintsPerWallet = 5;
    uint public maxPublicMintsPerWallet = 5;

    uint public presaleStartTimestamp = 1664398800;
    uint public publicSaleStartTimestamp = 1664401200;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public presaledNFTs;

    address public authorizedSigner = 0x722FB9A301c89C84e4d7Fa70D5B1825e6225eDc6;

    constructor() ERC721A("Face Fatigue Union", "FFU", 10) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _presalePrice,
        uint _publicPrice,
        uint _reservedSupply,
        uint _maxPresaleMintsPerWallet,
        uint _maxPublicMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        presalePrice = _presalePrice;
        publicPrice = _publicPrice;
        reservedSupply = _reservedSupply;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        maxPublicMintsPerWallet = _maxPublicMintsPerWallet;
        presaleStartTimestamp = _presaleStartTimestamp;
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function recoverSignerAddress(address minter, bytes calldata signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    function hashTransaction(address minter) internal pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function presale(uint amount, bytes calldata signature) public payable {
        require(block.timestamp >= presaleStartTimestamp && block.timestamp < publicSaleStartTimestamp, "Presale minting is not available");
        require(signature.length > 0 && recoverSignerAddress(_msgSender(), signature) == authorizedSigner, "tx sender is not allowed to presale");
        require(presaledNFTs[_msgSender()] + amount <= maxPresaleMintsPerWallet, "Too much mints for this wallet!");
        require(amount * presalePrice == msg.value, "Wrong ethers value");

        presaledNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function publicMint(uint amount) public payable {
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(mintedNFTs[_msgSender()] + amount <= maxPublicMintsPerWallet, "Too much mints for this wallet!");
        require(amount * publicPrice == msg.value, "Wrong ethers value");

        mintedNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function mint(uint amount) internal {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(amount > 0, "Zero amount to mint");
        require(totalSupply() + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");

        _safeMint(_msgSender(), amount);
    }
    //endregion

    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function withdraw() external {
        uint balance = address(this).balance;
        payable(0x72a5Ef2Ba5312EB31fA1D951B136eb049Fbd10D4).transfer(balance * 5 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 6 / 100);
        payable(0x6086174cc0805a3135d21400147Cb1dB4389FF6C).transfer(balance * 6 / 100);
        payable(0xB2718490E8b4bB66fC9c87cE6785423aa5E8FBcC).transfer(balance * 6 / 100);
        payable(0x78DF662313b1452533518fd33FA2b4DD6cf724d9).transfer(balance * 77 / 100);
    }

}