pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../roles/AccessRole.sol";

contract Basketball is IERC2981Upgradeable, ERC165StorageUpgradeable, OwnableUpgradeable, IERC1155MetadataURIUpgradeable, ERC1155Upgradeable
    , AccessRole, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    struct GameInfo {
        uint totalCount;
        uint claimedCount;
        bytes32 rootkey;
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // merkle tree root
    bytes32 public gcfRoot;
    bytes32 public communityRoot;

    string public name;
    string public symbol;

    //Token URI prefix
    string public tokenURIPrefix;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    address public royalty;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    uint256 public constant royaltyPercent = 5;

    /// @dev total mint supply
    uint256 public totalsupply;

    /// @dev total reserve supply
    uint256 public totalReservedSupply;

    /// @dev total reserve supply
    uint256 public totalThreePointSupply;

    /// @dev max mint supply
    uint256 public maxsupply;

    /// @dev max mint count per transaction
    uint256 public maxMintCount;

    /// @dev drop phase
    uint256 public dropPhase;

    ///@dev mint price
    uint256 public mintprice; 

    /// @dev reserve count mapping
    mapping(address => uint) public reserveCount;

    /// @dev mapping for game info
    mapping(uint => GameInfo) public gameInfo;

    /// @dev mapping for minted of GCF whiltelist minting
    mapping(address => bool) public mintedForGCF;

    /// @dev mapping for minted of community whiltelist minting
    mapping(address => bool) public mintedForCommunity;
    
    /// @dev mapping for minted of 3 point score
    mapping(address => mapping(uint => bool)) mintedForGame;

    ///@dev airdrop flag
    bool public isAirdroped;

    event claimedFromThreePoint(uint256 indexed gameId, address indexed beneficiary);

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _tokenURIPrefix token URI Prefix
    */
    function initialize(string memory _name, string memory _symbol, string memory _tokenURIPrefix, address _royalty, 
        bytes32 _gcfRoot, bytes32 _communityRoot) public initializer {
        ERC165StorageUpgradeable.__ERC165Storage_init();
        OwnableUpgradeable.__Ownable_init();
        ERC1155Upgradeable.__ERC1155_init(_tokenURIPrefix);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AccessRole.initialize();

        name = _name;
        symbol = _symbol;
        tokenURIPrefix = _tokenURIPrefix;
        royalty = _royalty;
        gcfRoot = _gcfRoot;
        communityRoot = _communityRoot;
        dropPhase = 0;
        totalsupply = 0;
        totalReservedSupply = 0;
        maxsupply = 20000;
        mintprice = 0.07 ether;
        maxMintCount = 3;
        isAirdroped = false;

        addAdmin(_msgSender());
        addMinter(_msgSender());
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * @dev Creates a new token type and assings _initialSupply to minter
     * @param _beneficiary address where mint to
     * @param _id token Id
     * @param _supply mint supply
    */
    function safeMint(address _beneficiary, uint256 _id, uint256 _supply) internal {
        require(_supply != 0, "Supply should be positive");

        _mint(_beneficiary, _id, _supply, "");
    }

    /**
     * @dev burn token with id and value
     * @param _owner address where mint to
     * @param _id token Id which will burn
     * @param _value token count which will burn
    */
    function burn(address _owner, uint256 _id, uint256 _value) external {
        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender) == true, "Need operator approval for 3rd party burns.");

        _burn(_owner, _id, _value);
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param _tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
    }

    /**
     * @dev function which return token URI
     * @param _id token Id
     */
    function uri(uint256 _id) override(ERC1155Upgradeable, IERC1155MetadataURIUpgradeable) virtual public view returns (string memory) {
        return bytes(tokenURIPrefix).length > 0 ? string(abi.encodePacked(tokenURIPrefix, _id.toString())) : "";
    }

        /**
     * @dev reserve function for reserve mint.
     */
    function reserve(uint256 _count) external payable {
        require((totalsupply + totalReservedSupply + _count) <= maxsupply, "overflow maxsupply");
        require(_count <= maxMintCount, "too many count for one transaction");
        require(msg.value >= (mintprice * _count), "mintprice is not enough");
        reserveCount[msg.sender] += _count;
        totalReservedSupply += _count;
    }

    /**
     * @dev mint function.
     */
    function mint(uint256 _count, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(dropPhase > 0, "not the drop period");
        require(maxsupply >= (totalsupply + totalReservedSupply + _count), "overflow maxsupply");
        require(_count <= maxMintCount, "too many count for one transaction");

        if(dropPhase == 1) {
            require(mintedForGCF[msg.sender] == false, "have already minted to this address");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _count));
            require(MerkleProofUpgradeable.verify(_merkleProof, gcfRoot, leaf), "Invalid Proof");
            safeMint(msg.sender, 1, _count);
            mintedForGCF[msg.sender] = true;
            totalsupply+=_count;
        } else if(dropPhase == 2) {
            require(mintedForCommunity[msg.sender] == false, "have already minted to this address");
            require(msg.value >= (mintprice * _count), "mintprice is not enough");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _count));
            require(MerkleProofUpgradeable.verify(_merkleProof, communityRoot, leaf), "Invalid Proof");
            safeMint(msg.sender, 1, _count);
            mintedForCommunity[msg.sender] = true;
            totalsupply+=_count;
        } else if(dropPhase == 3) {
            if(reserveCount[msg.sender] == 0)
                require(msg.value >= (mintprice * _count), "mintprice is not enough");
            else
                require(reserveCount[msg.sender] >= _count, "not enough reserved token");

            safeMint(msg.sender, 1, _count);
            totalsupply += _count;
            
            if(reserveCount[msg.sender] >= _count) {
                reserveCount[msg.sender] -= _count;
                totalReservedSupply -= _count;
            }
        } else {}
    }

    function mintForAirdrop(uint256 _airdropCount) external onlyOwner {
        require(!isAirdroped, "have already airdropped");
        _mint(msg.sender, 1, _airdropCount, "");
        totalThreePointSupply = _airdropCount;
        isAirdroped = true;
    }

    function claimFromThreePoint(uint256 _gameId, bytes32[] calldata _merkleProof, address _beneficiary) public nonReentrant {
        require(gameInfo[_gameId].totalCount > gameInfo[_gameId].claimedCount, "have already minted all NFTs");
        require(mintedForGame[_beneficiary][_gameId] == false, "have already minted to this address");

        bytes32 leaf = keccak256(abi.encodePacked(_beneficiary));
        require(MerkleProofUpgradeable.verify(_merkleProof, gameInfo[_gameId].rootkey, leaf), "Invalid Proof");
        safeMint(_beneficiary, 1, 1);
        mintedForGame[_beneficiary][_gameId] = true;
        gameInfo[_gameId].claimedCount++;
        totalThreePointSupply++;
        emit claimedFromThreePoint(_gameId, _beneficiary);
    }

    function setDropPhase(uint256 _dropPhase) external onlyOwner {
        require(_dropPhase <= 3, "dropPhase shold be not greater than 3");
        dropPhase = _dropPhase;
    }

    function setMintPrice(uint256 _mintprice) external onlyOwner {
        require(_mintprice > 0, "mint price shold be not 0");
        mintprice = _mintprice;
    }

    function setMaxMintCount(uint256 _maxMintCount) external onlyOwner {
        require(_maxMintCount > 0, "max mint count should be not 0");
        maxMintCount = _maxMintCount;
    }

    /**
     * @dev set maxsupply function
     */
    function setMaxSupply(uint256 _maxsupply) external onlyAdmin {
        maxsupply = _maxsupply;
    }

    /**
     * @dev set gcfRoot function
     */
    function setGCFRoot(bytes32 _gcfRoot) external onlyAdmin {
        gcfRoot = _gcfRoot;
    }

    /**
     * @dev set communityRoot function
     */
    function setCommunityRoot(bytes32 _communityRoot) external onlyAdmin {
        communityRoot = _communityRoot;
    }

    /**
     * @dev set game root key
     */
    function setGameRootKey(uint256 _gameId, bytes32 _rootkey, uint _totalCount) external onlyAdmin {
        GameInfo memory ri;
        ri.rootkey = _rootkey;
        ri.totalCount = _totalCount;
        ri.claimedCount = 0;
        gameInfo[_gameId] = ri;
    }

    /**
     * @dev withdraw all ethers to owner.
     */
    function withdraw() public payable onlyOwner {
        address payable ownerAddress =  payable(msg.sender);
        ownerAddress.transfer(address(this).balance);
    }

    function royaltyInfo(uint256 , uint256 salePrice) external view override(IERC2981Upgradeable) returns (address receiver, uint256 royaltyAmount) {
        receiver = royalty;
        royaltyAmount = salePrice.mul(royaltyPercent).div(100);
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165Upgradeable, ERC165StorageUpgradeable, ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}