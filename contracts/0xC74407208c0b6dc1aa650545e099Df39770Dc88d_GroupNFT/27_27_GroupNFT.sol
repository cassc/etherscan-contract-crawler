// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GroupNFT is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {

    uint8 public constant TEAM_COUNT = 32;

    uint8 public _phase;
    uint256 public _saleStartTime = 253400630399;
    uint256 public _startTime = 253400630399;
    uint256 public constant WHITELIST_MINT_DURATION = 3600;

    uint256 public _price = 50000000000000000;

    uint256 public _saleSupplyPerTeam = 30;
    uint256 public _freeSupply;
    uint256 public _freeTotalSupplyPerTeam;

    uint256 public _freeTokenId = 960;

    // team => count
    mapping(uint8 => uint256) public _saleCount;

    bytes32 public _whitelistMerkleRoot;

    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    mapping(uint8 => mapping(address => uint256)) public _freeCountPerPhase;
    mapping(uint8 => mapping(address => uint256)) public _wlCountPerPhase;

    // false: normal; true: in prediction
    mapping(uint256 => bool) private _tokenStatus;

    // Group predict contract address
    address public GROUP_PREDICT_ADDRESS;

    string private _metadataURI;

    event Buy(address indexed _sender, uint256 indexed _tokenId, uint256 indexed _team);
    event Mint(address indexed _sender, uint256 indexed _tokenId, uint256 indexed _team);
    event MintByWhiteList(address indexed _sender, uint256 indexed _tokenId, uint256 indexed _team);

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }

    modifier onlyPredictOrOwner {
        require(
            msg.sender == owner() ||
            msg.sender == GROUP_PREDICT_ADDRESS,
            "caller is not owner or predict contract"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {

    }

    /**
        ****************************************
        NFT mint functions
        ****************************************
    */

    function buy(uint8 team) external payable nonReentrant whenNotPaused isNotContract {
        require(block.timestamp >= _saleStartTime, "not start");
        require(team < TEAM_COUNT, "invalid parameter");
        require(_saleCount[team] <= _saleSupplyPerTeam, "sold out");
        require(msg.value == _price, "invalid ETH balance");

        uint256 tokenId = team + _saleCount[team] * TEAM_COUNT;
        _saleCount[team]++;
        _safeMint(msg.sender, tokenId);
        emit Buy(msg.sender, tokenId, team);
    }

    function mint() external nonReentrant whenNotPaused isNotContract {
        require(block.timestamp >= _startTime + WHITELIST_MINT_DURATION, "not start");
        require(_freeSupply <= _freeTotalSupplyPerTeam * TEAM_COUNT, "sold out");
        require(_freeCountPerPhase[_phase][msg.sender] < MAX_PUBLIC_MINT, "mint limit for free");

        _freeSupply++;
        _freeCountPerPhase[_phase][msg.sender]++;
        _safeMint(msg.sender, _freeTokenId);
        emit Mint(msg.sender, _freeTokenId, uint8(_freeTokenId % TEAM_COUNT));
        _freeTokenId++;
    }

    function mintByWhiteList(bytes32[] calldata proof) external nonReentrant whenNotPaused isNotContract {
        require(block.timestamp >= _startTime, "not start");
        require(_freeSupply <= _freeTotalSupplyPerTeam * TEAM_COUNT, "sold out");
        require(_wlCountPerPhase[_phase][msg.sender] < MAX_WHITELIST_MINT, "mint limit for whitelist");

        bytes32 leaf = _leaf(msg.sender);
        require(
            _verify(_whitelistMerkleRoot, leaf, proof),
            "bad whitelist merkle proof"
        );

        _freeSupply++;
        _wlCountPerPhase[_phase][msg.sender]++;
        _safeMint(msg.sender, _freeTokenId);
        emit MintByWhiteList(msg.sender, _freeTokenId, uint8(_freeTokenId % TEAM_COUNT));
        _freeTokenId++;
    }

    /**
        ****************************************
        Query functions
        ****************************************
    */

    function getTeam(uint256 tokenId) external view returns (uint256) {
        _requireMinted(tokenId);
        return tokenId % TEAM_COUNT;
    }

    function getSaleInfo() external view returns (uint256[32] memory list) {
        for (uint8 i = 0; i < TEAM_COUNT; i++) {
            list[i] = _saleSupplyPerTeam - _saleCount[i];
        }
    }

    function getFreeLeft() external view returns (uint256) {
        return _freeTotalSupplyPerTeam * TEAM_COUNT - _freeSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metadataURI, Strings.toString(tokenId)));
    }

    function getUserFreeLimit(address userAddr) external view returns (uint256) {
        return MAX_PUBLIC_MINT - _freeCountPerPhase[_phase][userAddr];
    }

    function getUserWLLimit(address userAddr) external view returns (uint256) {
        return MAX_WHITELIST_MINT - _wlCountPerPhase[_phase][userAddr];
    }

    function getTokenIds(
        address userAddr,
        uint256 pageNum,
        uint256 pageSize
    ) public view returns (uint256, uint256[] memory) {
        uint256 balance = balanceOf(userAddr);

        uint256 start = (pageNum - 1) * pageSize;
        uint256 end = pageNum * pageSize;
        if (start > balance) {
            return (balance, new uint256[](0));
        }
        if (end > balance) {
            end = balance;
        }

        uint256[] memory tokenIds = new uint256[](end - start);
        uint256 index = start;
        for (uint256 i = 0; i < end - start; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(userAddr, index);
            tokenIds[i] = tokenId;
            index++;
        }
        return (balance, tokenIds);
    }

    /**
        ****************************************
        Predict contract functions
        ****************************************
    */

    function lock(uint256 tokenId) external onlyPredictOrOwner {
        require(!_tokenStatus[tokenId], "token already locked");
        _tokenStatus[tokenId] = true;
    }

    function unlock(uint256 tokenId) external onlyPredictOrOwner {
        require(_tokenStatus[tokenId], "token is not locked");
        _tokenStatus[tokenId] = false;
    }

    /**
        ****************************************
        Admin setting functions
        ****************************************
    */

    function devMint() external onlyOwner {
        require(_freeSupply <= _freeTotalSupplyPerTeam * TEAM_COUNT, "sold out");
        require(_freeCountPerPhase[_phase][msg.sender] < MAX_PUBLIC_MINT, "mint limit for free");

        _freeSupply++;
        _freeCountPerPhase[_phase][msg.sender]++;
        _safeMint(msg.sender, _freeTokenId);
        emit Mint(msg.sender, _freeTokenId, uint8(_freeTokenId % TEAM_COUNT));
        _freeTokenId++;
    }

    function setSaleSupplyPerTeam(uint256 supply) external onlyOwner {
        _saleSupplyPerTeam = supply;
    }

    function nextPhase(
        uint256 startTime,
        uint256 supplyPerTeam,
        bytes32 whitelistMerkleRoot
    ) external onlyOwner {
        _phase++;
        _startTime = startTime;
        _freeTotalSupplyPerTeam = _freeTotalSupplyPerTeam + supplyPerTeam;
        _whitelistMerkleRoot = whitelistMerkleRoot;
    }

    function setPhase(uint8 phase) external onlyOwner {
        _phase = phase;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        _startTime = startTime;
    }

    function setSupplyPerTeam(uint256 freeTotalSupplyPerTeam) external onlyOwner {
        _freeTotalSupplyPerTeam = freeTotalSupplyPerTeam;
    }

    function setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot) external onlyOwner {
        _whitelistMerkleRoot = whitelistMerkleRoot;
    }

    function setSaleStartTime(uint256 startTime) external onlyOwner {
        _saleStartTime = startTime;
    }

    function setMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataURI = metadataURI;
    }

    function setPredictContractAddress(address addr) external onlyOwner {
        GROUP_PREDICT_ADDRESS = addr;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
        ****************************************
        Private functions
        ****************************************
    */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Skip check on minting to reduce gas cost
        if (from == address(0)) {
            return;
        }
        require(!_tokenStatus[tokenId], "token locked in prediction");
    }

    function _leaf(address account) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account));
    }

    function _verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

}