// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GangPass is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    address private whitelistSigner = 0xb1A7559274Bc1e92c355C7244255DC291AFEDB00;
    address private withdrawalAddress = 0x80c74C907071482Ec7E52d6C11185DAeAFE084Ab;
    address private proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    bool public saleIsActive;
    bool public publicSaleIsActive;

    uint[4] public maxSupplies = [0, 650, 200, 100]; //number of max supplies for each tokenId
    uint[4] public reservedTiers = [0, 30, 15, 4];   //number of reserved tiers for each tokenId. They are not included in max supplies
    uint[4] public prices = [0, 0.099 ether, 0.19 ether, 0.29 ether];

    string public name = "Gang Pass";
    string public symbol = "GANG";

    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private constant TYPEHASH = keccak256("mintToken(address to,uint tokenId)");

    mapping(address => bool) public isMinted;
    mapping(uint => uint) public mintedReservedTiers;  //number of minted reserved tiers for each tokenId

    modifier onlyAddress() {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        _;
    }

    constructor() ERC1155("https://ipfs.io/ipfs/QmYx2UKvLsMBBhknwm35Ai7jESe5Yu2v6GZua9k1bcBbaz/{id}.json") {        
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("Gang Pass")),
            keccak256(bytes("1")),
            chainId,
            address(this)
           )
        );
    }

    function mintToken(uint tokenId, bytes calldata signature) external payable onlyAddress {
        uint currentSupply = totalSupply(tokenId) - mintedReservedTiers[tokenId];   //excluding minted reserved tiers
        require(whitelistSigner != address(0), "Whitelist signer is not set yet");
        require(saleIsActive, "Sale is not active yet");
        require(!isMinted[msg.sender], "You already minted NFT");
        require(currentSupply < maxSupplies[tokenId], "Exceeds max supply for the corresponding tier");
        require(msg.value >= prices[tokenId], "Not enough ETH for transaction");

        bytes32 digest = keccak256(
            abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(TYPEHASH, msg.sender, tokenId))
            )
        );
        
        address signer = digest.recover(signature);

        require(signer == whitelistSigner, "Invalid signature");

        isMinted[msg.sender] = true;

        _mint(msg.sender, tokenId, 1, "");
    }

    function publicMint(uint tokenId) external payable onlyAddress {
        uint currentSupply = totalSupply(tokenId) - mintedReservedTiers[tokenId];  //excluding minted reserved tiers
        require(publicSaleIsActive, "Public sale is not active yet");
        require(tokenId == 1 || tokenId == 2 || tokenId == 3, "Not allowed");
        require(!isMinted[msg.sender], "You already minted NFT");
        require(currentSupply < maxSupplies[tokenId], "Exceeds max supply for the corresponding tier");
        require(msg.value >= prices[tokenId], "Not enough ETH for transaction");

        isMinted[msg.sender] = true;

        _mint(msg.sender, tokenId, 1, "");
    }

    function giveAway(address to, uint tokenId) external onlyOwner {
        require(!isMinted[to], "Receiver address already minted NFT");
        require(balanceOf(to, tokenId) == 0, "Receiver address already has corresponding tier");
        require(tokenId == 1 || tokenId == 2 || tokenId == 3, "Only Tier1, Tier2 and Tier3");
        require(mintedReservedTiers[tokenId] < reservedTiers[tokenId], "All reserved NFTs for the corresponding tier are minted");

        mintedReservedTiers[tokenId] += 1;

        _mint(to, tokenId, 1, "");
    }

    function setURI(string memory _newuri) external onlyOwner {
        _setURI(_newuri);
    }

    function setWhitelistSigner(address _newWhitelistSigner) external onlyOwner {
        whitelistSigner = _newWhitelistSigner;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPublicSaleState() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function setMaxSupplies(uint t1, uint t2, uint t3) external onlyOwner {
        maxSupplies = [0, t1, t2, t3];
    }

    function setPrices(uint256 price_t1, uint256 price_t2, uint256 price_t3) external onlyOwner {
        prices = [0, price_t1, price_t2, price_t3];
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is not sufficient");
        _withdraw(withdrawalAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    //@dev - allow gasless OpenSea listing
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if(address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}