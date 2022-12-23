// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract HeartHunterGenesis is ERC721AQueryable, Ownable {
    enum Status {
        Paused,
        Preminting,
        Started
    }

    Status public status = Status.Paused;
    bytes32 public root;
    string public baseURI;
    string public boxURI = "ipfs://QmNqVWzprexBrqqPcRd7nsR7jdGLnSGuLKYs77J4WEYVhm";
    uint256 public MAX_MINT_PER_ADDR = 2;

    uint256 public maxSupply = 500;
    uint256 public preSalePrice = 149000000000000000;
    uint256 public publicSalePrice = 200000000000000000;

    event Minted(address minter, uint256 amount);

    constructor() ERC721A("HeartHunter Genesis", "HG") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        return
        bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : boxURI;
    }


    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "Not minting");
        require(totalSupply() + quantity <= maxSupply, "Hearts exceed");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "Hearts exceed"
        );
        require(quantity > 0, "One heart at least");
        checkPrice(publicSalePrice * quantity);
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function checkPrice(uint256 amount) private {
        require(msg.value >= amount, "Need to send more ETH");
    }

    function allowlistMint(bytes32[] memory _proof, uint256 quantity)
    external
    payable
    {
        require(status == Status.Preminting, "Not preminting");
        require(_verify(_leaf(msg.sender), _proof), "Not allowlisted");
        require(totalSupply() + quantity <= maxSupply, "Hearts exceed");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "Hearts exceed"
        );
        require(quantity > 0, "One heart at least");
        checkPrice(preSalePrice * quantity);
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function devMint(uint256 quantity)
    external
    payable
    onlyOwner
    {
        require(totalSupply() + quantity <= maxSupply, "Hearts exceed");
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function setBoxURI(string calldata uri) public onlyOwner {
        boxURI = uri;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function setPreSalePrice(uint256 newPrice) public onlyOwner {
        preSalePrice = newPrice;
    }

    function setPublicSalePrice(uint256 newPrice) public onlyOwner {
        publicSalePrice = newPrice;
    }

    function setAmount(uint256 amount) public onlyOwner {
        MAX_MINT_PER_ADDR = amount;
    }

    function decreaseMaxSupply(uint256 supply) public onlyOwner {
        require(
            supply <= maxSupply,
            "Max supply must be less than or equal to max supply"
        );
        maxSupply = supply;
    }

    function setStatus(Status newStatus) public onlyOwner {
        status = newStatus;
    }

    function setRoot(uint256 _root) public onlyOwner {
        root = bytes32(_root);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}