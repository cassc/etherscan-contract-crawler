// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./BaseCollection.sol";

contract TokenCollection is
    BaseCollection,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable
{
    event RedeemableCreated(uint256 indexed redeemableId);
    event TokenRedeemed(
        address indexed collector,
        uint256 indexed redeemableId,
        uint256 quantity
    );

    struct Redeemable {
        string tokenURI;
        uint256 price;
        uint256 maxAmount;
        uint256 maxPerWallet;
        uint256 maxPerMint;
        uint256 redeemedCount;
        bytes32 merkleRoot;
        bool active;
        uint256 nonce;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;
    using MerkleProofUpgradeable for bytes32[];
    using ECDSAUpgradeable for bytes32;

    CountersUpgradeable.Counter private _tokenIdCounter;
    CountersUpgradeable.Counter private _redeemablesCounter;
    mapping(uint256 => Redeemable) private _redeemables;
    mapping(uint256 => mapping(address => uint256)) private _redeemedByWallet;

    modifier onlyRedeemable(
        uint256 redeemableId,
        uint256 numberOfTokens,
        bytes calldata signature
    ) {
        Redeemable memory redeemable = _redeemables[redeemableId];
        require(redeemable.active, "Not valid: 1");
        require(
            redeemable.price.mul(numberOfTokens) <= msg.value,
            "Value incorrect"
        );
        require(
            _redeemedByWallet[redeemableId][_msgSender()].add(numberOfTokens) <=
                redeemable.maxPerWallet,
            "Exceeded max: 1"
        );
        require(
            redeemable.redeemedCount.add(numberOfTokens) <=
                redeemable.maxAmount,
            "Exceeded max: 2"
        );
        require(
            keccak256(abi.encodePacked(redeemableId.add(redeemable.nonce)))
                .toEthSignedMessageHash()
                .recover(signature) == owner(),
            "Not valid: 2"
        );
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public override initializer {
        __BaseCollection_init(name_, symbol_, treasury_, royalty_, royaltyFee_);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
    }

    function mint(address to, string memory uri) public onlyOwner {
        _mint(to, uri);
    }

    function createRedeemable(
        string memory uri,
        uint256 price,
        uint256 maxAmount,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) public onlyOwner {
        uint256 redeemableId = _redeemablesCounter.current();
        _redeemablesCounter.increment();

        _redeemables[redeemableId] = Redeemable({
            tokenURI: uri,
            price: price,
            maxAmount: maxAmount,
            maxPerWallet: maxPerWallet,
            maxPerMint: maxPerMint,
            redeemedCount: 0,
            merkleRoot: "",
            active: true,
            nonce: 0
        });

        emit RedeemableCreated(redeemableId);
    }

    function setMerkleRoot(uint256 redeemableId, bytes32 newRoot)
        public
        onlyOwner
    {
        require(_redeemables[redeemableId].active, "Invalid Redeemable");

        _redeemables[redeemableId].merkleRoot = newRoot;
    }

    function invalidate(uint256 redeemableId) public onlyOwner {
        require(_redeemables[redeemableId].active, "Invalid Redeemable");

        _redeemables[redeemableId].nonce = _redeemables[redeemableId].nonce.add(
            1
        );
    }

    function revoke(uint256 redeemableId) public onlyOwner {
        require(_redeemables[redeemableId].active, "Invalid Redeemable");

        _redeemables[redeemableId].active = false;
    }

    function redeem(
        uint256 redeemableId,
        uint256 numberOfTokens,
        bytes calldata signature
    ) public payable onlyRedeemable(redeemableId, numberOfTokens, signature) {
        Redeemable memory redeemable = _redeemables[redeemableId];
        require(redeemable.merkleRoot == "", "Not valid: 3");

        _redeem(redeemableId, numberOfTokens);
    }

    function redeem(
        uint256 redeemableId,
        uint256 numberOfTokens,
        bytes calldata signature,
        bytes32[] calldata proof
    ) public payable onlyRedeemable(redeemableId, numberOfTokens, signature) {
        Redeemable memory redeemable = _redeemables[redeemableId];
        require(redeemable.merkleRoot != "", "Not valid: 3");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                redeemable.merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not valid: 4"
        );

        _redeem(redeemableId, numberOfTokens);
    }

    function totalRedeemables() external view returns (uint256) {
        return _redeemablesCounter.current();
    }

    function redeemableByIndex(uint256 index)
        external
        view
        returns (
            string memory uri,
            uint256 price,
            uint256 maxAmount,
            uint256 maxPerWallet,
            uint256 maxPerMint,
            uint256 redeemedCount,
            bytes32 merkleRoot,
            bool active,
            uint256 nonce
        )
    {
        Redeemable memory redeemable = _redeemables[index];

        return (
            redeemable.tokenURI,
            redeemable.price,
            redeemable.maxAmount,
            redeemable.maxPerWallet,
            redeemable.maxPerMint,
            redeemable.redeemedCount,
            redeemable.merkleRoot,
            redeemable.active,
            redeemable.nonce
        );
    }

    function _redeem(uint256 redeemableId, uint256 numberOfTokens) internal {
        Redeemable memory redeemable = _redeemables[redeemableId];

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
            _redeemables[redeemableId].redeemedCount = redeemable
                .redeemedCount
                .add(numberOfTokens);
            _redeemedByWallet[redeemableId][_msgSender()] = _redeemedByWallet[
                redeemableId
            ][_msgSender()].add(numberOfTokens);
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(_msgSender(), redeemable.tokenURI);
        }

        _niftyKit.addFees(msg.value);
        emit TokenRedeemed(_msgSender(), redeemableId, numberOfTokens);
    }

    function _mint(address to, string memory uri) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(BaseCollection, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseCollection, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}