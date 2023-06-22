// SPDX-License-Identifier: MIT
/**
    @author guozi
 */

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./tokens/ERC2981/ERC2981PerTokenRoyalties.sol";
import "./tokens/ERC721L.sol";

contract AlienInfinityCreatorRoyaltyImpl is Ownable, ERC721L, EIP712, ERC2981PerTokenRoyalties{
    using Strings for uint256;

    struct TimeDuration {
        uint128 reserve;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    struct MintTimeDuration {
        uint64 reserve;
        uint64 freeMintQtyPerUser;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    bool internal isInited = false;

    string private constant version = "1";
    address private _validator;
    uint256 private _maxSupply;
    string private _baseUri;
    string private _collectionURI;

    MintTimeDuration public mintTimeDuration;
    mapping(address => uint256) userFreeMintQuantity;

    bytes32 private constant LAZYMINT_TYPEHASH = keccak256("lazyMint(TimeDuration sigValidTimeDuration,address to,uint256 quantity)TimeDuration(uint128 reserve,uint64 startTimestamp,uint64 endTimestamp)");
    bytes32 private constant TimeDuration_TYPEHASH = keccak256("TimeDuration(uint128 reserve,uint64 startTimestamp,uint64 endTimestamp)");

    /**
     * @dev if maxSupply==0; means unlimited
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address validator_,
        uint256 maxBatchSize_,
        uint256 maxSupply_,
        string memory baseUri_,
        string memory collectionURI_
    ) ERC721L(name_, symbol_, maxBatchSize_) EIP712(name_, version){
        _validator = validator_;
        _maxSupply = maxSupply_;
        _baseUri = baseUri_;
        _collectionURI = collectionURI_;
        isInited = true;
    }

    function initCreator(
        string memory name_,
        string memory symbol_,
        address validator_,
        uint256 maxBatchSize_,
        uint256 maxSupply_,
        string memory baseUri_,
        string calldata collectionURI_,
        address recipient,
        uint256 royaltyAmount,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _freeMintQtyPerUser
    )  public {
        require(!isInited, "Can not reinited");
        isInited = true;

        _validator = validator_;
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        maxBatchSize = maxBatchSize_;
        _name = name_;
        _symbol = symbol_;
        _maxSupply = maxSupply_;
        _baseUri = baseUri_;
        _collectionURI = collectionURI_;


        RoyaltyInfo memory royaltyInfo_ = RoyaltyInfo(recipient, royaltyAmount);
        _setTokenRoyalty(royaltyInfo_);

        _setMintDateDuration(_startTimestamp, _endTimestamp, _freeMintQtyPerUser);
    }

    function mintQtyCheck(
        address to,
        uint256 quantity
    ) internal {
        uint256 currentUserMintedCount = userFreeMintQuantity[to]; //For gas saving
        currentUserMintedCount += quantity;
        require(
            currentUserMintedCount <= mintTimeDuration.freeMintQtyPerUser,
            "Free mint rise to max"
        );
        unchecked {
            userFreeMintQuantity[to] = currentUserMintedCount;
        }
    }

    function mintTimeCheck() public view {
        require(mintTimeDuration.startTimestamp <= uint64(block.timestamp), "startTimestamp not start!");
        require(mintTimeDuration.endTimestamp == 0  || uint64(block.timestamp) <= mintTimeDuration.endTimestamp , "endTimestamp expired!");
    }

    function lazyMint(
        address to,
        uint256 quantity,
        bytes calldata validatorSig,
        TimeDuration calldata sigValidTimeDuration
    ) external virtual {
        mintTimeCheck();
        mintQtyCheck(to, quantity);

        //Optimise: sigValidTimeDuration define within block number range
        verifySignature(to, quantity, sigValidTimeDuration, validatorSig);
        __mintTo(to, quantity);
    }

    function verifySignature(
        address _account,
        uint256 _quantity,
        TimeDuration calldata sigValidDuration,
        bytes calldata signature
    ) public view  {
        require(sigValidDuration.startTimestamp <= uint64(block.timestamp), "startTimestamp not start!");
        require(sigValidDuration.endTimestamp == 0 || uint64(block.timestamp) <= sigValidDuration.endTimestamp , "endTimestamp expired!");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(LAZYMINT_TYPEHASH,
                    keccak256(abi.encode(TimeDuration_TYPEHASH, sigValidDuration.reserve, sigValidDuration.startTimestamp, sigValidDuration.endTimestamp)),
                     _account, _quantity))
        );
        require(ECDSA.recover(digest, signature) == _validator, "Invalid Sign");
    }


    function setMintDateDuration(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _freeMintQtyPerUser) public onlyOwner {
        _setMintDateDuration(_startTimestamp, _endTimestamp, _freeMintQtyPerUser);
    }

    function _setMintDateDuration(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _freeMintQtyPerUser) internal {
        require(_startTimestamp < type(uint64).max, "_startTimestamp OverFlow");
        require(_endTimestamp < type(uint64).max, "_endTimestamp OverFlow");
        require(_freeMintQtyPerUser < type(uint64).max, "_freeMintQtyPerUser OverFlow");
        mintTimeDuration = MintTimeDuration(0, uint64(_freeMintQtyPerUser), uint64(_startTimestamp), uint64(_endTimestamp));
    }

    function getMintDateDuration() public view returns (MintTimeDuration memory){
        return mintTimeDuration;
    }

    /**
     * @dev Mints amount token to an address.
     * @param to address of the future owner of the token
     * @param amount of token to mint
     */
    function __mintTo(address to, uint256 amount) internal {
        //totalSupply() tokenIndex starts from 0
        //if maxSupply==0; means unlimited
        require(
            _maxSupply == 0 || totalSupply() + amount <= _maxSupply,
            "Mint count exceed MAX_SUPPLY!"
        );

        _safeMint(to, amount);
    }

    /**
     * @dev if maxSupply==0; means unlimited
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     */
    function getMaxBatchSize() public view returns (uint256) {
        return maxBatchSize;
    }

    /**
     * @dev Override _collectionBaseURI, for collectionURI return collection Level URI
     */
    function _collectionBaseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _collectionURI;
    }

    function setCollectionURI(
        string calldata newCollectionURI
    ) public virtual onlyOwner {
        _collectionURI = newCollectionURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        _baseUri = newBaseUri;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function getValidator() external view returns (address) {
        return _validator;
    }

    function setValidator(address newValidator) external onlyOwner {
        require(
            newValidator != address(0) && _validator != newValidator,
            "invalid newValidator address!"
        );
        _validator = newValidator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Alien, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}