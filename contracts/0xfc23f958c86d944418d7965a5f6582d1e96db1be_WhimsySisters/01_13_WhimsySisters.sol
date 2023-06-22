// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhimsySisters is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 7000;

    string public baseURI = "https://storage.googleapis.com/whimsysisters/meta/";

    uint public price = 0.07 ether;
    uint public reservedSupply = 70;
    uint public maxMintsPerWallet = 7;

    uint public presaleStartTimestamp = 1651780800;
    uint public publicSaleStartTimestamp = 1651953600;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public presaledNFTs;

    address public authorizedSigner = 0xf89C869460AA20b8A0982A5D90f2470E8f6EbC65;

    bool osAutoApproveEnabled = true;
    address public osProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("Whimsy Sisters", "WHIMSY", 7) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _reservedSupply,
        uint _maxMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        reservedSupply = _reservedSupply;
        maxMintsPerWallet = _maxMintsPerWallet;
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
        require(presaledNFTs[_msgSender()] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
        require(price * amount == msg.value, "Wrong ethers value");

        presaledNFTs[_msgSender()] += amount;
        mint(amount);
    }

    function publicMint(uint amount) public payable {
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(mintedNFTs[_msgSender()] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
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

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint communityShare = balance * 5 / 100;
        payable(0xbFa306b0842135D62F48e350FE6B1c0A9F30ccdA).transfer(communityShare);
        balance -= communityShare;

        payable(0x8D170a89F9c9Daf8dE5b6f39892161BDAC48508D).transfer(balance * 7 / 100);
        payable(0x0668CFb7e3E82B531Fb7FAad71C84Ae9eCbB7A6B).transfer(balance * 7 / 100);

        payable(0x16b2564d0e966877587F9B743ec862f06604E17d).transfer(balance * 13 / 100);
        payable(0x6439747005C945f7a0aCBc0baDB8F05299dE50D3).transfer(balance * 19 / 100);
        payable(0xCb78c7138E2A3FDeD98B4574a5Fd3bBdF5CC9adB).transfer(balance * 44 / 100);
        payable(0x1985BDE6F68fF743907D147ead62DA65aB651714).transfer(balance * 3 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 7 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}