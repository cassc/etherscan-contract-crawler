// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
  @dev when user don't have nft, they have to mint and admin will setValidTargets for user
 */
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../interfaces/IPadi721.sol";
import "../../interfaces/IWhitelist.sol";
import "../../interfaces/IOpenseaStandard.sol";
import "../../shared/WhitelistUpgradeable.sol";

contract Padi721 is
    Initializable,
    IOpenseaStandard,
    IPadi721,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    WhitelistUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(uint256 => bool) private requestAssetIds;
    bytes32 private _TYPEHASH;
    uint256 public mintFee;
    address private _treasuryAddress;
    address private _airdropAddress;
    string public override(IOpenseaStandard) contractURI;

    event Mint(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 quantity,
        string ipfs
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyNftOwner(uint256 _tokenId) {
        require(
            ownerOf(_tokenId) == _msgSender(),
            "Padi721: You are not owner of NFT"
        );
        _;
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function initialize(address _whitelistAddress) public initializer {
        __ERC721_init("Padi721", "PDT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __WhitelistUpgradeable_init(_whitelistAddress);
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __EIP712_init(name(), "1");
        _TYPEHASH = keccak256(
            "params(address _requester,uint256 _assetId,uint256 _nonce)"
        );
        mintFee = 0.005 ether;
        _treasuryAddress = _msgSender();
    }

    function pause() public validateAdmin {
        _pause();
    }

    function unpause() public validateAdmin {
        _unpause();
    }

    function safeMint(
        string memory _ipfs,
        bytes calldata _signature,
        MintAssetRequest calldata _req
    ) external payable validateGranterOnPerson(getAddressWithSignature(_signature, _req)) override(IPadi721) {
        require (msg.value >= mintFee, "Padi721: Not enough fee");
        (bool success, ) = _treasuryAddress.call{value: msg.value}("");
        require(success, "Padi721: Can not send money");
        require(requestAssetIds[_req.assetId] == false, "Asset is minted!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _ipfs);
        requestAssetIds[_req.assetId] = true;
        emit Mint(address(0), msg.sender, address(this), tokenId, 1, _ipfs);
    }

    function claim(address _to, string memory _ipfs) external override(IPadi721) {
        require (msg.sender == _airdropAddress, "Padi721: not airdrop address");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _ipfs);
    }

    function burn(uint256 tokenId) public override(ERC721BurnableUpgradeable) {
        super.burn(tokenId);
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _uri
    ) external onlyNftOwner(_tokenId) {
        _setTokenURI(_tokenId, _uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override validateAdmin {}

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(IOpenseaStandard,ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getAddressWithSignature(
        bytes calldata signature,
        MintAssetRequest calldata req
    ) public view returns (address) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(_TYPEHASH, req.requester, req.assetId, req.nonce)
            )
        ).recover(signature);

        return signer;
    }

    function setMintFee(uint256 _value) external validateAdmin {
        mintFee = _value;
    }

    function setTreasuryAddress(address _address) external validateAdmin {
        _treasuryAddress = _address;
    }

    function setAirdropAddress(address _address) external validateAdmin {
        _airdropAddress = _address;
    }

    function setContractURI(string memory _contractURI) external override(IOpenseaStandard) {
        contractURI = _contractURI;
    }
}