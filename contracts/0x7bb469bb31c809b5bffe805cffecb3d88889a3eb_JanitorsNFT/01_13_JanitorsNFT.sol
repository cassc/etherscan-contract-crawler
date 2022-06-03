// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JanitorsNFT is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 4444;

    string public baseURI = "https://storage.googleapis.com/janitorsnft/meta/";

    uint public price = 0.044 ether;
    uint public reservedSupply = 100;
    uint public maxPresaleMintsPerWallet = 3;
    uint public maxPublicMintsPerWallet = 10;

    uint public presaleStartTimestamp = 1654088400;
    uint public publicSaleStartTimestamp = 1654110000;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public presaledNFTs;

    address public authorizedSigner = 0x968f9ABBFf02589c9efda1DcFFE1Afb5d386E4c2;

    bool osAutoApproveEnabled = true;
    address public osProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("JanitorsNFT", "JANITORS", 10) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _reservedSupply,
        uint _maxPresaleMintsPerWallet,
        uint _maxPublicMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        reservedSupply = _reservedSupply;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        maxPublicMintsPerWallet = _maxPublicMintsPerWallet;
        presaleStartTimestamp = _presaleStartTimestamp;
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
        osAutoApproveEnabled = _osAutoApproveEnabled;
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
        require(price * amount == msg.value, "Wrong ethers value");

        presaledNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function publicMint(uint amount) public payable {
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(mintedNFTs[_msgSender()] + amount <= maxPublicMintsPerWallet, "Too much mints for this wallet!");
        require(price * amount == msg.value, "Wrong ethers value");

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

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled) {
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(osProxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {

    }

    function withdraw() external {
        uint balance = address(this).balance;
        payable(0xe6f23Cd41F3dae0a4c899b78d32e4d1E16522d43).transfer(balance / 2);
        payable(0x6319C7Bb8B6799E892292C602Feb711CB1ec4606).transfer(balance * 1267 / 10000);
        payable(0x166D28De2C43730F65908F5Bc6a6b8B226465B7C).transfer(balance * 1267 / 10000);
        payable(0x1FD4529eDac4fcF8A10081f49F8f5FB1C4807348).transfer(balance * 1267 / 10000);
        payable(0x9db13B06345c1bf5684f02aA2022103e11B3a702).transfer(balance * 599 / 10000);
        payable(0xa8CDDC2DC479b460EAeD6468c73C820A3F89F2D3).transfer(balance * 599 / 10000);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}