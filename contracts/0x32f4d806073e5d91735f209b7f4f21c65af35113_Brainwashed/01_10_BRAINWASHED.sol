// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Brainwashed is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public BrainTotalSupply = 6969;
    uint256 public BrainPublicSupply = 6000;
    uint256 public BrainPrice = 0.009 ether;
    uint256 public MaxBrainPerAddress = 5;

    bool public BrainMintEnabled = false;

    mapping(address => bool) public BrainClaimed;
    string public uriSuffix = ".json";
    string public baseURI = "";

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721A(_tokenName, _tokenSymbol)
    {
        _mint(msg.sender, 1);
    }


    function PublicMint(uint256 _brainAmount) public payable {
        uint256 mintedBrain = totalSupply();
        require(BrainMintEnabled, "The brainwash isn't open yet");
        require(!BrainClaimed[msg.sender], "Address already brainwashed");
        require(
            _brainAmount <= MaxBrainPerAddress,
            "Invalid brain amount"
        );
        require(
            _brainAmount + mintedBrain <= BrainPublicSupply,
            "Brain public supply exceeded"
        );
        _mint(msg.sender, _brainAmount);
        require(
            msg.value >= _brainAmount * BrainPrice, 
            "Invalid price input"
        );
        BrainClaimed[msg.sender] = true;
        delete mintedBrain;
    }

    function adminMint(uint256 _teamAmount) external onlyOwner {
        uint256 mintedBrain = totalSupply();
        require(_teamAmount + mintedBrain <= BrainTotalSupply, "Supply overload");
        _mint(msg.sender, _teamAmount);
        delete mintedBrain;
    }

    function airdrop(address[] calldata receivers) external onlyOwner{
        uint256 mintedBrain = totalSupply();
        require(receivers.length + mintedBrain <= BrainTotalSupply, "Supply overload");
        for (uint256 i; i < receivers.length; ++i) {
            _mint(receivers[i], 1);
        }
        delete mintedBrain;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function cutPublicSupply(uint256 newSupply) public onlyOwner{
        BrainPublicSupply = newSupply;
    }

    function setBrainPrice(uint256 newPrice) public onlyOwner{
        BrainPrice = newPrice;
    }

    function setPublicMintStatus(bool _state) public onlyOwner {
        BrainMintEnabled = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }
}