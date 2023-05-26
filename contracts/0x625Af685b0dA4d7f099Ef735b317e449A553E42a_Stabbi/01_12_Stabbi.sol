// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Stabbi is ERC721A, ReentrancyGuard, Ownable {
    using Address for address;

    enum State {
        Setup,
        NormalMint,
        WhitelistMint,
        Finished
    }

    uint256 public maxSupply = 750;
    uint256 public price = 0.0012 ether;
    uint256 public capsuleCounter = 0;
    bytes32 public merkleRoot;

    State private _state;
    string private _tokenUriBase;
    IERC1155 private _greetingToken;

    mapping(uint256 => mapping(address => bool)) private _mintedInBlock;

    event mintEvent(
        address indexed user,
        uint256 quantity,
        string indexed name,
        uint256 tokenId
    );

    constructor() ERC721A("Kill Team Stabbi Collection", "KTSC") {
        _state = State.Setup;
    }

    function setBonusToken(address greetingToken) external onlyOwner {
        _greetingToken = IERC1155(greetingToken);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }

    function setStateToNormalMint() public onlyOwner {
        _state = State.NormalMint;
    }

    function setStateToWhitelistMint() public onlyOwner {
        _state = State.WhitelistMint;
    }

    function setStateToFinished() public onlyOwner {
        _state = State.Finished;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenBaseURI(string memory tokenUriBase) public onlyOwner {
        _tokenUriBase = tokenUriBase;
    }

    function normalMint(
        uint256 quantity,
        string memory attr
    ) external payable nonReentrant {
        address sender = msg.sender;
        uint256 blockNumber = block.number;
        require(quantity <= 5, "quantity must be less than or equal to 5");
        require(
            capsuleCounter + quantity < maxSupply + 1,
            "amount should not exceed max supply"
        );
        require(_state == State.NormalMint, "sale is not active");
        require(sender == tx.origin, "mint from contract not allowed");
        require(msg.value >= quantity * price, "ether value sent is incorrect");
        require(
            !Address.isContract(sender),
            "contracts are not allowed to mint"
        );
        require(
            _mintedInBlock[blockNumber][sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[blockNumber][sender] = true;
        capsuleCounter = capsuleCounter + quantity;
        uint256 total = quantity * 3;
        if (_greetingToken.balanceOf(sender, 1) > 0) ++total;
        _safeMint(sender, total);
        uint256 tokenId = totalSupply() - total;
        emit mintEvent(sender, total, attr, tokenId);
    }

    function mintBatch(
        address receiver,
        uint256 quantity,
        string memory attr
    ) external onlyOwner {
        _safeMint(receiver, quantity);
        uint256 tokenId = totalSupply() - quantity;
        emit mintEvent(receiver, quantity, attr, tokenId);
    }

    function airdrop(
        address[] calldata wallets,
        uint256[] memory quantity,
        string[] memory attr
    ) external onlyOwner {
        require(
            wallets.length == quantity.length || wallets.length == attr.length,
            "length mismatch"
        );
        for (uint8 i = 0; i < wallets.length; i++) {
            _safeMint(wallets[i], quantity[i]);
            uint256 tokenId = totalSupply() - quantity[i];
            emit mintEvent(wallets[i], quantity[i], attr[i], tokenId);
        }
    }

    function whitelistMint(
        uint256 quantity,
        string memory attr,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        address sender = msg.sender;
        uint256 blockNumber = block.number;
        require(quantity <= 5, "quantity must be less than or equal to 5");
        require(
            capsuleCounter + quantity < maxSupply+1,
            "amount should not exceed max supply"
        );
        require(_state == State.WhitelistMint, "mint is not active");
        require(sender == tx.origin, "mint from contract not allowed");
        require(msg.value >= quantity * price, "ether value sent is incorrect");
        require(
            !Address.isContract(sender),
            "contracts are not allowed to mint"
        );
        require(
            _mintedInBlock[blockNumber][sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[blockNumber][sender] = true;

        bytes32 leaf = keccak256(abi.encodePacked(sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof."
        );

        capsuleCounter = capsuleCounter + quantity;
        uint256 total = quantity * 3;
        if (_greetingToken.balanceOf(msg.sender, 1) > 0) ++total;

        _safeMint(msg.sender, total);
        uint256 tokenId = totalSupply() - total;
        emit mintEvent(sender, total, attr, tokenId);
    }

    function withdrawAll(address recipient) public onlyOwner {
        require(recipient != address(0), "recipient is the zero address");
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawAllViaCall(address payable to) public onlyOwner {
        require(to != address(0), "recipient is the zero address");
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}