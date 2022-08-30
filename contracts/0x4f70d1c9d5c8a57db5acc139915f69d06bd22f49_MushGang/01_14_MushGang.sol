// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";
import "./extensions/ERC721ABurnable.sol";

/**
███████████████████████████████████████████████████████████████
███████████████████▀▀▀▀▀▀▀▀░░░░░░░░░░░░▀▀▀▀▀▀▀█████████████████
████████████████▀▀▀▀░░░░░░░░░░░░░░░░░░░░░░░░▀▀▀▀▀▀█████████████
██████████████▀▀▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀▀▀▀█████████████
██████████▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀▀█████████
███████▀░░░░▄▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀███████
█████▀░░░▄█▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀█████
███▀░░░▄██▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
██░░░░▄██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
██░░░░▄██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
█░░░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
█░░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
█░░░▀▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄██████
█▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄▄▄█████████
███████▄▄▄▄▄▄██████████████████████████████████████████████████
████████████████▀▀▀▀▀▀░░░░░░░░░░░░░░░░░░░▀█████████████████████
████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░█████████████████████
████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░█████████████████████
████████████████░░░░░░░░░░░░░░░░░░░░░░░░░█░████████████████████
███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░█░░███████████████████
███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░█░███████████████████
██████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░███████████████████
█████████████▀░░░░░░░░░░░░░░░░░░░░░░░░░░░█░▄███████████████████
████████████▀░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░████████████████████
███████████████████████████████████████████████████████████████
 **/


contract MushGang is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 6556;
    uint256 public constant MINT_PRICE = 0.0069 ether;
    uint8 public  maxByWalletPerPublic = 3;
    uint8 public  maxByWalletPerMushSale = 1;

    enum Stage {
        SaleClosed,
        MushVIP,
        MushList,
        Public
    }

    Stage public saleState = Stage.SaleClosed;

    string public baseTokenURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    bool public revealed = false;

    mapping(address => uint8) private _vipList;
    bytes32 private _mushListMerkleRoot;

    constructor() ERC721A("MushGang", "MUSH") {}

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function mint(uint8 _amountOfMush, bytes32[] memory _proof) public payable mintIsOpen nonContract nonReentrant{
        require(totalSupply() + _amountOfMush <= MAX_SUPPLY, "Reached Max Supply");
        require(MINT_PRICE * _amountOfMush <= msg.value, "Ether value sent is not correct");
        if (saleState == Stage.MushList) {
            require(_mushListMerkleRoot != "", "Mush Claim merkle tree not set. This address is not allowed to mint");
            require(MerkleProof.verify(_proof, _mushListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))),
                "MushList claim validation failed.");
            _mushListMint(_amountOfMush);
        }
        if (saleState == Stage.Public) {
            _publicMint(_amountOfMush);
        }
    }

    function _publicMint(uint8 _amountOfMush) internal mintIsOpen {
        require(saleState == Stage.Public, "Public mint is not open yet!");
        require(getRedemptionsPublic() + _amountOfMush <= maxByWalletPerPublic, "Exceeded max available to purchase");
        incrementRedemptionsPublic(_amountOfMush);
        _safeMint(msg.sender, _amountOfMush);
    }

    function _mushListMint(uint8 _amountOfMush) internal mintIsOpen {
        require(saleState == Stage.MushList, "MushList mint is not open yet!");
        require(getRedemptionsMushList() + _amountOfMush <= maxByWalletPerMushSale, "Exceeded max available to purchase");
        incrementRedemptionsMushList(_amountOfMush);
        _safeMint(msg.sender, _amountOfMush);
    }

    function mintVIP(uint8 _amountOfMush) public mintIsOpen nonReentrant{
        require(saleState == Stage.MushVIP, "Vip mint is not open yet!");
        require(_vipList[msg.sender] != 0, "Vip claim  failed. This address is not allowed to mint");
        require(getRedemptionsVipList() + _amountOfMush <= _vipList[msg.sender], "Exceeded max available to purchase");
        incrementRedemptionsVipList(_amountOfMush);

        _safeMint(msg.sender, _amountOfMush);
    }

    ////////////////////
    // OWNER FUNCTIONS //
    ////////////////////

    function setMaxByWalletPerPublic(uint8 newMaxByWallet) external onlyOwner {
        maxByWalletPerPublic = newMaxByWallet;
    }

    function setMaxByWalletPerMushSale(uint8 newMaxByWallet) external onlyOwner {
        maxByWalletPerMushSale = newMaxByWallet;
    }

    function setMaxVipListRedemptions(
        address[] calldata _addresses,
        uint8  _redemptions
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _vipList[_addresses[i]] = _redemptions;
        }
    }

    function setMushListMerkleRoot(bytes32 newMerkleRoot_) external onlyOwner {
        _mushListMerkleRoot = newMerkleRoot_;
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

    function reserveMint(address to, uint8 _amountOfMush) public onlyOwner nonReentrant mintIsOpen{
        require(totalSupply() + _amountOfMush <= MAX_SUPPLY, "Reached Max Supply");
        _safeMint(to, _amountOfMush);
    }

    function withdraw() public onlyOwner nonReentrant {
        require(saleState != Stage.SaleClosed, "Sorry, but not now");
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
        (uint8 vipListMintRedemptions,uint8 mushListMintRedemptions, uint8 publicListMintRedemptions) = unpackMintRedemptions(
            _getAux(checkedAddress)
        );
        if(saleState==Stage.MushVIP)
            return _vipList[checkedAddress] - vipListMintRedemptions;
        if(saleState==Stage.MushList)
            return maxByWalletPerMushSale - mushListMintRedemptions;
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
     * (vip, public and mushlist redemptions) we need to pack and unpack three uint8s into a single uint24.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsVipList() private view returns (uint8) {
        (uint8 vipListMintRedemptions,,) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return vipListMintRedemptions;
    }

    /**
     * @notice Unpack and get number of mushlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, public and mushlist redemptions) we need to pack and unpack three uint8s into a single uint24.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsMushList() private view returns (uint8) {
        (,uint8 mushListMintRedemptions,) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return mushListMintRedemptions;
    }


    /**
     * @notice Unpack and get number of mushlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, public and mushlist redemptions) we need to pack and unpack three uint8s into a single uint24.
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
        uint8 _mushListMintRedemptions,
        uint8 _publicMintRedemptions
    ) private pure returns (uint24) {
        return
        (uint24(_vipMintRedemptions) << 8) |
        (uint24(_mushListMintRedemptions) << 16) | uint24(_publicMintRedemptions);
    }

    /**
     * @notice Unpack a single uint24 value into thr uint8s (vip, mushList and public redemptions)
     * @return vipMintRedemptions mushListMintRedemptions publicMintRedemptions Unpacked values
     * @dev Performs shift and bit operations to unpack a single uint64 into two uint32s
     */
    function unpackMintRedemptions(uint64 _mintRedemptionPack)
    private
    pure
    returns (uint8 vipMintRedemptions, uint8 mushListMintRedemptions, uint8 publicMintRedemptions)
    {
        vipMintRedemptions = uint8(_mintRedemptionPack >> 8);
        mushListMintRedemptions = uint8(_mintRedemptionPack >> 16);
        publicMintRedemptions = uint8(_mintRedemptionPack);
    }

    /**
    * @notice Increment number of viplist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, mushlist and public) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsVipList(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 mushListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        vipListMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, mushListMintRedemptions, publicMintRedemptions)
        );
    }

    /**
    * @notice Increment number of mushlist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, mushlist and public redemptions) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsMushList(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 mushListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        mushListMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, mushListMintRedemptions, publicMintRedemptions)
        );
    }

    /**
     * @notice Increment number of public token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint8, which will not be an issue as
     * mint quantity should never be greater than 2^8 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (vip, mushlist and public) we need to pack and unpack two uint8s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsPublic(uint8 _numToIncrement) private {
        (
        uint8 vipListMintRedemptions,
        uint8 mushListMintRedemptions,
        uint8 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        publicMintRedemptions += uint8(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(vipListMintRedemptions, mushListMintRedemptions, publicMintRedemptions)
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