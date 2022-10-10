// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721ACustom.sol";
import "./Interfaces.sol";
import "./Punakawan.sol";

/// @title RiseOfPunakawan NFT Contract
/// @author N.I.B|Neuromancer (https://github.com/pixl-cat)


contract RiseOfPunakawan is ERC721ACustom, Ownable {


    uint256 public immutable maxSupply;
    uint256 public immutable maxSummon = 1400;
    uint256 public maxMintAtOnce;
    uint256 public maxMintOg;
    uint256 public maxMintWhitelist;
    uint256 public price = 0.02 ether;
    uint256 public ogPrice = 0.00 ether;
    uint256 public presalePrice = 0.01 ether;
    uint256 public summonPrice = 1500 * (10 ** 18); //1500 Prajna

    bool public ogsaleActive;
    bool public presaleActive;
    bool public saleActive;
    bool public summonActive;
    bool public typesFrozen = false;

    string public baseTokenURI;

    bytes32 public ogMerkleRoot = 0x0;
    bytes32 public whitelistMerkleRoot = 0x0;

    mapping(uint256 => uint256) private typesMap;
    mapping(address => uint256) public ogClaimed;
    mapping(address => uint256) public claimed;

    struct CharacterType {
        uint256 id;
        uint256 firstType;
    }

    IPrajna prajnaContract;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_,
        uint256 maxMintAtOnce_,
        uint256 maxMintOg_,
        uint256 maxMintWhitelist_
    ) ERC721ACustom(name_, symbol_){
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
        maxMintAtOnce = maxMintAtOnce_;
        maxMintOg = maxMintOg_;
        maxMintWhitelist = maxMintWhitelist_;

    }

    function mint (
        uint256 _quantity
    ) external payable {
        require(saleActive, "Sale Inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        require(_quantity <= maxMintAtOnce, "Max mint exceeded");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        _safeMint(msg.sender, _quantity);
        prajnaContract.updateReward(msg.sender);
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive, "Presale Inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Not whitelisted");
        require(claimed[msg.sender] + _quantity <= maxMintWhitelist, "Whitelist mint exceeded");
        require(presalePrice * _quantity == msg.value, "Value sent is incorrect");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        prajnaContract.updateReward(msg.sender);
    }

    function mintOg(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        require(ogsaleActive, "OG Sale Inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), "You are not OG");
        require(ogClaimed[msg.sender] + _quantity <= maxMintOg, "OG mint exceeded");
        require(ogPrice * _quantity == msg.value, "Value sent is incorrect");

        ogClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        prajnaContract.updateReward(msg.sender);

    }

    /// @notice Check if someone is whitelisted
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function isOG(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf);
    }

    /// @notice store type for summon

    function storeType(CharacterType[] calldata _items) external onlyOwner {
        require(!typesFrozen, "Types are frozen");
        for (uint256 i = 0; i < _items.length; i++) {
            CharacterType memory t = _items[i];
            typesMap[t.id] = t.firstType;
        }
    }

    function freezeType() external onlyOwner {
        typesFrozen = true;
    }

    /// @notice summon functions

    function summon(
        uint256 amount,
        uint256 firstId,
        uint256 secondId,
        uint256 thirdId
    ) external {
        require(summonActive, "Breeding inactive");
        require(
            totalSupply() + amount <= maxSupply + maxSummon,
            "Max summons reached"
        );
        require(
            prajnaContract.balanceOf(msg.sender) >= summonPrice * amount,
            "Not enough Prajna"
        );
        require(
            msg.sender == ownerOf(firstId) && msg.sender == ownerOf(secondId) && msg.sender == ownerOf(thirdId),
            "You're not the owner"
        );
        uint256 t1 = typesMap[firstId];
        uint256 t2 = typesMap[secondId];
        uint256 t3 = typesMap[thirdId];
        require(isSummonCompatible(t1, t2, t3), "Can't summon. Incompatible");

        _summon(amount);
    }

    function _summon(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (mintIndex <= maxSupply + maxSummon) {
                prajnaContract.burn(msg.sender, summonPrice);
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function isSummonCompatible(uint256 t1, uint256 t2, uint256 t3)
    internal
    pure
    returns (bool)
    {
        return
        (isBagong(t1) && isPetruk(t2) && isGareng(t3))  ||
        (isBagong(t1) && isGareng(t3) && isPetruk(t2))  ||
        (isPetruk(t2) && isBagong(t1) && isGareng(t3))  ||
        (isPetruk(t2) && isGareng(t3) && isBagong(t3))  ||
        (isGareng(t3) && isBagong(t1) && isPetruk(t2))  ||
        (isGareng(t3) && isPetruk(t2) && isBagong(t1));
    }

    /// @notice token types

    function isBagong(uint256 tokenType) internal pure returns (bool) {
        return tokenType == 1;
    }

    function isPetruk(uint256 tokenType) internal pure returns (bool) {
        return tokenType == 2;
    }

    function isGareng(uint256 tokenType) internal pure returns (bool) {
        return tokenType == 3;
    }

    function isSemar(uint256 tokenType) internal pure returns (bool) {
        return tokenType == 4;
    }

    /// ADMIN

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleOgsale() external onlyOwner {
        ogsaleActive = !ogsaleActive;
    }

    function toggleSummon() external onlyOwner {
        summonActive = !summonActive;
    }


    /// @notice for marketing / team
    /// @param _quantity Amount to mint
    function reserve(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        _safeMint(msg.sender, _quantity);
        prajnaContract.updateReward(msg.sender);
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

    function setOgMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        ogMerkleRoot = _merkleRoot;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _yieldTransferHook(address _from, address _to) internal {
        prajnaContract.updateReward(_from);
        prajnaContract.updateReward(_to);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
        _yieldTransferHook(from_, to_);
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
        _yieldTransferHook(from_, to_);
        ERC721ACustom.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function setPrajna(address _address) public onlyOwner {
        prajnaContract = IPrajna(_address);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawPrajna() external onlyOwner {
        uint256 balance = prajnaContract.balanceOf(address(this));
        prajnaContract.transfer(msg.sender, balance);
    }

}