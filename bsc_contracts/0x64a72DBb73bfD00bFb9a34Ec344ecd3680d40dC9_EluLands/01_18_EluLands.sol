// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

// ▄▄▄▄▄▄▄ ▄▄▄     ▄▄   ▄▄ ▄▄▄     ▄▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ 
//█       █   █   █  █ █  █   █   █       █  █  █ █      ██       █
//█    ▄▄▄█   █   █  █ █  █   █   █   ▄   █   █▄█ █  ▄    █  ▄▄▄▄▄█
//█   █▄▄▄█   █   █  █▄█  █   █   █  █▄█  █       █ █ █   █ █▄▄▄▄▄ 
//█    ▄▄▄█   █▄▄▄█       █   █▄▄▄█       █  ▄    █ █▄█   █▄▄▄▄▄  █
//█   █▄▄▄█       █       █       █   ▄   █ █ █   █       █▄▄▄▄▄█ █
//█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄█ █▄▄█▄█  █▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█

// ERC721A Smart Contract for the Lands of Elulands. Audited by ProtoStarter.io.

// First 5 person to send a screenshot of this smart contract code will get a T3 Pickaxe!
// #create-a-ticket on discord with your screenshot https://discord.gg/elulands

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

contract EluLands is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721BurnableUpgradeable
{
    function initialize(bytes32 _merkleRoot) public initializer {
        require(_merkleRoot != bytes32(0), "zero bytes32");

        __ERC721_init("Elulands Land", "LAND");
        __ERC721Enumerable_init();
        __ERC721Pausable_init();
        __ERC721Burnable_init();

        __Ownable_init();

        merkleRoot = _merkleRoot;
    }

    // contract uri used to display collection in the opensea
    string private _contractURI;
    // generated from list whitelist users
    bytes32 public merkleRoot;

    // store land info (metro, outpost, standard, urban, etc,...)
    mapping(uint8 => Land) private _landInfo;
    // store nft info (land type, uri, etc,...)
    mapping(uint256 => TokenInfo) private _tokenInfo;

    mapping(address => mapping(uint8 => uint256)) private _userBoughts;

    struct Land {
        uint8 typ;
        string name;
        string uri;
        uint256 price;
        uint256 quantity;
        uint256 totalSold;
        bool locked;
    }

    struct TokenInfo {
        uint8 landType;
        string uri;
    }

    event NewLand(address indexed owner, uint8 indexed typ, string name);
    event BoughtLand(address indexed buyer, address indexed token, uint8 indexed typ, uint256 amount);

    modifier onlyLandExists(uint8 typ) {
        require(_landInfo[typ].typ > 0, "land not exists");
        _;
    }

    /**
     * @notice Set Merkle Root
     *
     * @dev External function to change merkle root. Only owner can call this function.
     * @param _merkleRoot New merkle root.
     */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot != bytes32(0), "zero bytes32");

        merkleRoot = _merkleRoot;
    }

    function addNewLand(
        uint8 _landType,
        string calldata _name,
        string calldata _uri,
        uint256 _price,
        uint256 _quantity
    ) external onlyOwner {
        require(_landInfo[_landType].typ == 0, "land existed");
        require(_landType > 0, "zero type");
        require(_price > 0, "zero price");
        require(_quantity > 0, "zero quantity");

        _landInfo[_landType] = Land(_landType, _name, _uri, _price, _quantity, 0, false);

        emit NewLand(_msgSender(), _landType, _name);
    }

    function setLandInfo1(
        uint8 _landType,
        string calldata _name,
        string calldata _uri
    ) external onlyOwner onlyLandExists(_landType) {
        require(bytes(_name).length > 0, "invalid length");
        require(bytes(_uri).length > 0, "invalid length");

        Land storage land = _landInfo[_landType];
        land.name = _name;
        land.uri = _uri;
    }

    function setLandInfo2(
        uint8 _landType,
        uint256 _price,
        uint256 _quantity,
        bool _locked
    ) external onlyOwner onlyLandExists(_landType) {
        Land storage land = _landInfo[_landType];
        require(_price > 0, "zero price");
        require(_quantity > land.totalSold, "invalid quantity");

        land.price = _price;
        land.quantity = _quantity;
        land.locked = _locked;
    }

    function getLandInfo(uint8 _landType) external view onlyLandExists(_landType) returns(Land memory) {
        return _landInfo[_landType];
    }

    /**
     * @notice View Contract URI
     *
     * @dev External funciton to view contract URI.
     */

    function contractURI() external view returns(string memory) {
        return _contractURI;
    }

    /**
     * @notice Set Contract URI
     *
     * @dev Update contract uri for contract. Only owner can call this function.
     * @param _newContractURI New contract uri.
     */

    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        TokenInfo memory tokenInfo = _tokenInfo[tokenId];
        if (bytes(tokenInfo.uri).length > 0) {
            return tokenInfo.uri;
        }

        Land memory landInfo = _landInfo[tokenInfo.landType];
        return bytes(landInfo.uri).length > 0 ? landInfo.uri : "";
    }

    /**
     * @notice Set Token URI
     * 
     * @dev Specific token URI. Only owner of token can call this function
     * @param tokenId the identifier of the token
     * @param _uri the new token uri
     */
    function setTokenURI(uint256 tokenId, string calldata _uri) external {
        _requireMinted(tokenId);
        require(_msgSender() == ownerOf(tokenId), "not owner");

        TokenInfo storage tokenInfo = _tokenInfo[tokenId];
        tokenInfo.uri = _uri;
    }

    function getTokenInfo(uint256 _tokenId) external view returns(uint256 tokenId, uint8 landType, string memory uri) {
        _requireMinted(_tokenId);

        TokenInfo memory tokenInfo = _tokenInfo[_tokenId];
        return (_tokenId, tokenInfo.landType, tokenInfo.uri);
    }

    function _preMintValidate(
        uint8 _landType,
        uint256 _amount,
        uint256[] calldata _limits,
        uint256 _index,
        bytes32[] calldata _merkleProof
    ) internal view returns (uint256) {
        require(_amount > 0, "zero amount");
        require(_landType <= _limits.length, "invalid limits");

        // validate whitelist
        bytes32 node = keccak256(abi.encodePacked(_index, _msgSender(), _limits));
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node), "invalid proof");

        // check land info allow to mint
        Land memory landInfo = _landInfo[_landType];
        require(!landInfo.locked, "mint locked");
        require(landInfo.totalSold + _amount <= landInfo.quantity, "mint reached");

        uint256 _limitAmountOfTyp = _limits[_landType - 1];
        require(_userBoughts[_msgSender()][_landType] + _amount <= _limitAmountOfTyp, "buy limit");

        // check balance of minter is enough, not allow to send greater than total mint fee
        uint256 totalMintFee = _amount * landInfo.price;
        require(msg.value == totalMintFee, "insufficient balance");

        return totalMintFee;
    }

    /**
     * @notice Mint & purchase by native token
     *
     * @dev Mint new token. Only whitelist address can call this function.
     */

    function mint(
        uint8 _landType,
        uint256 _amount,
        uint256[] calldata _limits,
        uint256 _index,
        bytes32[] calldata _merkleProof
    ) external payable onlyLandExists(_landType) {
        // pre validate conditions before mint
        uint256 totalMintFee = _preMintValidate(_landType, _amount, _limits, _index, _merkleProof);

        // send total mint fee to owner
        payable(owner()).transfer(totalMintFee);

        // start mint nft
        _executeMints(_landType, _amount);
        
        // fire event
        emit BoughtLand(_msgSender(), address(0), _landType, _amount);
    }

    function _executeMints(uint8 _landType, uint256 _amount) internal {
        uint256 startTokenId = totalSupply() + 1;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = startTokenId + i;
            _safeMint(_msgSender(), _tokenId);

            _tokenInfo[_tokenId] = TokenInfo(_landType, "");
        }

        // update total sold
        Land storage landInfo = _landInfo[_landType];
        landInfo.totalSold = landInfo.totalSold + _amount;

        _userBoughts[_msgSender()][_landType] = _userBoughts[_msgSender()][_landType] + _amount;
    }

    function getUserBoughtInfo(address _address, uint8 _landType) external view returns (uint256) {
        return _userBoughts[_address][_landType];
    }

    /**
     * @notice Pause Contract
     *
     * @dev Only owner can call this function.
     */

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Un-pause Contract
     *
     * @dev Only owner can call this function.
     */

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * ===============================================================
     * OVERRIDE METHOD
     * ===============================================================
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}