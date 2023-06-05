// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MekaBae is ERC721, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 10000;
    uint constant public PRICE = 0.02 ether;

    string public baseURI;
    uint public maxFreeNFTPerWallet;
    uint public maxMintsPerWallet;

    address public authorizedSigner;
    uint public claimingStartTimestamp;
    uint public mintingStartTimestamp;

    uint public totalSupply;
    mapping(address => uint) public claimedNFTs;
    mapping(address => uint) public mintedNFTs;

    constructor() ERC721("One Day Mekabae", "ODB") {
        claimingStartTimestamp = 1635285600;
        mintingStartTimestamp = 1635292800;
        baseURI = "https://storage.googleapis.com/onedaybae/mekabae_meta/";
        maxFreeNFTPerWallet = 0;
        maxMintsPerWallet = 15;
        authorizedSigner = 0x4d7c6859B14464Af6c10E3Dff22a80B86fC26FD9;

        mintNFTs(1);
    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setMaxFreeNFTPerWallet(uint _maxFreeNFTPerWallet) external onlyOwner {
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setAuthorizedSigner(address _authorizedSigner) external onlyOwner {
        authorizedSigner = _authorizedSigner;
    }

    function setClaimingStartTimestamp(uint _claimingStartTimestamp) external onlyOwner {
        claimingStartTimestamp = _claimingStartTimestamp;
    }

    function setMintingStartTimestamp(uint _mintingStartTimestamp) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
    }

    function configure(
        uint _maxFreeNFTPerWallet,
        uint _maxMintsPerWallet,
        address _authorizedSigner,
        uint _claimingStartTimestamp,
        uint _mintingStartTimestamp
    ) external onlyOwner {
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
        maxMintsPerWallet = _maxMintsPerWallet;
        authorizedSigner = _authorizedSigner;
        claimingStartTimestamp = _claimingStartTimestamp;
        mintingStartTimestamp = _mintingStartTimestamp;
    }
    // endregion

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Mint and Claim functions
    function hashTransaction(address minter, uint claimsLimit) internal pure returns (bytes32) {
        bytes32 dataHash = keccak256(abi.encodePacked(minter, claimsLimit));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));
    }

    function recoverSignerAddress(address minter, uint claimsLimit, bytes memory signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter, claimsLimit);
        return hash.recover(signature);
    }

    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    function claim(uint amount, uint claimsLimit, bytes memory signature) internal {
        require(block.timestamp >= claimingStartTimestamp, "Claiming is not available");
        require(recoverSignerAddress(msg.sender, claimsLimit, signature) == authorizedSigner, "Bad signature");
        require(claimedNFTs[msg.sender] + amount <= claimsLimit, "Can't claim such amount of tokens");
        claimedNFTs[msg.sender] += amount;
        mintNFTs(amount);
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

    function mint(uint amount) internal {
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");
        mintedNFTs[msg.sender] += amount;
        mintNFTs(amount);
    }

    function publicMint(uint mintAmount, uint claimAmount, uint claimsLimit, bytes memory signature) external payable {
        if (mintAmount > 0) {
            mint(mintAmount);
        }
        if (claimAmount > 0) {
            claim(claimAmount, claimsLimit, signature);
        }
    }

    function mintNFTs(uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }

    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xb5bE3a702ea2b3ac1e5D14dAcD9f2b1D5b76CF97).transfer(balance * 8 / 100);
        balance -= balance * 8 / 100;
        payable(0x50131231dE9E36B3838c5F4B9D80D07e45FDD7Ae).transfer(balance / 18);
        payable(0x216F2Cf67561ED5e9A2F31482158BFc4996037AE).transfer(balance / 18);
        payable(0x82C71278733e4F8B938594C90269486b88Fb03B6).transfer(balance / 18);
        payable(0x7C94FeA51887eEFaAc4D5e708Dc1Ab98A701250A).transfer(balance / 18);
        payable(0x9Edd6b63cFCd36c2937A0955b1f9F01547707e5B).transfer(balance / 18);
        payable(0xc47c0dccfbb4D1c20d53569A288738f22e32275B).transfer(balance / 18);
        payable(0x818ea5826A063E940Cd3a8C49efa00E1ac1ed78a).transfer(balance / 18);
        payable(0x913A9F335B3C43ad91C37d1c57C0C8B0AC2Bc7aC).transfer(balance / 18);
        payable(0xFeE836516a3Fc5f053F35964a2Bed9af65Da8159).transfer(balance / 18);
        payable(0xdf674A85F3E6e2f24beeFe9EF291F2c632Ef0f0E).transfer(balance / 18);
        payable(0x17301aA866A6FFEe762c51134934924d2727b35E).transfer(balance / 18);
        payable(0x2E8D42eeC83E5e9dFC3DF007F8CE890197a1d461).transfer(balance / 18);
        payable(0xC1aC82943c37CEE8427A7878e78086F8Eac12615).transfer(balance / 18);
        payable(0x446D8feD6c6124f8Df17ED19De46977a29C30FD8).transfer(balance / 18);
        payable(0xBc2a6780951a84CD33C266a5213948606A2a67d3).transfer(balance / 18);
        payable(0x80B69a849cEE64bCEF6c6dA5A809fA521Aef6091).transfer(balance / 18);
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance / 18);
        payable(0xc153FE99e6F09fbf52f7D1D84618E06e3d9495fD).transfer(balance / 18);
    }

}