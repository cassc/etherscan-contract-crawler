// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JanitorsNFTV2 is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 3800;

    string public baseURI = "ipfs://QmViD5SmCXyxAK7aBtLNTV8r4BtCHE2up9LUUShN2XHKWu/";

    uint public price = 0.002 ether;
    uint public reservedSupply = 100;
    uint public maxPresaleMintsPerWallet = 5;
    uint public maxPublicMintsPerWallet = 5;

    uint public presaleStartTimestamp = 1660057200;
    uint public publicSaleStartTimestamp = 1660068000;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public presaledNFTs;

    address public authorizedSigner = 0x1439bB6aa01238b5E2797F25FEEAA06aa92E454C;

    bool osAutoApproveEnabled = true;
    address public openseaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor() ERC721A("Janitors V2", "JANITORSV2", 10) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _price,
        uint _reservedSupply,
        uint _maxPresaleMintsPerWallet,
        uint _maxPublicMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _publicSaleStartTimestamp,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
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
        if (osAutoApproveEnabled && operator == openseaConduit) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {

    }

    function withdraw() external {
        uint balance = address(this).balance;
        payable(0xe6f23Cd41F3dae0a4c899b78d32e4d1E16522d43).transfer(balance * 40 / 100);
        payable(0x6319C7Bb8B6799E892292C602Feb711CB1ec4606).transfer(balance * 12 / 100);
        payable(0x166D28De2C43730F65908F5Bc6a6b8B226465B7C).transfer(balance * 12 / 100);
        payable(0x1FD4529eDac4fcF8A10081f49F8f5FB1C4807348).transfer(balance * 12 / 100);
        payable(0x9db13B06345c1bf5684f02aA2022103e11B3a702).transfer(balance * 12 / 100);
        payable(0xa8CDDC2DC479b460EAeD6468c73C820A3F89F2D3).transfer(balance * 12 / 100);
    }

}