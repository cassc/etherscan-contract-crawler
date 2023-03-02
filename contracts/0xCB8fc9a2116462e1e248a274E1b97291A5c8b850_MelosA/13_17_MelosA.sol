//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MelosA is ERC721A, ERC721AQueryable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Drop {
        address to;
        uint256 amount;
        uint256 itemType;
    }

    address public constant DEV_ADDRESS = 0xea7Ce518713bc6Aec484C2Dc22b359621ed560F5;

    uint256 public maxTokenSupply;
    string public baseTokenURI;
    bytes32 public merkleRoot;
    bool public saleEnabled;
    bool public whitelistEnabled;
    uint256 public currentPrice;
    uint256 public currentMaxSale;
    uint256 public maxMintPerTx;
    uint256 public maxMintPerWallet;
    mapping(address => uint256) public mintCount;
    mapping(address => bool) private presaleListClaimed;
    uint256[] public items;

    constructor(string memory baseURI) ERC721A("Melos A", "MELOSA") {
        setBaseURI(baseURI);
        saleEnabled = true;
        whitelistEnabled = false;
        currentPrice = 0.03 ether;
        currentMaxSale = 6000;
        maxTokenSupply = 6000;
        maxMintPerTx = 20;
        maxMintPerWallet = 6000;
        items.push(0);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(
        uint256 _count,
        uint256 _presaleMaxAmount,
        address _to,
        uint256 _type,
        bytes32[] calldata _merkleProof
    ) public payable {
        uint256 total = totalSupply();
        require(total + _count <= currentMaxSale, "MelosA: Max sale limit");
        require(mintCount[_to] + _count <= maxMintPerWallet, "MelosA: Max wallet limit");
        require(_count <= maxMintPerTx, "MelosA: Max mint for tx limit");
        require(saleEnabled, "MelosA: Sale is not active");
        require(msg.value >= getPrice(_count), "MelosA: Value below price");

        if (whitelistEnabled == true) {
            require(merkleRoot != 0x0, "MelosA: merkle root not set");

            // Verify if the account has already claimed
            require(
                !isPresaleListClaimed(msg.sender),
                "MelosA: account already claimed"
            );

            // Verify we cannot claim more than the max amount
            require(
                _count <= _presaleMaxAmount,
                "MelosA: can only claim less than or equal to the max amount"
            );

            // Verify the merkle proof.
            require(
                validClaim(msg.sender, _presaleMaxAmount, _merkleProof),
                "MelosA: invalid proof"
            );

            presaleListClaimed[msg.sender] = true;
        }

        for (uint i = 0; i < _count; i++) {
            items.push(_type);
        }

        _mintElements(_to, _count, true);
    }

    // @dev start of public/external views
    function isPresaleListClaimed(address account) public view returns (bool) {
        return presaleListClaimed[account];
    }

    function validClaim(
        address claimer,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(claimer, maxAmount.toString()));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        return currentPrice.mul(_count);
    }
    // @dev end of public/external views

    // @dev start of internal/private functions
    function _mintElements(address _to, uint256 _amount, bool increaseCount) private {
        if(increaseCount) {
            mintCount[_to] = mintCount[_to] + _amount;
        }
        _safeMint(_to, _amount);
        require(totalSupply() <= maxTokenSupply, "MelosA: Limit reached");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _payout(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "MelosA: Transfer failed");
    }
    // @dev end of internal/private functions

    // @dev start of airdrop functions
    function airdrop(Drop[] calldata drops) external onlyOwner {
        for (uint i = 0; i < drops.length; i++) {
            Drop calldata drop = drops[i];

            for (uint i = 0; i < drop.amount; i++) {
                items.push(drop.itemType);
            }
            _mintElements(drop.to, drop.amount, false);
        }
    }
    // @dev end of airdrop functions

    // @dev start of only owner functions
    function setMaxSale(uint256 currentMaxSale_) external onlyOwner {
        require(currentMaxSale_ <= maxTokenSupply, "MelosA: currentMaxSale cannot be higher than maxTokenSupply");
        currentMaxSale = currentMaxSale_;
    }

    function setMaxTokenSupply(uint256 maxTokenSupply_) external onlyOwner {
        require(currentMaxSale <= maxTokenSupply_, "MelosA: maxTokenSupply cannot be lower than currentMaxSale");
        maxTokenSupply = maxTokenSupply_;
    }

    function setPrice(uint256 priceInWei) external onlyOwner {
        currentPrice = priceInWei;
    }

    function setMaxMintPerWallet(uint256 maxMintPerWallet_) external onlyOwner {
        require(maxMintPerTx <= maxMintPerWallet_, "MelosA: MaxMintPerWallet cannot be lower than maxMintPerTx");
        maxMintPerWallet = maxMintPerWallet_;
    }

    function setMaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        require(maxMintPerTx_ <= maxMintPerWallet, "MelosA: MaxMintPerTx cannot be higher than maxMintPerWallet");
        maxMintPerTx = maxMintPerTx_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleSale() public onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function toggleWhitelist() public onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ?
            string(abi.encodePacked(currentBaseURI, items[tokenId].toString())) : "";
    }

    function withdrawAll() public {
        require(msg.sender == owner() || msg.sender == DEV_ADDRESS, "no permission");
        uint256 balance = address(this).balance;
        require(balance > 0, "MelosA: Balance should be above 0");
        _payout(DEV_ADDRESS, balance);
    }
    // @dev end of only owner functions
}