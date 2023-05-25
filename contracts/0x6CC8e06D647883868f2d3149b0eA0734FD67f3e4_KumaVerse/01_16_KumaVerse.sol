// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721ACustom.sol";
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "./Interfaces.sol";

/// @title Kumaverse NFT contract
/// @author agonist (https://github.com/agonist)
contract KumaVerse is ERC721ACustom, Ownable {

    struct KumaHistory {
        string name;
        string lore;
    }

    uint256 public immutable maxSupply;
    uint256 public maxMintAtOnce;
    uint256 public maxMintWhitelist;
    uint256 public price = 0.05 ether;
    uint256 public changeLorePrice = 10 ** 18;
    bool public trackerSaleActive;
    bool public presaleActive;
    bool public saleActive;
    string public baseTokenURI;
    bytes32 public whitelistMerkleRoot = 0x0;
    bool private ancestorUnlocked;

    mapping(address => uint256) public claimed;
    mapping(address => uint256) public claimedTracker;
    mapping(address => bool) public trackerFreeClaimed;

    mapping(uint256 => KumaHistory) public kumaHistories;

    IERC1155 trackerContract;
    IPaw pawContract;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_,
        uint256 maxMintAtOnce_,
        uint256 maxMintWhitelist_,
        address trackerContract_
    ) ERC721ACustom(name_, symbol_){
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
        maxMintAtOnce = maxMintAtOnce_;
        maxMintWhitelist = maxMintWhitelist_;
        trackerContract = IERC1155(trackerContract_);
    }

    function mint(
        uint256 _quantity
    ) external payable {
        require(saleActive, "Sale inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        require(_quantity <= maxMintAtOnce, "Max mint exceeded");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        _safeMint(msg.sender, _quantity);
        pawContract.updateReward(msg.sender);
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive, "Presale inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Not whitelisted");
        require(claimed[msg.sender] + _quantity <= maxMintWhitelist, "Whitelist mint exceeded");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        pawContract.updateReward(msg.sender);
    }

    function mintTracker(uint256 _quantity) external payable {
        require(trackerSaleActive, "TrackerSale inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");

        uint256 trackerBalance = trackerContract.balanceOf(msg.sender, 1);

        require(trackerBalance > 0, "You don't own a tracker");
        require(claimedTracker[msg.sender] + _quantity <= trackerBalance * 2, "Tracker mint exceeded");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        uint256 trackerExtra = 0;
        if (trackerBalance > 0) {
            if (!trackerFreeClaimed[msg.sender]) {
                trackerExtra += trackerBalance;
                trackerFreeClaimed[msg.sender] = true;
            }
        }
        claimedTracker[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity + trackerExtra);
        pawContract.updateReward(msg.sender);
    }

    function claimFreeKuma() external {
        require(trackerSaleActive, "TrackerSale inactive");
        require(!trackerFreeClaimed[msg.sender], "Already claimed");
        uint256 trackerBalance = trackerContract.balanceOf(msg.sender, 1);
        require(trackerBalance > 0, "You don't own a tracker");
        require(totalSupply() + trackerBalance <= maxSupply, "Mint exceed max supply");

        trackerFreeClaimed[msg.sender] = true;
        _safeMint(msg.sender, trackerBalance);
        pawContract.updateReward(msg.sender);
    }

    /// @notice Check if someone is whitelisted
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function changeLore(uint256 _id, string calldata _lore) external {
        require(this.ownerOf(_id) == msg.sender, "You are not the owner");
        require(pawContract.transferFrom(msg.sender, address(this), changeLorePrice), "PAW transfer failed");

        kumaHistories[_id].lore = _lore;
    }

    function renameKuma(uint256 _id, string calldata _newName) external {
        require(this.ownerOf(_id) == msg.sender, "You are not the owner");
        require(pawContract.transferFrom(msg.sender, address(this), changeLorePrice), "PAW transfer failed");

        kumaHistories[_id].name = _newName;
    }

    function updateHistory(uint256 _id, string calldata _newName, string calldata _lore) external {
        require(this.ownerOf(_id) == msg.sender, "You are not the owner");
        require(pawContract.transferFrom(msg.sender, address(this), changeLorePrice * 2), "PAW transfer failed");

        kumaHistories[_id] = KumaHistory(_newName, _lore);
    }

    // ADMIN

    /// @notice mint 10 extra NFTs that are the Ancestors that will be auctioned by the project.
    /// to use only after soldout
    function unlockAncestors() external onlyOwner {
        require(!ancestorUnlocked, "Ancestor already unlocked");
        _safeMint(msg.sender, 10);
        pawContract.updateReward(msg.sender);
        ancestorUnlocked = true;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleTrackerSale() external onlyOwner {
        trackerSaleActive = !trackerSaleActive;
    }

    /// @notice for marketing / team
    /// @param _quantity Amount to mint
    function reserve(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        _safeMint(msg.sender, _quantity);
        pawContract.updateReward(msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _yieldTransferHook(address _from, address _to) internal {
        pawContract.updateReward(_from);
        pawContract.updateReward(_to);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
        _yieldTransferHook(from_, to_);
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
        _yieldTransferHook(from_, to_);
        ERC721ACustom.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function setChangeLorePrice(uint256 _price) external onlyOwner {
        changeLorePrice = _price ** 18;
    }

    function setPaw(address _address) public onlyOwner {
        pawContract = IPaw(_address);
    }

    function setTracker(address _address) public onlyOwner {
        trackerContract = IERC1155(_address);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawPaw() external onlyOwner {
        uint256 balance = pawContract.balanceOf(address(this));
        pawContract.transfer(msg.sender, balance);
    }
}