// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

contract GDrake is ERC721A {
    using Strings for uint256;
    bytes32 public merkleRoot;

    address private _owner;
    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Gduck basic info
    uint256 public maxSupply;
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxBalance = 10;
    uint256 public wlMintAmount = 1;
    uint256 public normalFreeMint = 1;

    address private teamHolder;

    uint256 public wlStartTime;
    uint256 public wlEndTime;
    string public baseURI = "";
    string public notRevealedUri;
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public wlMintedAddress;

    mapping(address=>bool) private adminAddressList;

    modifier onlyOwner() {
        require(adminAddressList[msg.sender], "only owner");
        _;
    }

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        bytes32 _merkleTreeRoot,
        address _teamHolder,
        string memory _notRevealedUri,
        uint256 _maxSupply
    ) ERC721A("GDrake", "GD") {
        adminAddressList[msg.sender] = true;
        wlStartTime = _startTime;
        wlEndTime = _endTime;
        merkleRoot = _merkleTreeRoot;
        teamHolder = _teamHolder;
        notRevealedUri = _notRevealedUri;
        maxSupply = _maxSupply;
        setSaleActive(true);
    }

    function mint(uint256 tokenQuantity) public payable {
        require(_isSaleActive, "Not Active");
        require(block.timestamp > wlEndTime, "Public Sale Not Start");
        require(tokenQuantity > 0, "Quantity must bigger than zero");
        require(totalSupply() + tokenQuantity <= maxSupply, "Exceed Max");
        uint256 normalMintAmount = balanceOf(msg.sender) - wlMintedAddress[msg.sender];
        require(
            normalMintAmount + tokenQuantity <= maxBalance,
            "Exceed Max Balance"
        );
        uint256 amount = tokenQuantity;
        if (normalMintAmount == 0) {
            amount = tokenQuantity - normalFreeMint;
        }
        uint256 price = amount * mintPrice;
        require(msg.value >= price, "NotEnoughETH");
        _mint(msg.sender, tokenQuantity);
    }

    function wlMint(
        uint256 tokenQuantity,
        address to,
        bytes32[] calldata proof
    ) external {
        require(_isSaleActive, "Not Active");
        require(tokenQuantity > 0, "Quantity must bigger than zero");
        require(block.timestamp > wlStartTime, "Whitelist Sale not start");
        require(block.timestamp <= wlEndTime, "Whitelist Sale was over");

        require(totalSupply() + tokenQuantity <= maxSupply, "Exceed Max");
        require(
            balanceOf(to) + tokenQuantity <= wlMintAmount,
            "Exceed WL Balance"
        );
        bytes32 leaf = keccak256(abi.encodePacked(to, tokenQuantity));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "Not in whitelist");
        wlMintedAddress[to] += tokenQuantity;

        _mint(to, tokenQuantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Not Exist");
        if (_revealed == false) {
            return notRevealedUri;
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    function openBox(string memory _newBaseURI) external onlyOwner {
        uint256 amount = maxSupply - totalSupply();
        _mint(teamHolder, amount);
        setReveal(true);
        setBaseURI(_newBaseURI);
    }

    //Setting functions

    //if something wrong ,solve it
    function setTokenURI(string memory uri, uint256 tokenId)
        external
        onlyOwner
    {
        _tokenURIs[tokenId] = uri;
    }

    function setSaleActive(bool _activeType) public onlyOwner {
        _isSaleActive = _activeType;
    }

    function setReveal(bool _revealedType) public onlyOwner {
        _revealed = _revealedType;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function setwlEndTime(uint256 _endTime) external onlyOwner {
        wlEndTime = _endTime;
    }
    
    function setWlStartTime(uint256 _startTime) external onlyOwner{
        require(_startTime<wlEndTime,"start time mast be early than endTime");
        wlStartTime = _startTime;
    }

    //MerkelTree
    function setMerkleTreeRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }


    //admin
    function setAdminInfo(address _addr,bool _bool) external onlyOwner{
        adminAddressList[_addr] = _bool;
    }

    function setTeamHolder(address _addr) external onlyOwner{
        teamHolder = _addr;
    }
}