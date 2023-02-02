// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./abstract/CustomErrors.sol";
import "./interfaces/ICybaspaceGenesisCollection.sol";

contract CybaspaceGenesisCollection is
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Ownable,
    CustomErrors,
    ICybaspaceGenesisCollection
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public tokenPrice;

    uint256 public maxSupplyPerAddress;
    uint256 public maxSupply;
    uint256 public currentSupply;

    bool public metadataFrozen;
    bool public mintingFrozen;
    string public baseImageURI;
    string public description;

    uint256 public supplyForInvestors;
    bool public investorPhase;


    mapping(address => uint8) public mintedByAddress;

    modifier checkAddress(address _address) {
        if (_address == address(0)) revert AddressZero();
        _;
    }

    modifier whenMintingIsNotFrozen() {
        if (mintingFrozen) revert MintingIsFrozen();
        _;
    }

    modifier checkPrice(uint256 price) {
        if (price < tokenPrice) revert PriceTooLow();
        _;
    }

    /**
     * @param _name Name of the NFT Collection
     * @param _symbol Symbol of the NFT Collection
     * @param _tokenPrice Price for one Token
     * @param _maxSupply Maximum supply of Token in Collection
     * @param _maxSupplyPerAddress Maximum amount of Token per Address
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenPrice,
        uint256 _maxSupply,
        uint256 _maxSupplyPerAddress,
        uint256 _supplyForInvestors
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tokenPrice = _tokenPrice;
        maxSupply = _maxSupply;
        maxSupplyPerAddress = _maxSupplyPerAddress;
        supplyForInvestors = _supplyForInvestors;
        investorPhase = false;
    }

    /**
     * @notice Callable only by `MINTER_ROLE`
     * @dev Mints a token to the given `_to` address
     *
     * @param _to Wallet address which will receive the token
     * @param _price amount payed
     */
    function mint(
        address _to,
        uint _price
    ) external onlyRole(MINTER_ROLE) whenMintingIsNotFrozen checkPrice(_price) {

        if (investorPhase) {
            if (currentSupply + 1 > supplyForInvestors) revert MaxSupplyReached();
        }

        if (currentSupply + 1 > maxSupply) revert MaxSupplyReached();

        // allow only maxSupplyPerAddress mints per address
        if (mintedByAddress[_to] >= maxSupplyPerAddress)
            revert MaxSupplyReachedForAddress();

        ++mintedByAddress[_to];
        _mint(_to, ++currentSupply);


    }

    /***
     * @notice Returns metadata for a specific token
     * @param _tokenId - Id of the token
     * @return - Metadata for a requested _tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(_tokenId) == address(0)) revert TokenDoesNotExist();

        string memory metadata = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name(),
                        " #",
                        Strings.toString(_tokenId),
                        '", "description": "',
                        description,
                        '", "image": "',
                        baseImageURI,
                        '", ',
                        '"attributes": [{"trait_type": "Edition","value": "Founders Edition"}]',
                        "}"
                    )
                )
            )
        );

        return
            string(abi.encodePacked("data:application/json;base64,", metadata));
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Grants `MINTER_ROLE` to the specified address
     *
     * @param _minter Address which will be granted the `MINTER_ROLE`
     */
    function grantMinterRole(
        address _minter
    ) external onlyOwner checkAddress(_minter) {
        _grantRole(MINTER_ROLE, _minter);
    }

    /**
     * @dev Freezes metadata so it's no longer possible to alter it
     */
    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @dev Freezes minting so it's no longer possible
     * MintingIsFrozen
     *
     * @param _switch switch to turn off/on minting phase
     */
    function disableMinting(bool _switch) external onlyOwner {
        mintingFrozen = _switch;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets maxSupply to equal the specified value
     *
     * @param _maxSupply New maxSupply value
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < currentSupply) revert CurrentSupplyExceedsMaxSupply();
        maxSupply = _maxSupply;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets TokenPrice to equal the specified value
     *
     * @param _tokenPrice New TokenPrice value
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Sets the baseImageURI
     * 
     * @param _baseImageURI base uri of image to set
     */
    function setBaseImageURI(
        string memory _baseImageURI
    ) external onlyOwner {
        if (metadataFrozen) revert MetadataIsFrozen();

        baseImageURI = _baseImageURI;
    }

    /**
     * @dev Sets the description
     * 
     * @param _description description to set
     */
    function setDescription(string memory _description) external onlyOwner {
        if (metadataFrozen) revert MetadataIsFrozen();

        description = _description;
    }

    /**
     * @dev mint phase
     *
     * @param _switch switch to turn off/on minting phase
     */
    function setPhase(bool _switch) external onlyOwner {

        investorPhase = _switch;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}