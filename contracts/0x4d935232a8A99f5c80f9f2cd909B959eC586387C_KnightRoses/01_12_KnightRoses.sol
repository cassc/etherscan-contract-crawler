// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";

contract KnightRoses is ERC721A,  ERC721AQueryable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 5005;
    uint256 public constant MAX_SALE_SUPPLY = 4800;
    uint256 public constant MINT_PRICE = 0.03 ether;
    uint8 public  maxByWalletPerPublic = 5;
    uint8 public  maxByWalletPerKnightSale = 1;

    enum Stage {
        SaleClosed,
        KnightVIP,
        KnightList,
        Public
    }

    Stage public saleState = Stage.SaleClosed;

    string public baseTokenURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    bool public revealed = false;

    mapping(address => uint8) private _vipList;
    bytes32 private _knightListMerkleRoot;

    constructor() ERC721A("Knight&Roses", "Knights") {}

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function mint(uint8 _amountOfKnight, bytes32[] memory _proof) public payable mintIsOpen nonContract nonReentrant{
        require(totalSupply() + _amountOfKnight <= MAX_SALE_SUPPLY, "Reached Max Supply");
        require(MINT_PRICE * _amountOfKnight <= msg.value, "Ether value sent is not correct");
        if (saleState == Stage.KnightList) {
            require(_knightListMerkleRoot != "", "Knight Claim merkle tree not set. This address is not allowed to mint");
            require(MerkleProof.verify(_proof, _knightListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))),
                "KnightList claim validation failed.");
            _knightListMint(_amountOfKnight);
        }
        if (saleState == Stage.Public) {
            _publicMint(_amountOfKnight);
        }
        if (saleState == Stage.KnightVIP) {
            revert("I'm sorry you're out of time");
        }
    }

    function _publicMint(uint8 _amountOfKnight) internal mintIsOpen {
        require(saleState == Stage.Public, "Public mint is not open yet!");
        require(getRedemptionsPublic() + _amountOfKnight <= maxByWalletPerPublic, "Exceeded max available to purchase");
        incrementRedemptionsPublic(_amountOfKnight);
        _safeMint(msg.sender, _amountOfKnight);
    }

    function _knightListMint(uint8 _amountOfKnight) internal mintIsOpen {
        require(saleState == Stage.KnightList, "KnightList mint is not open yet!");
        require(getRedemptionsKnightList() + _amountOfKnight <= maxByWalletPerKnightSale, "Exceeded max available to purchase");
        incrementRedemptionsKnightList(_amountOfKnight);
        _safeMint(msg.sender, _amountOfKnight);
    }

    function mintVIP(uint8 _amountOfKnight) public mintIsOpen nonReentrant{
        require(saleState == Stage.KnightVIP, "Vip mint is not open yet!");
        require(_vipList[msg.sender] != 0, "Vip claim  failed. This address is not allowed to mint");
        require(getRedemptionsVipList() + _amountOfKnight <= _vipList[msg.sender], "Exceeded max available to purchase");
        incrementRedemptionsVipList(_amountOfKnight);

        _safeMint(msg.sender, _amountOfKnight);
    }

    ////////////////////
    // OWNER FUNCTIONS //
    ////////////////////

    function setMaxByWalletPerPublic(uint8 newMaxByWallet) external onlyOwner {
        maxByWalletPerPublic = newMaxByWallet;
    }

    function setMaxByWalletPerKnightSale(uint8 newMaxByWallet) external onlyOwner {
        maxByWalletPerKnightSale = newMaxByWallet;
    }

    function setMaxVipListRedemptions(
        address[] calldata _addresses,
        uint8  _redemptions
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _vipList[_addresses[i]] = _redemptions;
        }
    }

    function setKnightListMerkleRoot(bytes32 newMerkleRoot_) external onlyOwner {
        _knightListMerkleRoot = newMerkleRoot_;
    }

    function setStage(Stage _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function setReveal(bool _setReveal) public onlyOwner {
        revealed = _setReveal;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reserveMint(address to, uint8 _amountOfKnight) public onlyOwner nonReentrant mintIsOpen{
        require(totalSupply() + _amountOfKnight <= MAX_SUPPLY, "Reached Max Supply");
        _safeMint(to, _amountOfKnight);
    }

    function airdrop(
        address[] calldata _addresses,
        uint8  _amountOfKnight
    ) external onlyOwner nonReentrant mintIsOpen {
        require(totalSupply() + _amountOfKnight * _addresses.length  <= MAX_SUPPLY, "Reached Max Supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _amountOfKnight);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        require(saleState == Stage.SaleClosed, "Sorry, but not now");
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }


    ////////////////////
    // OVERRIDES //
    ////////////////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721A, IERC721A)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        if(revealed == false) {
            currentBaseURI = notRevealedUri;
        }

        return
        bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /********************  READ ********************/

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function toString(uint256 x) public pure returns (string memory) {
        return _toString(x);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function getAvailableForMintByCurrentStage(address checkedAddress) public view returns (uint8) {
        (uint8 vipListMintRedemptions,uint8 knightListMintRedemptions, uint8 publicListMintRedemptions) = unpackMintRedemptions(
            _getAux(checkedAddress)
        );
        if(saleState==Stage.KnightVIP)
            return _vipList[checkedAddress] - vipListMintRedemptions;
        if(saleState==Stage.KnightList)
            return maxByWalletPerKnightSale - knightListMintRedemptions;
        if(saleState==Stage.Public)
            return maxByWalletPerPublic - publicListMintRedemptions;
        return 0;
    }

    function checkVipList(address checkedAddress) public view returns (address, uint8) {
        return (checkedAddress, _vipList[checkedAddress]);
    }


    /********************  MODIFIERS ********************/

    modifier mintIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Soldout!");
        require(
            saleState != Stage.SaleClosed,
            "Mint is not open yet!"
        );
        _;
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "No, no, no. ! It is forbidden!");
        _;
    }

    //////////////////////
    // GETTER FUNCTIONS //
    //////////////////////

    /**
     * @notice Unpack and get number of viplist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, public and knightlist redemptions) we need to pack and unpack three uint8s into a single uint24.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsVipList() private view returns (uint8) {
        (uint8 vipListMintRedemptions,,) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return vipListMintRedemptions;
    }

    /**
     * @notice Unpack and get number of knightlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, public and knightlist redemptions) we need to pack and unpack three uint8s into a single uint24.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsKnightList() private view returns (uint8) {
        (,uint8 knightListMintRedemptions,) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return knightListMintRedemptions;
    }


    /**
     * @notice Unpack and get number of knightlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, public and knightlist redemptions) we need to pack and unpack three uint8s into a single uint24.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsPublic() private view returns (uint8) {
        (,,uint8 publicMintRedemptions) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return publicMintRedemptions;
    }

    //////////////////////
    // HELPER FUNCTIONS //
    //////////////////////
    /**
     * @notice Pack three uint8s (viplist, allowlist and public redemptions) into a single uint24 value
     * @return Packed value
     * @dev Performs shift and bit operations to pack two uint8s into a single uint24
     */
    function packMintRedemptions(
        uint8 _vipMintRedemptions,
        uint8 _knightListMintRedemptions,
        uint8 _publicMintRedemptions
    ) private pure returns (uint24) {
        return
        (uint24(_vipMintRedemptions) << 8) |
        (uint24(_knightListMintRedemptions) << 16) | uint24(_publicMintRedemptions);
    }

    /**
     * @notice Unpack a single uint24 value into thr uint8s (vip, knightList and public redemptions)
     * @return vipMintRedemptions knightListMintRedemptions publicMintRedemptions Unpacked values
     * @dev Performs shift and bit operations to unpack a single uint64 into two uint32s
     */
    function unpackMintRedemptions(uint64 _mintRedemptionPack)
    private
    pure
    returns (uint8 vipMintRedemptions, uint8 knightListMintRedemptions, uint8 publicMintRedemptions)
    {
        vipMintRedemptions = uint8(_mintRedemptionPack >> 8);
        knightListMintRedemptions = uint8(_mintRedemptionPack >> 16);
        publicMintRedemptions = uint8(_mintRedemptionPack);
    }

    /**
    * @notice Increment number of viplist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, knightlist and public) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsVipList(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 knightListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        vipListMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, knightListMintRedemptions, publicMintRedemptions)
        );
    }

    /**
    * @notice Increment number of knightlist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, knightlist and public redemptions) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsKnightList(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 knightListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        knightListMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, knightListMintRedemptions, publicMintRedemptions)
        );
    }

    /**
     * @notice Increment number of public token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, knightlist and public) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsPublic(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 knightListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        publicMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, knightListMintRedemptions, publicMintRedemptions)
        );
    }

    /**
   * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        revert NotImplemented();
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        revert NotImplemented();
    }

}

/**
 * Function not implemented
 */
    error NotImplemented();