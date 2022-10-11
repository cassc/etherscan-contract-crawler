pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract LittleMamiPASS is ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    string public baseURI;
    uint256 public maxBatch;
    string public defaultURI;
    bytes32 public root;

    uint256 public presalePrice;

    uint256 public whitelistPrice;

    uint256 public presaleStartTime;

    uint256 public presaleEndTime;

    uint256 public whitelistStartTime;

    uint256 public whitelistEndTime;

    uint256 public presaleNum;

    uint256 public whitelistNum;

    uint256 public maxPresaleNum;

    uint256 public maxWhitelistNum;

    uint256 public reservedNum;

    uint256 public maxReservedNum;

    mapping(address => bool) public whitelistMined;

    mapping(address => bool) public presaleMined;

    mapping(uint256 => bool) public blackList;

    using Strings for uint256;

    constructor() public ERC721A("Litte Mami Pass NFT Pro", "Litte Mami Pass NFT Pro") {
        maxBatch = 3;
        uint256 _maxSupply = 1100;
        maxSupply = _maxSupply;
        maxReservedNum = 1;
        maxWhitelistNum = 100;
        maxPresaleNum = 999;
        whitelistStartTime = 1655715600;
        whitelistEndTime = 1655888400;
        whitelistPrice = 0.5 ether;
        presaleStartTime = 1655722800;
        presaleEndTime = 1655888400;
        presalePrice = 0.45 ether;
        baseURI = "ipfs://QmSJXWDTo6fo6dsQjLCm15cWF7QYU8Cr6Hyvy1TNEoEAUF/";
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            require(!blackList[i], "In blacklist");
        }
    }

    function setBlackList(uint256[] calldata _blackList, bool _status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _blackList.length; i++) {
            blackList[_blackList[i]] = _status;
        }
    }

    function setPrice(uint256 _presalePrice, uint256 _whitelistPrice)
        external
        onlyOwner
    {
        presalePrice = _presalePrice;
        whitelistPrice = _whitelistPrice;
    }

    function setPresaleTime(
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime
    ) external onlyOwner {
        require(_whitelistEndTime > _whitelistStartTime);
        require(_presaleEndTime > _presaleStartTime);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
    }

    function setMaxNum(
        uint256 _maxPresaleNum,
        uint256 _maxWhitelistNum,
        uint256 _maxReservedNum
    ) external onlyOwner {
        maxPresaleNum = _maxPresaleNum;
        maxWhitelistNum = _maxWhitelistNum;
        maxReservedNum = _maxReservedNum;
    }

    function snapshot(address[] calldata _addrs) external onlyOwner {
        require(
            totalSupply() + _addrs.length <= maxSupply,
            "Num must lower maxSupply"
        );
        for (uint256 i = 0; i < _addrs.length; i++) {
            _mint(_addrs[i], 1);
        }
    }

    function mint(address _addresss, uint256 _num) internal nonReentrant {
        require(totalSupply() + _num <= maxSupply, "Num must lower maxSupply");
        _mint(_addresss, _num);
    }

    function _startTokenId() internal view override returns (uint256) {
        super._startTokenId();
        return 1;
    }

    function mintReserved(address _address, uint256 _num) external onlyOwner {
        require(
            reservedNum + _num <= maxReservedNum,
            "reservedNum must lower maxReservedNum"
        );
        mint(_address, _num);
        reservedNum += _num;
    }

    function presaleWhitelist(uint256 _num, bytes32[] memory _proof)
        external
        payable
    {
        require(_num == 1, "Num must be 1");
        require(!whitelistMined[msg.sender], "Already whitelist mined");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, leaf), "Verification failed");
        require(
            msg.value == whitelistPrice * _num,
            "Value must eq whitelistPrice*num"
        );
        require(
            whitelistStartTime <= block.timestamp,
            "Whitelist pre-sale has not started yet"
        );
        require(
            whitelistEndTime > block.timestamp,
            "Whitelist pre-sale has ended"
        );
        require(
            whitelistNum + _num <= maxWhitelistNum,
            "Num must lower maxWhitelistNum"
        );
        mint(msg.sender, _num);
        whitelistNum += _num;
        whitelistMined[msg.sender] = true;
    }

    function presale(uint256 _num) external payable {
        // require(!presaleMined[msg.sender], "Already presale mined");
        require(
            msg.value == presalePrice * _num,
            "Value must eq presalePrice1*num"
        );
        require(
            presaleStartTime <= block.timestamp,
            "Pre-sale has not started yet"
        );
        require(presaleEndTime > block.timestamp, "Pre-sale has ended");
        require(
            presaleNum + _num <= maxPresaleNum,
            "Num must lower maxPresaleNum"
        );
        mint(msg.sender, _num);
        presaleNum += _num;
        // presaleMined[msg.sender] = true;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMaxBatch(uint256 _maxBatch) public onlyOwner {
        maxBatch = _maxBatch;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : defaultURI;

        return imageURI;
    }
}