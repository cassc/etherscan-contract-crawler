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

contract Wearable is ERC721A, ReentrancyGuard, Ownable {
    using Address for address;
    string private _tokenUriBase;
    address public mintableAddress;
    uint256 public MAX_SUPPLY = 10000;
    uint256 private PRICE = 0.035 ether;
    bytes32 public merkleRoot;
    bool revealMintEnable = true;
    
    event mintEvent(address user, uint256 quantity, string name);

    enum State {
        Setup,
        NormalMint,
        whitelistMint,
        PublicMint,
        Finished
    }

    State private _state;

    mapping(uint256 => mapping(address => bool)) private _mintedInBlock;

    constructor() ERC721A("Drug receipts wearable", "DRxW") {
        _state = State.Setup;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setRevealMintEnable() public onlyOwner {
        revealMintEnable = true;
    }

    function setRevealMintDisable() public onlyOwner {
        revealMintEnable = false;
    }

    function setMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }

    function setStateToNormalMint() public onlyOwner {
        _state = State.NormalMint;
    }

    function setStateToWhitelistMint() public onlyOwner {
        _state = State.whitelistMint;
    }

    function setStateToPublicMint() public onlyOwner {
        _state = State.PublicMint;
    }

    function setStateToFinished() public onlyOwner {
        _state = State.Finished;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function setMintableAddress(address _mintableAddress) public onlyOwner {
        mintableAddress = _mintableAddress;
    }

    function revealMint(
        uint256 _quantity,
        address _receiver,
        string memory _name
    ) external nonReentrant {
        require(revealMintEnable, "Not enable to reveal a capsule");
        require(msg.sender == mintableAddress, "not allowed to mint");
        _safeMint(_receiver, _quantity);
        emit mintEvent(_receiver, _quantity, _name);
    }

    function normalMint(uint256 _quantity, string memory _name)
        external
        payable
        nonReentrant
    {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "amount should not exceed max supply"
        );
        require(_state == State.NormalMint, "sale is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(msg.value >= _quantity * PRICE, "ether value sent is incorrect");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            _mintedInBlock[block.number][msg.sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[block.number][msg.sender] = true;

        _safeMint(msg.sender, _quantity);
        emit mintEvent(msg.sender, _quantity, _name);
    }

    function mintBatch(
        address _receiver,
        uint256 _quantity,
        string memory _name
    ) external onlyOwner {
        _safeMint(_receiver, _quantity);
        emit mintEvent(_receiver, _quantity, _name);
    }

    function airdrop(
        address[] calldata _wallets,
        uint256[] memory _quantity,
        string memory _name
    ) external onlyOwner {
        unchecked {
            for (uint8 i = 0; i < _wallets.length; i++) {
                _safeMint(_wallets[i], _quantity[i]);
                emit mintEvent(_wallets[i], _quantity[i], _name);
            }
        }
    }

    function whitelistMint(
        uint256 _quantity,
        string memory _name,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "amount should not exceed max supply"
        );
        require(_state == State.whitelistMint, "mint is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(msg.value >= _quantity * PRICE, "ether value sent is incorrect");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            _mintedInBlock[block.number][msg.sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[block.number][msg.sender] = true;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof."
        );
        _safeMint(msg.sender, _quantity);
        emit mintEvent(msg.sender, _quantity, _name);
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}