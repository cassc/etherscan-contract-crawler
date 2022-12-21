//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????:
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B [email protected]@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7
//    [email protected]@@@@#                                                                [email protected]@@@@@ [email protected]@@@@G
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//         [email protected]@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&[email protected]@@@@@!
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^

//  _____________________________________________________ Tomb Series  _____________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^
//     ~&@@@@@@@@@@#7.                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5
//    ^@@@@@@[email protected]@@@@@@B!              [email protected]@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG!
//    [email protected]@@@@5  .7#@@@@@@@P^           [email protected]@@@@P                                [email protected]@@@@@.         .J&@@@@@@&5:
//    [email protected]@@@@Y     .J&@@@@@@&5:        [email protected]@@@@G                                 @@@@@@.            :Y&@@@@@@&J.
//    [email protected]@@@@5        :5&@@@@@@&J.     [email protected]@@@@G                                 @@@@@@.               ^[email protected]@@@@@@#7.
//    [email protected]@@@@5           ^[email protected]@@@@@@#7.  [email protected]@@@@G                                 @@@@@@.                  [email protected]@@@@@@B!
//    [email protected]@@@@5              [email protected]@@@@@@[email protected]@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~
//    [email protected]@@@@5                .7#@@@@@@@@@@&! [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^

//  __________________________________________________ Tomb Index Marker ___________________________________________________

//  _______________________________________________ Deployed by TERRAIN 2022 _______________________________________________

//  ___________________________________________ All tombs drawn by David Rudnick ___________________________________________

//  ___________________________________ Contract architects: James Geary and Luke Miles ____________________________________

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";
import "zora-drops-contracts/src/interfaces/IOperatorFilterRegistry.sol";
import "./utils/IERC173.sol";

contract IndexMarkerV2 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    ERC721VotesUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    uint96 internal constant DEFAULT_ROYALTY_BPS = 1_000; // 10%
    uint16 internal constant MAX_SUPPLY = 3_000;

    address payable public constant TOMB_ARTIST = payable(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
    IOperatorFilterRegistry public immutable operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    address public marketFilterDAOAddress;

    ERC721Upgradeable public indexContract;
    IERC721Upgradeable public indexMarkerV1;
    address public tokenClaimSigner;
    uint256 public mintExpiry;
    bool public isMintAllowed;
    mapping(bytes32 => uint256) public premintTimes;
    mapping(address => bool) public isTombContract;
    mapping(address => mapping(uint256 => bool)) public isSingletonTombToken;

    string public baseURI;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _marketFilterDAOAddress,
        address _tokenClaimSigner,
        address _indexMarkerV1,
        address payable _defaultRoyalty,
        address _indexContract
    ) public initializer {
        __Ownable_init();
        __ERC721_init("Tomb Index Marker", "MKR");
        __EIP712_init("Tomb Index Marker", "1");
        __ERC721Votes_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();

        // initialize RONIN
        _mint(_msgSender(), 0);

        indexMarkerV1 = IERC721Upgradeable(_indexMarkerV1);
        mintExpiry = 1672531199; // Sat Dec 31 2022 23:59:59 GMT+0000
        isMintAllowed = false;
        marketFilterDAOAddress = _marketFilterDAOAddress;
        tokenClaimSigner = _tokenClaimSigner;
        baseURI = "ipfs://QmYZEr3xvwdd5v5wbFR4LEDrqaBRLG3gXg5uC6SK37GfaQ/";
        indexContract = ERC721Upgradeable(_indexContract);
        _setTokenRoyalty(0, TOMB_ARTIST, DEFAULT_ROYALTY_BPS);
        _setDefaultRoyalty(_defaultRoyalty, DEFAULT_ROYALTY_BPS);
    }

    /// TOKEN AND MINTING ///

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        _requireMinted(tokenID);

        if (tokenID == 0) {
            return indexContract.tokenURI(21);
        }

        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenID)));
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) {
        if (from != _msgSender() && address(operatorFilterRegistry).code.length > 0) {
            require(
                operatorFilterRegistry.isOperatorAllowed(address(this), _msgSender()),
                "IndexMarker: operator not allowed"
            );
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function migrationMint(uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address recipient = indexMarkerV1.ownerOf(tokenIds[i]);
            require(recipient != address(0), "IndexMarker: token does not exist");
            _mint(recipient, tokenIds[i]);
        }
    }

    function adminMint(uint256[] calldata tokenIds, address[] calldata recipients) public onlyOwner {
        require(!canMint(), "Can't admin claim when mint active");
        require(tokenIds.length == recipients.length, "IndexMarker: invalid input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] <= MAX_SUPPLY, "IndexMarker: Index is too high");
            _mint(recipients[i], tokenIds[i]);
        }
    }

    function canMint() public view returns (bool) {
        return isMintAllowed && mintExpiry > block.timestamp;
    }

    function calculateMintHash(
        uint256 tokenId,
        bytes memory signature,
        address sender
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, signature, sender));
    }

    function premint(bytes32 _hash) public {
        require(premintTimes[_hash] == 0, "IndexMarker: Can't override hash value");
        premintTimes[_hash] = block.timestamp;
    }

    function mint(uint256 tokenId, bytes memory signature) public {
        require(canMint(), "IndexMarker: Public minting is not active");
        require(tokenId <= MAX_SUPPLY, "IndexMarker: Index is too high");
        bytes32 mintHash = calculateMintHash(tokenId, signature, _msgSender());
        uint256 premintTime = premintTimes[mintHash];
        require(premintTime != 0, "IndexMarker: Token is not preminted");

        require(block.timestamp - premintTime > 60, "IndexMarker: Claim is too new");

        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(
            keccak256(abi.encodePacked(tokenId)),
            signature
        );
        require(
            error == ECDSAUpgradeable.RecoverError.NoError && recovered == tokenClaimSigner,
            "IndexMarker: Invalid signature"
        );

        _mint(_msgSender(), tokenId);
    }

    function setTokenClaimSigner(address _tokenClaimSigner) public onlyOwner {
        tokenClaimSigner = _tokenClaimSigner;
    }

    function setMintAllowedAndExpiry(bool _isMintAllowed, uint256 _expiry) public onlyOwner {
        isMintAllowed = _isMintAllowed;
        mintExpiry = _expiry;
    }

    /// ROYALTIES ///

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /// OPERATOR FILTERING ///

    function updateMarketFilterSettings(bytes calldata args) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory ret) = address(operatorFilterRegistry).call(args);
        require(success, "IndexMarker: failed to update market settings");
        return ret;
    }

    function manageMarketFilterDAOSubscription(bool enable) external onlyOwner {
        address self = address(this);
        require(marketFilterDAOAddress != address(0), "IndexMarker: DAO not set");
        if (!operatorFilterRegistry.isRegistered(self) && enable) {
            operatorFilterRegistry.registerAndSubscribe(self, marketFilterDAOAddress);
        } else if (enable) {
            operatorFilterRegistry.subscribe(self, marketFilterDAOAddress);
        } else {
            operatorFilterRegistry.unsubscribe(self, false);
            operatorFilterRegistry.unregister(self);
        }
    }

    /// TOMB REGISTRY ///

    function setTombContracts(address[] memory _contracts, bool[] memory _isTombContract) public onlyOwner {
        require(_contracts.length == _isTombContract.length, "IndexMarker: invalid input");
        for (uint256 i = 0; i < _contracts.length; i++) {
            isTombContract[_contracts[i]] = _isTombContract[i];
        }
    }

    function setTombTokens(
        address[] memory _contracts,
        uint256[] memory _tokenIds,
        bool[] memory _isTombToken
    ) public onlyOwner {
        require(
            _contracts.length == _tokenIds.length && _tokenIds.length == _isTombToken.length,
            "IndexMarker: invalid input"
        );
        for (uint256 i = 0; i < _contracts.length; i++) {
            isSingletonTombToken[_contracts[i]][_tokenIds[i]] = _isTombToken[i];
        }
    }

    function isTomb(address _tokenContract, uint256 _tokenId) public view returns (bool) {
        return isTombContract[_tokenContract] || isSingletonTombToken[_tokenContract][_tokenId];
    }

    /// UUPS ///

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// ERC165 ///

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC173).interfaceId || super.supportsInterface(interfaceId);
    }
}