// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../../interfaces/IPadi1155.sol";
import "../../interfaces/IWhitelist.sol";
import "../../interfaces/IOpenseaStandard.sol";
import "../../shared/WhitelistUpgradeable.sol";

contract Padi1155 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155URIStorageUpgradeable,
    WhitelistUpgradeable,
    UUPSUpgradeable,
    IOpenseaStandard,
    IPadi1155
{
    using ECDSAUpgradeable for bytes32;
    uint256 private _tokenIdCounter;
    mapping(uint256 => bool) private requestAssetIds;
    bytes32 public DOMAIN_SEPARATOR;

    uint256 public mintFee;
    address private _treasuryAddress;
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

    function initialize(address _whitelistAddress) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __WhitelistUpgradeable_init(_whitelistAddress);
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Padi1155")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        mintFee = 0.005 ether;
        _treasuryAddress = _msgSender();
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        override(ERC1155URIStorageUpgradeable, ERC1155Upgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    function setUri(
        uint256 _tokenId,
        string memory _tokenUri
    ) public validateAdmin {
        super._setURI(_tokenId, _tokenUri);
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
    ) external payable validateGranterOnPerson(getAddressWithSignature(_signature, _req)) override(IPadi1155) {
        require (msg.value >= mintFee, "Padi1155: Not enough fee");
        (bool success, ) = _treasuryAddress.call{value: msg.value}("");
        require(success, "Padi1155: Can not send money");
        require(requestAssetIds[_req.assetId] == false, "Asset is minted!");
        _mint(msg.sender, _tokenIdCounter, _req.amount, "0x");
        _setURI(_tokenIdCounter, _ipfs);
        _tokenIdCounter++;
        requestAssetIds[_req.assetId] = true;
        emit Mint(
            address(0),
            msg.sender,
            address(this),
            _tokenIdCounter - 1,
            _req.amount,
            _ipfs
        );
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 value
    ) public validateAdmin override(ERC1155BurnableUpgradeable) {
        super.burn(account, tokenId, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override(ERC1155BurnableUpgradeable) validateAdmin {
        super.burnBatch(account, ids, values);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external validateAdmin {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override validateAdmin {}

    function getAddressWithSignature(
        bytes calldata signature,
        MintAssetRequest calldata req
    ) public view returns (address) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "params(address _requester,uint256 _assetId,uint256 _amount,uint256 _nonce)"
                ),
                req.requester,
                req.assetId,
                req.amount,
                req.nonce
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
        address signer = hash.recover(signature);
        return signer;
    }

    function setMintFee(uint256 _value) external validateAdmin {
        mintFee = _value;
    }

    function setTreasuryAddress(address _address) external validateAdmin {
        _treasuryAddress = _address;
    }

    function tokenURI(uint256 tokenId) external view override(IOpenseaStandard)  returns(string memory) {
        return uri(tokenId);
    }

    function setContractURI(string memory _contractURI) external override(IOpenseaStandard) {
        contractURI = _contractURI;
    }
}