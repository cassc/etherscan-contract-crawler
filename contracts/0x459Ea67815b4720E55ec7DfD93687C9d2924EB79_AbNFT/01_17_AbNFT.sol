// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]io
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Local
import { Configurable } from "./utils/Configurable.sol";
import { IAbNFT } from "./interfaces/IAbNFT.sol";

/**************************************

    AB NFT token

 **************************************/

contract AbNFT is IAbNFT, IERC2981, ERC721Enumerable, Ownable, Configurable {

    // libs
    using Strings for uint256;

    // structs
    struct RangedURI {
        uint256 range;
        string uri;
    }

    // constants
    uint256 public TRANSFER_FEE = 420; // divided by 10.000

    // contracts
    address public minterAddress;

    // storage
    string public blindURI;
    RangedURI[] public uris;
    uint256 public toVest;

    // events
    event Minted(uint256[] nftIds, address owner);
    event Revealed(RangedURI uri);
    event Vested(address owner, uint256 amount);

    // errors
    error MinterAddressNotSet();
    error NotMinter(address senderAddress);
    error BlindURINotSet();
    error NftAlreadyMinted(uint256 tokenId);
    error NftDoesNotExist(uint256 tokenId);
    error VestNotPossible(uint256 amount, uint256 available);
    error TooLowRange(uint256 range, uint256 existing);

    // modifiers
    modifier onlyMinter() {

        // check sender
        if (msg.sender != minterAddress) {
            revert NotMinter(msg.sender);
        }
        _;

    }

    /**************************************

        Constructor

     **************************************/

    constructor()
    ERC721("AngelBlock NFTs", "AB")
    Ownable() {}

    /**************************************

        Set minter address

     **************************************/

    function setMinterAddress(address _minterAddress) external
    onlyInState(State.UNCONFIGURED)
    onlyOwner {

        // storage
        minterAddress = _minterAddress;

    }

    /**************************************

        Set blind URI

     **************************************/

    function setBlindURI(string memory _blindURI) external
    onlyInState(State.UNCONFIGURED)
    onlyOwner {

        // storage
        blindURI = _blindURI;

    }

    /**************************************

        Set as configured

     **************************************/

    function setConfigured() public override
    onlyInState(State.UNCONFIGURED) {

        // check minter
        if (minterAddress == address(0)) {
            revert MinterAddressNotSet();
        }

        // check blindURI
        if (keccak256(bytes(blindURI)) == keccak256(bytes(""))) {
            revert BlindURINotSet();
        }

        // super
        super.setConfigured();

    }

    /**************************************

        Internal: override ERC721

     **************************************/

    function _baseURI() internal view virtual override
    onlyInState(State.CONFIGURED)
    returns (string memory) {

        // return
        return blindURI;

    }

    /**************************************

        Internal: Convert token to uri

     **************************************/

    function _tokenIdToUriId(uint256 _tokenId) internal view
    returns (int256) {

        // length
        uint256 length_ = uris.length;

        // loop
        for (uint256 i = 0; i < length_; i++) {

            // get uri
            RangedURI memory uri_ = uris[i];

            // check if token is within range
            if (uri_.range > _tokenId) {

                // return uri id
                return int256(i);

            }

        }

        // return not found
        return -1;

    }

    /**************************************

        Get token URI

     **************************************/

    function tokenURI(uint256 _tokenId) public view virtual override
    onlyInState(State.CONFIGURED)
    returns (string memory) {

        // check if token exists
        if (!_exists(_tokenId)) {
            revert NftDoesNotExist(_tokenId);
        }

        // token to uri id
        int256 uriId_ = _tokenIdToUriId(_tokenId);

        // check if revealed else return blind
        if (uriId_ < 0) return _baseURI();

        // get revealed uri
        string memory uri_ = uris[uint256(uriId_)].uri;

        // return revealed uri
        return string(abi.encodePacked(uri_, _tokenId.toString()));

    }

    /**************************************

        Mint from Minter

     **************************************/

    function mint(uint256[] calldata _nftIds, address _owner) external override
    onlyInState(State.CONFIGURED)
    onlyMinter {

        // mint
        __mint(_nftIds, _owner);

    }

    /**************************************

        Vested claim from Minter

     **************************************/

    function vestedClaim(uint256[] calldata _nftIds, address _vesting) external
    onlyInState(State.CONFIGURED)
    onlyMinter {

        // amount to vest
        uint256 amount_ = _nftIds.length;

        // check if vest is possible
        if (toVest < amount_) {
            revert VestNotPossible(amount_, toVest);
        }

        // decrement available to vest
        toVest -= amount_;

        // vested claim
        __mint(_nftIds, _vesting);

        // event
        emit Vested(_vesting, amount_);

    }

    /**************************************

        Internal: mint

     **************************************/

    function __mint(uint256[] calldata _nftIds, address _owner) internal {

        // length
        uint256 length_ = _nftIds.length;

        // loop through ids
        for (uint256 i = 0; i < length_; i++) {

            // check if nft exists already
            if (_exists(_nftIds[i])) {
                revert NftAlreadyMinted(_nftIds[i]);
            }

            // mint
            _safeMint(_owner, _nftIds[i]);

        }

        // event
        emit Minted(_nftIds, _owner);

    }

    /**************************************

        Reveal from Minter

     **************************************/

    function reveal(
        uint256 _range,
        string memory _revealedURI,
        uint256 _toVest
    ) external
    onlyInState(State.CONFIGURED)
    onlyMinter {

        // get uri
        RangedURI memory rangedURI_ = RangedURI(
            _range,
            _revealedURI
        );

        // check range
        if (uris.length > 0 && uris[uris.length - 1].range >= rangedURI_.range) {
            revert TooLowRange(
                rangedURI_.range,
                uris[uris.length - 1].range
            );
        }

        // storage
        if (_toVest > 0) toVest += _toVest;
        uris.push(rangedURI_);

        // event
        emit Revealed(rangedURI_);

    }

    /**************************************

        Royalties - ERC2981

     **************************************/

    function royaltyInfo(uint256, uint256 value) external view override
    returns (address, uint256) {

        // return owner fee 4.20% of transaction
        return (owner(), value * TRANSFER_FEE / 10000);

    }

    /**************************************

        Supports interface

    **************************************/

    function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721Enumerable, IERC165)
    returns (bool) {
        return
            interfaceId == type(IAbNFT).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}