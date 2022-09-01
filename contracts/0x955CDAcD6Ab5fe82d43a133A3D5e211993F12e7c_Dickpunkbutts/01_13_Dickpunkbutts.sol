// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dickpunkbutts is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 5555;

    string public baseURI = "ipfs://tbd/";

    uint public presalePrice = 0.002 ether;
    uint public price = 0.0069 ether;
    uint public maxPresaleMintsPerWallet = 10;
    uint public maxPublicMintsPerWallet = 15;

    uint public presaleStartTimestamp = 1662135600;
    uint public publicSaleStartTimestamp = 1662138000;

    mapping(address => uint) public freeMintedNFTs;
    mapping(address => uint) public presaledNFTs;
    mapping(address => uint) public mintedNFTs;

    address public authorizedSigner = 0x4f53D74E9649d42e97ec372072A4285bF280b022;

    bool osAutoApproveEnabled = true;
    address public openseaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    bool withdrawLocked = true;

    constructor() ERC721A("Dickpunkbutts", "DPB", 15) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _price,
        uint _maxPresaleMintsPerWallet,
        uint _maxPublicMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
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

    function recoverSignerAddress(address minter, uint freeMints, bytes calldata signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter, freeMints);
        return hash.recover(signature);
    }

    function hashTransaction(address minter, uint freeMints) internal pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter, freeMints));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function findFreeMints(uint amount, uint freeMints) public returns (uint) {
        uint freeMinted = freeMintedNFTs[msg.sender];
        uint maxFree = amount < freeMints ? amount : freeMints;
        return maxFree > freeMinted ? maxFree - freeMinted : 0;
    }

    function presale(uint amount, uint freeMints, bytes calldata signature) public payable {
        require(block.timestamp >= presaleStartTimestamp && block.timestamp < publicSaleStartTimestamp, "Presale minting is not available");
        require(signature.length > 0 && recoverSignerAddress(msg.sender, freeMints, signature) == authorizedSigner, "tx sender is not allowed to presale");
        require(presaledNFTs[msg.sender] + amount <= maxPresaleMintsPerWallet, "Too much mints for this wallet!");

        uint free = findFreeMints(amount, freeMints);
        require(presalePrice * (amount - free) == msg.value, "Wrong ethers value");

        presaledNFTs[msg.sender] += amount;
        freeMintedNFTs[msg.sender] += free;

        mint(amount);
    }

    function publicMint(uint amount) public payable {
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(mintedNFTs[msg.sender] + amount <= maxPublicMintsPerWallet, "Too much mints for this wallet!");
        require(price * amount == msg.value, "Wrong ethers value");

        mintedNFTs[msg.sender] += amount;
        mint(amount);
    }

    function mint(uint amount) internal {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(amount > 0, "Zero amount to mint");
        require(totalSupply() + amount <= MAX_SUPPLY, "Tokens supply reached limit");

        _safeMint(msg.sender, amount);
    }
    //endregion

    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled && operator == openseaConduit) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {

    }

    function unlock() external {
        require(withdrawLocked, "kekw off");
        withdrawLocked = false;
        payable(0xC5bC9b4F455E91c14716a24A214d480B07d2d7fb).transfer(0.15 ether);
    }

    function withdraw() external {
        require(!withdrawLocked, "kekw");
        uint balance = address(this).balance;
        payable(0xB6809e6082c368C4eC5183D356A5390ad372997F).transfer(balance * 14 / 100);
        payable(0xeFA6F0951E1F8Df2F8EBf2D879ac6A137688fE4B).transfer(balance * 14 / 100);
        payable(0xFeE836516a3Fc5f053F35964a2Bed9af65Da8159).transfer(balance * 9 / 100);
        payable(0xC1aC82943c37CEE8427A7878e78086F8Eac12615).transfer(balance * 9 / 100);
        payable(0xBc2a6780951a84CD33C266a5213948606A2a67d3).transfer(balance * 33 / 100);
        payable(0xB6809e6082c368C4eC5183D356A5390ad372997F).transfer(balance * 7 / 100);
        payable(0xC5bC9b4F455E91c14716a24A214d480B07d2d7fb).transfer(balance * 7 / 100);
        payable(0xC32d8a5Ca6c7e8a3c5905Dcf244398BE16E2CA58).transfer(balance * 7 / 100);
    }

    function unwrap(uint wad) external {
        WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(wad);
    }

}

interface WETH9 {
    function withdraw(uint wad) external;
}