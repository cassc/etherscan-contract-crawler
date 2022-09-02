// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721ACustom.sol";




contract PixelEvolutionSoccer is ERC721ACustom, Ownable {


    uint256 public immutable maxSupply;
    uint256 public price = 0.03 ether;
    uint256 public presalePrice = 0.02 ether;
    bool public saleActive;
    bool public presaleActive;
    bytes32 public whitelistMerkleRoot = 0x0;
    string public baseTokenURI;
    string public baseExtension = ".json";



    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC721ACustom(name_, symbol_){
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;

    }

    function mint (
        uint256 _quantity
    ) external payable {
        require(saleActive, "Sale Inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        _safeMint(msg.sender, _quantity);
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive, "Presale inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Not whitelisted");
        require(presalePrice * _quantity == msg.value, "Value sent is incorrect");
        _safeMint(msg.sender, _quantity);
    }

    /// @notice Check if someone is whitelisted
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    // ADMIN

    function toggleSale() external onlyOwner {
    saleActive = !saleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    /// @notice for marketing / team
    /// @param _quantity Amount to mint
    function reserve(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
    }


    function setBaseURI(
    string calldata _baseTokenURI
    ) external onlyOwner {
    baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension)) : "";
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _startTokenId() internal pure override returns (uint256) {
    return 1;
    }


    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
    _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
    ERC721ACustom.safeTransferFrom(from_, to_, tokenId_, data_);
    }



    function withdraw() public onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
    }



}