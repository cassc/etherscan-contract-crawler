// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//███████╗███╗░░░███╗░█████╗░
//██╔════╝████╗░████║██╔══██╗
//█████╗░░██╔████╔██║██║░░╚═╝
//██╔══╝░░██║╚██╔╝██║██║░░██╗
//██║░░░░░██║░╚═╝░██║╚█████╔╝
//╚═╝░░░░░╚═╝░░░░░╚═╝░╚════╝░

contract FurusMintClub is ERC1155Supply, Ownable, ReentrancyGuard
{
    bool public whitelist = true;
    bool public saleIsActive = false;
    uint public activeBadgeId = 1;
    uint public maxPerTransaction = 1;
    uint public maxPerWallet = 1;
    uint public maxSupply = 2100;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    uint256 public constant PRICE = 150000000000000000; //0.15 ETH
    string public name = "Furus Mint Club";

    bytes32 root;
    mapping(address => uint) public addressMintedBalance;

    uint public reservedTokensMinted = 0;

    string public contractURIstr = "";

    constructor() ERC1155("https://ipfs.io/ipfs/QmR7yc7gmXZf1cRnwZZFyqqqZZGjAjC4teRcXWJBitZAq1/{id}.json") {}

    address payable private recipient1 = payable(0x2E69ab2e2Ab818be7D84815e5ac29B95e46F1ef2); //payout address

    function contractURI() public view returns (string memory)
    {
       return contractURIstr;
    }

    function setContractURI(string memory newuri) external onlyOwner
    {
       contractURIstr = newuri;
    }

    function setURI(string memory newuri) external onlyOwner
    {
        _setURI(newuri);
    }

    function setName(string memory _name) public onlyOwner
    {
        name = _name;
    }

    function getName() public view returns (string memory)
    {
       return name;
    }

    function mintToken(uint256 amount, bytes32[] memory proof) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(!whitelist || verify(proof), "Address not whitelisted");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= maxPerTransaction, "Max per transaction reached, sale not allowed");

        require(addressMintedBalance[msg.sender] + amount <= maxPerWallet, "Limit per wallet reached with this amount, sale not allowed");

        require(totalSupply(activeBadgeId) + amount <= maxSupply - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        addressMintedBalance[msg.sender] += amount; //tracking all ids on a single array
        _mint(msg.sender, activeBadgeId, amount, "");
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        _mint(to, activeBadgeId, amount, "");
        reservedTokensMinted = reservedTokensMinted + amount;
    }

    function withdraw() external nonReentrant
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");
        (bool success, ) = recipient1.call{value: address(this).balance / 100 * 20}("");
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistingState() external onlyOwner
    {
        whitelist = !whitelist;
    }

    function changeSaleDetails(uint _activeBadgeId, uint _maxPerTransaction, uint _maxPerWallet, uint _maxSupply) external onlyOwner
    {
        activeBadgeId = _activeBadgeId;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
        maxSupply = _maxSupply;
        saleIsActive = false;
    }
}