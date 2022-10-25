// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HCB_NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.007 ether;
    uint256 public maxSupply = 7777;
    uint256 public preSupply = 3600;
    uint256 public wlSupply = 600;
    uint256 public dropSupply = 540;
    uint256 public dropAmount = 0;
    uint256 public maxMintAmount = 2;
    uint256 public currentStage = 0;
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;
    Member[] public members;

    struct Member {
        address account;
        uint32 value;
        uint32 total;
    }

    mapping(address => uint256) private mintAmountClaimed;

    bytes32 public saleMerkleRoot;

    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        Member[] memory _members
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        initMembers(_members);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount)
    public
    payable
    isValidMintAmount(_mintAmount, maxSupply) {
        uint256 supply = totalSupply();
        require(currentStage == 2, "public sale has not begin");
        require(msg.value >= cost * _mintAmount);

        mintAmountClaimed[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function preMint(uint256 _mintAmount)
    public
    payable
    isValidMintAmount(_mintAmount, preSupply) {
        uint256 supply = totalSupply();
        require(currentStage == 1, "Pre sale has not begin");

        mintAmountClaimed[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function whiteMint(uint256 _mintAmount, bytes32[] calldata merkleProof)
    external
    payable
    isValidMerkleProof(merkleProof, saleMerkleRoot)
    isValidMintAmount(_mintAmount, wlSupply) {
        uint256 supply = totalSupply();
        require(currentStage == 0, "Wl mint has not begin");

        mintAmountClaimed[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in wl"
        );
        _;
    }

    modifier isValidMintAmount(uint256 _mintAmount, uint256 _supply) {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount, "Exceed max mint amount");
        require(supply + _mintAmount <= _supply, "Exceed the total amount limit");
        require(mintAmountClaimed[msg.sender] + _mintAmount <= maxMintAmount, "Exceed max mint amount per wallet");
        _;
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }


    function batchDropHCB(address dropAddress, uint256 numToDrop)
    external
    onlyOwner
    isValidDropAmount(numToDrop)
    {
        uint256 supply = totalSupply();
        dropAmount += numToDrop;

        for (uint256 i = 1; i <= numToDrop; i++) {
            _safeMint(dropAddress, supply + i);
        }
    }

    modifier isValidDropAmount(uint256 numToDrop) {
        uint256 supply = totalSupply();
        require(
            dropAmount + numToDrop <= dropSupply,
            "Exceed the dropSupply amount limit"
        );
        require(
            supply + numToDrop <= maxSupply,
            "Exceed the total amount limit"
        );
        _;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setCurrentStage(uint256 _stage) public onlyOwner {
        currentStage = _stage;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function initMembers(Member[] memory _members) private {
        for (uint i = 0; i < _members.length; i++) {
            members.push(_members[i]);
        }
    }

    function withdraw() public payable onlyOwner {
        require(members.length > 0, "Empty members");
        uint256 balance = address(this).balance;
        for (uint i = 0; i < members.length; i++) {
            Member memory m = members[i];
            _streamTransfer(m.account, balance * m.value / m.total);
        }
    }

    error StreamTransferFailed();

    function _streamTransfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert StreamTransferFailed();
    }

}