pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SummerCoco is ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    string public baseURI;
    uint256 public maxBatch;
    string public defaultURI;
    bytes32 public ogRoot;
    bytes32 public whitelistRoot;

    uint256 public publicPrice;

    uint256 public whitelistPrice;

    uint256 public ogPrice;

    uint256 public ogStartTime;

    uint256 public ogEndTime;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    uint256 public whitelistStartTime;

    uint256 public whitelistEndTime;

    uint256 public publicNum;

    uint256 public whitelistNum;

    uint256 public ogNum;

    uint256 public maxPublicNum;

    uint256 public reservedNum;

    mapping(address => uint256) public ogMined;

    mapping(address => uint256) public whitelistMined;

    mapping(address => uint256) public mined;

    uint256 public premintPrice;

    using Strings for uint256;

    constructor() public ERC721A("Summer coco", "Summer Coco") {
        maxBatch = 3;
        maxSupply = 5555;
        maxPublicNum = 5455;
        whitelistStartTime = 1665327600;
        whitelistEndTime = 99999999999;
        ogStartTime = 1665327600;
        ogEndTime = 99999999999;
        publicStartTime = 1665327600;
        publicEndTime = 99999999999;
        publicPrice = 0.009 ether;
        premintPrice = 0.007 ether;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    function setPrice(
        uint256 _publicPrice,
        uint256 _whitelistPrice,
        uint256 _ogPrice
    ) external onlyOwner {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
        ogPrice = _ogPrice;
    }

    function setMintTime(
        uint256 _ogStartTime,
        uint256 _ogEndTime,
        uint256 _publicStartTime,
        uint256 _publicEndTime,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime
    ) external onlyOwner {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
        ogStartTime = _ogStartTime;
        ogEndTime = _ogEndTime;
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
    }

    function setMaxNum(uint256 _maxPublicNum) external onlyOwner {
        maxPublicNum = _maxPublicNum;
    }

    function mint(address _address, uint256 _num) internal nonReentrant {
        require(totalSupply() + _num <= maxSupply, "Num must lower maxSupply");
        _safeMint(_address, _num);
    }

    function mintReservedBatch(address _address, uint256 _num)
        external
        onlyOwner
    {
        mint(_address, _num);
        reservedNum += _num;
    }

    function mintReserved(address[] calldata _address) external onlyOwner {
        uint256 num = _address.length;

        for (uint256 i = 0; i < num; i++) {
            mint(_address[i], 1);
        }
        reservedNum += num;
    }

    function ogMint(uint256 _num, bytes32[] memory _proof) external payable {
        require(mined[msg.sender] + _num <= maxBatch, "Num must lt or eq 3");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, ogRoot, leaf),
            "Verification failed"
        );
        require(ogStartTime <= block.timestamp, "OgtMint has not started yet");
        require(ogEndTime > block.timestamp, "OgMint has ended");
        require(
            publicNum + _num <= maxPublicNum,
            "Num must lower maxPublicNum"
        );
        uint256 ogFreeNum = 2 - ogMined[msg.sender];
        if (_num < ogFreeNum) {
            ogFreeNum = _num;
        }
        uint256 totalPrice = premintPrice * (_num - ogFreeNum);

        ogNum += ogFreeNum;
        ogMined[msg.sender] += ogFreeNum;
        require(msg.value >= totalPrice, "value not eq");
        mint(msg.sender, _num);

        mined[msg.sender] += _num;
    }

    function whitelistMint(uint256 _num, bytes32[] memory _proof)
        external
        payable
    {
        require(mined[msg.sender] + _num <= maxBatch, "Num must lt or eq 3");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, whitelistRoot, leaf),
            "Verification failed"
        );
        require(
            whitelistStartTime <= block.timestamp,
            "WhitelistMint has not started yet"
        );
        require(whitelistEndTime > block.timestamp, "WhitelistMint has ended");
        require(
            publicNum + _num <= maxPublicNum,
            "Num must lower maxPublicNum"
        );
        uint256 wlFreeNum = 1 - whitelistMined[msg.sender];
        if (_num < wlFreeNum) {
            wlFreeNum = _num;
        }
        uint256 totalPrice = premintPrice * (_num - wlFreeNum);

        whitelistNum += wlFreeNum;
        whitelistMined[msg.sender] += wlFreeNum;
        require(msg.value >= totalPrice, "value not eq");
        mint(msg.sender, _num);

        mined[msg.sender] += _num;
    }

    function publicMint(uint256 _num) public payable {
        require(mined[msg.sender] + _num <= maxBatch, "Num must lt or eq 3");
        require(
            msg.value == publicPrice * _num,
            "Value must eq publicPrice*num"
        );

        require(
            publicStartTime <= block.timestamp,
            "PublicMint has not started yet"
        );
        require(publicEndTime > block.timestamp, "PublicMint has ended");
        require(
            publicNum + _num <= maxPublicNum,
            "Num must lower maxPublicNum"
        );
        mint(msg.sender, _num);
        publicNum += _num;

        mined[msg.sender] += _num;
    }

    function setRoot(bytes32 _ogRoot, bytes32 _whitelistRoot)
        external
        onlyOwner
    {
        ogRoot = _ogRoot;
        whitelistRoot = _whitelistRoot;
    }

    function setMaxBatch(uint256 _maxBatch) public onlyOwner {
        maxBatch = _maxBatch;
    }

    function withdrawETH(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(IERC20 _token, address _to) external onlyOwner {
        _token.transfer(_to, _token.balanceOf(address(this)));
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
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
            : defaultURI;

        return imageURI;
    }
}