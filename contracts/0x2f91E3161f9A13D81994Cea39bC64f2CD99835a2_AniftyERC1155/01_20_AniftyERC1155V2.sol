//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./util/Ownable.sol";
import "./util/AccessControl.sol";
import "./util/ERC1155PausableV2.sol";
import "./interfaces/IERC1271.sol";
import "./libraries/ERC1155Holder.sol";

interface AniftyERC1155V1 {
    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract AniftyERC1155 is
    AccessControl,
    ERC1155Pausable,
    ERC1155Holder,
    Ownable
{
    struct ExistingTokenURI {
        uint256 tokenId;
        address signer;
        string uri;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    using Counters for Counters.Counter;
    Counters.Counter private adminTokenIds;
    AniftyERC1155V1 aniftyERC1155V1;

    // Mapping of whitelisted addresses, addresses include lootbox contracts
    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public functionNotSupported;

    bytes32 internal immutable _DOMAIN_SEPARATOR;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRANSFER_SIGNER_ROLE =
        keccak256("TRANSFER_SIGNER_ROLE");

    uint64 public startTokenId;

    constructor(
        address _admin,
        address _signer,
        uint64 _startAdminTokenId,
        AniftyERC1155V1 _aniftyERC1155V1
    ) public ERC1155("ipfs://") {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("AniftyERC1155"),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        aniftyERC1155V1 = _aniftyERC1155V1;
        // Start after the last minted tokenId from V1
        adminTokenIds._value = _startAdminTokenId;
        startTokenId = _startAdminTokenId;
        _setBaseURI("ipfs://");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(TRANSFER_SIGNER_ROLE, _signer);
    }

    // =========================================================== VIEW ===========================================================

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function _verify(
        bytes32 signedHash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), signedHash)
        );
        if (Address.isContract(signer)) {
            require(
                IERC1271(signer).isValidSignature(
                    digest,
                    abi.encodePacked(r, s, v)
                ) == 0x1626ba7e,
                "AniftyERC1155: UNAUTHORIZED"
            );
        } else {
            require(
                ecrecover(digest, v, r, s) == signer,
                "AniftyERC1155: UNAUTHORIZED"
            );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function hash(ExistingTokenURI memory existingTokenURI)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    // keccak256("ExistingTokenURI(uint256 tokenId,address signer,string uri)")
                    0x5f9d3ceadcd5e9e1bfbb494a85c65503b9fd43ee76adbf589ea49172bed4e23f,
                    existingTokenURI.tokenId,
                    existingTokenURI.signer,
                    keccak256(bytes(existingTokenURI.uri))
                )
            );
    }

    // =========================================================== MODIFIER ===========================================================

    modifier onlyWhitelist() {
        require(
            whitelist[msg.sender] == true,
            "Caller is not from a whitelist address"
        );
        _;
    }

    // =========================================================== EXTERNAL ===========================================================

    function whitelistMint(
        uint256 amount,
        string memory metadataURI,
        bytes calldata data
    ) external onlyWhitelist returns (uint256) {
        adminTokenIds.increment();
        // Increment tokenId
        uint256 tokenId = adminTokenIds.current();
        // Mint
        _mint(msg.sender, tokenId, amount, data);
        // Set ipfs hash uri
        _setTokenURI(tokenId, metadataURI);
        return tokenId;
    }

    function whitelistMintBatch(
        uint256[] memory amounts,
        string[] memory metadataURIs,
        bytes calldata data
    ) external onlyWhitelist returns (uint256[] memory) {
        require(
            amounts.length == metadataURIs.length,
            "AniftyERC1155: Incorrect parameter length"
        );
        uint256[] memory tokenIds = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            adminTokenIds.increment();
            tokenIds[i] = adminTokenIds.current();
        }
        _mintBatch(msg.sender, tokenIds, amounts, data);
        _setTokenURIBatch(tokenIds, metadataURIs);
        return tokenIds;
    }

    function transferV1(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        ExistingTokenURI[] memory existingTokenURIs,
        bytes calldata data
    ) external {
        require(
            tokenIds.length == existingTokenURIs.length,
            "AniftyERC1155: Incorrect parameter length"
        );
        require(
            tokenIds.length > 0,
            "AniftyERC1155: Incorrect parameter length"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                (keccak256(abi.encodePacked((uri(tokenIds[i])))) !=
                    keccak256(abi.encodePacked((ERC1155.uri(tokenIds[i])))))
            ) continue;
            require(
                hasRole(TRANSFER_SIGNER_ROLE, existingTokenURIs[i].signer),
                "AniftyERC1155: Invalid role"
            );
            require(
                existingTokenURIs[i].tokenId == tokenIds[i],
                "AniftyERC1155: Invalid tokenId"
            );
            require(
                existingTokenURIs[i].tokenId <= startTokenId,
                "AniftyERC1155: Invalid tokenId"
            );
            _verify(
                hash(existingTokenURIs[i]),
                existingTokenURIs[i].signer,
                existingTokenURIs[i].v,
                existingTokenURIs[i].r,
                existingTokenURIs[i].s
            );
            _setTokenURI(tokenIds[i], existingTokenURIs[i].uri);
        }
        aniftyERC1155V1.safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds,
            amounts,
            ""
        );
        aniftyERC1155V1.burnBatch(tokenIds, amounts);
        _mintBatch(msg.sender, tokenIds, amounts, data);
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    // =========================================================== ADMIN ===========================================================

    function removeWhitelistAddress(address[] memory _whitelistAddresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelist[_whitelistAddresses[i]] = false;
        }
    }

    function addWhitelistAddress(address[] memory _whitelistAddresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelist[_whitelistAddresses[i]] = true;
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        require(!functionNotSupported[0], "AniftyERC1155: NO PAUSE FUNCTION");
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setTokenUri(uint256[] memory tokenIds, string[] memory tokenURIs)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!functionNotSupported[1], "AniftyERC1155: NO SET URI FUNCTION");
        _setTokenURIBatch(tokenIds, tokenURIs);
    }

    function removeFunction(uint256 functionId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        functionNotSupported[functionId] = true;
    }
}