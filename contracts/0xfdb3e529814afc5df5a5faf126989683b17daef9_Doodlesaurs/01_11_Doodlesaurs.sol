// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Doodlesaurs is ERC721, Ownable {

    uint constant public MAX_SUPPLY = 7777;
    uint constant public PRICE = 0.02 ether;

    string public baseURI = "https://storage.googleapis.com/doodlesaurs/meta/";

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint public maxFreeNFTPerWallet = 1;
    uint public maxMintsPerWallet = 80;
    uint public mintingStartTimestamp = 1642190400;
    uint public reservedSupply = 55;

    uint public totalSupply;
    mapping(address => uint) public mintedNFTs;

    constructor() ERC721("Doodlesaurs", "DINO") {
        mintNFTs(msg.sender, 1);
    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setMaxFreeNFTPerWallet(uint _maxFreeNFTPerWallet) external onlyOwner {
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMintingStartTimestamp(uint _mintingStartTimestamp) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOwner {
        reservedSupply = _reservedSupply;
    }

    // endregion

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Mint and Claim functions
    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    function findRemainingFreeMints() public view returns (uint) {
        uint minted = mintedNFTs[msg.sender];
        return maxFreeNFTPerWallet > minted ? maxFreeNFTPerWallet - minted : 0;
    }

    function mintPrice(uint amount) public view returns (uint) {
        uint remainingFreeMints = findRemainingFreeMints();
        if (remainingFreeMints >= amount) {
            return 0;
        } else {
            return (amount - remainingFreeMints) * PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(amount > 0 && amount <= 20, "Wrong mint amount");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");

        mintedNFTs[msg.sender] += amount;
        mintNFTs(msg.sender, amount);
    }

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }

    function mintNFTs(address to, uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
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
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance * 5 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 6 / 100);
        payable(0xbe3864844Da0cdF63cB7a5297B7fb89762676264).transfer(balance * 7 / 100);
        payable(0x82C71278733e4F8B938594C90269486b88Fb03B6).transfer(balance * 7 / 100);
        payable(0x17863997b798ab9F018e8c9f14898Ed4143e9990).transfer(balance * 75 / 100);
    }

}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}