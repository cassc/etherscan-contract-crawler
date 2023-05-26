// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KOKODI is ERC721A, ReentrancyGuard, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 5555;

    string public baseURI = "https://storage.googleapis.com/kokodinft/meta/";

    uint public price = 0.05 ether;
    uint public wlPrice = 0.03 ether;

    uint public reservedSupply = 55;

    uint public maxPresaleMintsPerWallet = 3;
    uint public maxMintsPerWallet = 10;

    uint public presaleStartTimestamp = 1643655600;
    uint public publicSaleStartTimestamp = 1643670000;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public presaledNFTs;

    address public authorizedSigner = 0xb5c64B6BdA4d6f71BC5D167f1356e4e50ef9c21C;

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("KOKODI", "KKD", 10) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function configure(
        uint _price,
        uint _wlPrice,
        uint _reservedSupply,
        uint _maxPresaleMintsPerWallet,
        uint _maxMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
        wlPrice = _wlPrice;
        reservedSupply = _reservedSupply;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        maxMintsPerWallet = _maxMintsPerWallet;
        presaleStartTimestamp = _presaleStartTimestamp;
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function recoverSignerAddress(address minter, bytes calldata signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    function hashTransaction(address minter) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function presale(uint amount, bytes calldata signature) public payable nonReentrant {
        require(block.timestamp >= presaleStartTimestamp && block.timestamp < publicSaleStartTimestamp, "Presale minting is not available");
        require(recoverSignerAddress(_msgSender(), signature) == authorizedSigner, "Not allowed for presale");
        require(presaledNFTs[_msgSender()] + amount <= maxPresaleMintsPerWallet, "Too much mints for this wallet!");
        require(wlPrice * amount == msg.value, "Wrong ethers value");

        presaledNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function publicMint(uint amount) public payable nonReentrant {
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(mintedNFTs[_msgSender()] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
        require(price * amount == msg.value, "Wrong ethers value");

        mintedNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function mint(uint amount) internal {
        require(tx.origin == _msgSender(), "The caller is another contract");
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

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }


    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0x587f26296F074375Bd9e76895Bb2550124B9F8b7).transfer(balance * 75 / 1000);
        payable(0x39f527e945ac1c2f74dC5d049e1f67848652e7e7).transfer(balance * 75 / 1000);
        // alpha mint
        payable(0x105b178bCa7bf97a6f4E5f9f21A57F258D46526c).transfer(balance * 7 / 100);
        payable(0xc2E62Da2c7F8301Bcf865C0fCE0F240891586E77).transfer(balance * 3 / 100);
        payable(0xe82052c32406811C1E86f0Ba9BEb93292FD51fc5).transfer(balance * 10 / 100);
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance * 1 / 100);
        payable(0xD31aE467026815b0b8f520E764215c64c3FD0A41).transfer(balance * 64 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}