//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//       ___          ___          ___                     ___          ___                   ___          ___       ___
//      /\  \        /\__\        /\  \         ___       /\__\        /\  \                 /\__\        /\  \     /\  \
//     /::\  \      /:/  /       /::\  \       /\  \     /::|  |      /::\  \               /::|  |      /::\  \    \:\  \
//    /:/\:\  \    /:/__/       /:/\:\  \      \:\  \   /:|:|  |     /:/\ \  \             /:|:|  |     /:/\:\  \    \:\  \
//   /:/  \:\  \  /::\  \ ___  /::\~\:\  \     /::\__\ /:/|:|  |__  _\:\~\ \  \           /:/|:|  |__  /::\~\:\  \   /::\  \
//  /:/__/ \:\__\/:/\:\  /\__\/:/\:\ \:\__\ __/:/\/__//:/ |:| /\__\/\ \:\ \ \__\         /:/ |:| /\__\/:/\:\ \:\__\ /:/\:\__\
//  \:\  \  \/__/\/__\:\/:/  /\/__\:\/:/  //\/:/  /   \/__|:|/:/  /\:\ \:\ \/__/         \/__|:|/:/  /\/__\:\ \/__//:/  \/__/
//   \:\  \           \::/  /      \::/  / \::/__/        |:/:/  /  \:\ \:\__\               |:/:/  /      \:\__\ /:/  /
//    \:\  \          /:/  /       /:/  /   \:\__\        |::/  /    \:\/:/  /               |::/  /        \/__/ \/__/
//     \:\__\        /:/  /       /:/  /     \/__/        /:/  /      \::/  /                /:/  /
//      \/__/        \/__/        \/__/                   \/__/        \/__/                 \/__/

// Smart Contract By: @backseats_eth

contract ChainsNFT is ERC721, PaymentSplitter, Ownable {

    // Setup

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Public Properties

    bool public mintEnabled;
    bool public allowListMintEnabled;

    mapping(address => uint) public allowListMintCount;

    bytes32 public merkleRoot;

    // Private Properties

    string private _baseTokenURI;

    uint private price = 0.1 ether;

    address private teamWallet = 0x35c4599b34AC1Aa0b8436A4019E3b0B7E0546D52;

    // Modifiers

    modifier isNotPaused(bool _enabled) {
        require(_enabled, "Mint paused");
        _;
    }

    // Constructor

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721("Chains NFT", "CHAINS") PaymentSplitter(_payees, _shares) {
        _mintChains(teamWallet, 50);
    }

    // Mint Functions

    // Function requires a Merkle proof and will only work if called from the minting site.
    // Allows the allowList minter to come back and mint again if they mint under 3 max mints in the first transaction(s).
    function allowListMint(bytes32[] calldata _merkleProof, uint _amount) external payable isNotPaused(allowListMintEnabled) {
        require((_amount > 0 && _amount < 4), "Wrong amount");
        require(totalSupply() + _amount < 10_001, 'Exceeds max supply');
        require(allowListMintCount[msg.sender] + _amount < 4, "Can only mint 3");
        require(price * _amount == msg.value, "Wrong ETH amount");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not on the list');

        allowListMintCount[msg.sender] = allowListMintCount[msg.sender] + _amount;

        _mintChains(msg.sender, _amount);
    }

    function mint(uint _amount) external payable isNotPaused(mintEnabled) {
        require((_amount > 0 && _amount < 21), "Wrong amount");
        require(totalSupply() + _amount < 10_001, 'Exceeds max supply');
        require(price * _amount == msg.value, "Wrong ETH amount");

        _mintChains(msg.sender, _amount);
    }

    // Allows the team to mint Chains to a destination address
    function promoMint(address _to, uint _amount) external onlyOwner {
        require(_amount > 0, "Mint 1");
        require(totalSupply() + _amount < 10_001, 'Exceeds max supply');
        _mintChains(_to, _amount);
    }

    function _mintChains(address _to, uint _amount) internal {
        for(uint i = 0; i < _amount; i++) {
            _tokenSupply.increment();
            _safeMint(_to, totalSupply());
        }
    }

    function totalSupply() public view returns (uint) {
        return _tokenSupply.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Ownable Functions

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setAllowListMintEnabled(bool _val) external onlyOwner {
        allowListMintEnabled = _val;
    }

    function setMintEnabled(bool _val) external onlyOwner {
        mintEnabled = _val;
    }

    // Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

}