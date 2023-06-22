//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/INOwnerResolver.sol";
import "./interfaces/IN.sol";
import "./ERC2981ContractWideRoyalties.sol";

/**
 * @title Holey People
 * @author zhark; Art by Daniel Leighton
 */

contract HoleyPeople is ERC721Enumerable, ReentrancyGuard, AccessControl, ERC2981ContractWideRoyalties {
    uint256 private _tokenId;
    bytes32 public root;
    address private _owner;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    bool public nHolderSaleActive;
    bool public presaleListSaleActive;
    bool public publicSaleActive;
    bool public isSalePaused;

    uint256 public constant MAX_SUPPLY = 8888;

    uint256 public tempSaleLimit = 1111;

    uint256 public nHolderMintLimit = 2;
    uint256 public presaleListMintLimit = 5;
    uint256 public publicMintLimit = 10;

    uint256 public nHolderPrice = 0.03499 ether;
    uint256 public presaleListPrice = 0.03999 ether;
    uint256 public publicPrice = 0.06999 ether;

    IN public immutable n;
    INOwnerResolver public immutable nOwnerResolver;

    constructor(
        address _nContractAddress,
        address nOwnersRegistry,
        bytes32 merkleroot
    ) ERC721("Holey People", "HOLEY") {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, 0xB7D2EFED6D2B0F080e3B96D10f6259B8A958E88e);
        _setupRole(ADMIN_ROLE, 0x84b30ec1EE3e8905279C7aDF1e944BCA3dE3603B); 
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _owner = msg.sender;
        baseTokenURI = "";
        metadataExtension = ".json";
        n = IN(_nContractAddress);
        nOwnerResolver = INOwnerResolver(nOwnersRegistry);
        root = merkleroot;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "HoleyPeople:ACCESS_DENIED");
        _;
    }

    /** Royalties **/
     function setRoyalties(address recipient, uint256 value) public onlyAdmin {
        _setRoyalties(recipient, value);
    }

    /** OpenSea Owner Hack */

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) public onlyAdmin {
        _owner = newOwner;
    }

    /** Dev Functions **/

    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        root = _merkleRoot;
    }

    function devMint(address addr, uint256 amount) public onlyAdmin {
        require(_tokenId + amount <= MAX_SUPPLY, "HoleyPeople:MAX_SUPPLY_REACHED");
        for (uint256 i = 0; i < amount; i++) {
            _tokenId++;
            _safeMint(addr, _tokenId);
        }
    }

    /** Set States **/

    // Sale States

    function setnHolderSaleState(bool _nHolderSaleState) public onlyAdmin {
        nHolderSaleActive = _nHolderSaleState;
    }

    function setpresaleListSaleState(bool presaleListSaleState) public onlyAdmin {
        presaleListSaleActive = presaleListSaleState;
    }

    function setPublicSaleState(bool _publicSaleActiveState) public onlyAdmin {
        publicSaleActive = _publicSaleActiveState;
    }

    function setSalePausedState(bool _salePausedState) public onlyAdmin {
        isSalePaused = _salePausedState;
    }

    // Sale Price

    function setnHolderSalePrice(uint256 _nHolderSalePrice) public onlyAdmin {
        nHolderPrice = _nHolderSalePrice;
    }

    function setpresaleListSalePrice(uint256 presaleSalePrice) public onlyAdmin {
        presaleListPrice = presaleSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) public onlyAdmin {
        publicPrice = _publicSalePrice;
    }

    // Mint Limits

    function setnHolderMintLimit(uint256 _nHolderMintLimit) public onlyAdmin {
        nHolderMintLimit = _nHolderMintLimit;
    }

    function setpresaleListMintLimit(uint256 _presaleMintLimit) public onlyAdmin {
        presaleListMintLimit = _presaleMintLimit;
    }
    
    function setPublicMintLimit(uint256 _publicMintLimit) public onlyAdmin {
        publicMintLimit = _publicMintLimit;
    }

    // Sale Limits

    function setTempSaleLimit(uint256 _tempSaleLimit) public onlyAdmin {
        tempSaleLimit = _tempSaleLimit;
    }

    /** Internal **/

    function _ispresaleListSaleActive() internal view returns (bool) {
        return presaleListSaleActive && !isSalePaused;
    }

    function _isnHolderSaleActive() internal view returns (bool) {
        return nHolderSaleActive && !isSalePaused;
    }

    function _isPublicSaleActive() internal view returns (bool) {
        return publicSaleActive && !isSalePaused;
    }

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view returns (uint256) {
        return tempSaleLimit - _tokenId;
    }

    /** MINTING **/
    
    function mint(uint8 amount) public payable virtual nonReentrant {
        bool canNMint = (_isPublicSaleActive() || (_isnHolderSaleActive() && nOwnerResolver.balanceOf(msg.sender) > 0));
        uint256 price = _isPublicSaleActive() ? publicPrice : nHolderPrice;
        uint256 mintLimit = _isPublicSaleActive() ? publicMintLimit: nHolderMintLimit;
        require((_isPublicSaleActive() || _isnHolderSaleActive()), "HoleyPeople:USER_NOT_ALLOWED_TO_MINT");
        require(canNMint, "HoleyPeople:USER_DOES_NOT_OWN_N");
        require(amount <= totalMintsAvailable(), "HoleyPeople:MAX_ALLOCATION_REACHED");
        require(balanceOf(msg.sender) + amount <= mintLimit, "HoleyPeople:MINT_ABOVE_MAX_MINT_ALLOWANCE");

        require(msg.value == price * amount, "NPass:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }
    }

    function mintpresaleList(bytes32[] calldata proof, uint8 amount)
    external payable nonReentrant
    {
        require(balanceOf(msg.sender) + amount <= presaleListMintLimit,"HoleyPeople:MINT_ABOVE_MAX_MINT_ALLOWANCE");
        require(_ispresaleListSaleActive(), "HoleyPeople:USER_NOT_ALLOWED_TO_MINT");
        require(amount <= totalMintsAvailable(), "HoleyPeople:MAX_ALLOCATION_REACHED");
        require(_verify(_leaf(msg.sender), proof), "HoleyPeople:Invalid merkle proof");
        require(msg.value == presaleListPrice * amount, "HoleyPeople:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    public view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    /** URI HANDLING **/

    string public baseTokenURI;
    string public metadataExtension;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId), metadataExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURIAndExtension(string calldata baseTokenUri_, string calldata metadataExtension_)
        external
        onlyAdmin
    {
        baseTokenURI = baseTokenUri_;
        metadataExtension = metadataExtension_;
    }

    /** PAYOUT **/

    address private constant devAddress = 0xB6fE450D565F99066D44692Ede257cD179a0C846;
    address private constant artistAddress1 = 0xFe5F90756BF715B55774E18EC4EE26424e56c3B9;
    address private constant artistAddress2 = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    uint256 private devfee = 0 ether;

    function withdraw() public onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;

        if (devfee >= 2 ether) {
            payable(artistAddress1).transfer(address(this).balance * 875 / 1000);
            payable(artistAddress2).transfer(address(this).balance);
        } else if(devfee + balance/2 > 2 ether) { 
            payable(devAddress).transfer(2 ether - devfee); 
            devfee = 2 ether;
            payable(artistAddress1).transfer(address(this).balance * 875 / 1000);
            payable(artistAddress2).transfer(address(this).balance);
        } else {
            payable(devAddress).transfer(balance/2);
            devfee = devfee + balance/2;
            payable(artistAddress1).transfer(address(this).balance * 875 / 1000);
            payable(artistAddress2).transfer(address(this).balance);
        }
    }

    bool private devLock = false;

    function unlock(bool _lockState) public {
        require(msg.sender == 0xB6fE450D565F99066D44692Ede257cD179a0C846, "HoleyPeople:NOT_DEV");
        devLock = _lockState;
    }

    function altWithdraw() public onlyAdmin {
        require(devLock, "HoleyPeople: locked");
        payable(artistAddress1).transfer(address(this).balance * 875 / 1000);
        payable(artistAddress2).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}