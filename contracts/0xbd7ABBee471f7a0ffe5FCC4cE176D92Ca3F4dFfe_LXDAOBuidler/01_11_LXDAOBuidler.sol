// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ILXDAOBuidlerMetadata.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract LXDAOBuidler is Ownable, ERC721AQueryable {
    using ECDSA for bytes32;
    using Address for address;
    using Strings for uint256;

    enum Status {
        // the status of ready to mint.
        Pending,
        // the status of after buidler minted.
        Active,
        // the status set by community for security.
        // can be active again.
        Suspended,
        // the status set by community or buidler reason for buidler quit.
        // can be active again.
        Archived
    }

    address private signer;
    address private metadataAddress;
    mapping(uint256 => Status) public buidlerStatuses;

    event SignerChanged();
    event MetadataAddressChanged();
    event Minted(address minter, uint256 tokenId);
    event StatusChanged(Status status);

    constructor(address _signer, address _metadataAddress)
        ERC721A("LXDAOBuidler", "LXB")
    {
        require(
            _signer != address(0),
            "LXDAOBuidler: The signer cannot be initialized zero."
        );
        signer = _signer;
        metadataAddress = _metadataAddress;
    }

    modifier _checkMetadataAddress() {
        require(
            metadataAddress != address(0),
            "LXDAOBuidler: metadata address is zero."
        );
        _;
    }

    function _hashBatch(address[] memory owners, bytes[] calldata metadataURIs)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(owners, metadataURIs));
    }

    function _hashBytes(bytes calldata ipfsHash, address from)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(ipfsHash, from));
    }

    function _hashAddress(address sender) internal pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit SignerChanged();
    }

    function getSigner() external view onlyOwner returns (address) {
        return signer;
    }

    function setMetadataAddress(address _metadataAddress) external onlyOwner {
        metadataAddress = _metadataAddress;
        emit MetadataAddressChanged();
    }

    function getMetadataAddress() external view onlyOwner returns (address) {
        return metadataAddress;
    }

    function mint(bytes calldata metadataURI, bytes calldata signature)
        external
    {
        require(
            balanceOf(_msgSender()) == 0,
            "LXDAOBuidler: The buidler has already minted."
        );

        require(
            _verify(_hashBytes(metadataURI, _msgSender()), signature),
            "LXDAOBuidler: Invalid signature."
        );

        uint256 tokenId = _nextTokenId();
        _safeMint(_msgSender(), 1);
        buidlerStatuses[tokenId] = Status.Active;
        ILXDAOBuidlerMetadata(metadataAddress).create(tokenId, metadataURI);

        emit Minted(_msgSender(), tokenId);
    }

    function updateMetadata(
        uint256 tokenId,
        bytes calldata metadataURI,
        bytes calldata signature
    ) external {
        if (_msgSender() == owner()) {
            _updateMetadata(tokenId, metadataURI, signature);
        } else {
            require(
                ownerOf(tokenId) == _msgSender(),
                "LXDAOBuidler: Only owner can update metadata."
            );
            _updateMetadata(tokenId, metadataURI, signature);
        }
    }

    function _updateMetadata(
        uint256 tokenId,
        bytes calldata metadataURI,
        bytes calldata signature
    ) private _checkMetadataAddress {
        require(
            buidlerStatuses[tokenId] == Status.Active,
            "LXDAOBuidler: The token is not activating now."
        );
        require(
            _verify(_hashBytes(metadataURI, ownerOf(tokenId)), signature),
            "LXDAOBuidler: Invalid signature."
        );

        ILXDAOBuidlerMetadata(metadataAddress).update(tokenId, metadataURI);
    }

    function batchUpdateMetadata(
        uint256[] calldata tokenIds,
        bytes[] calldata metadataURIs,
        bytes calldata signature
    ) external onlyOwner {
        require(
            tokenIds.length == metadataURIs.length,
            "LXDAOBuidler: the length of owners is not equal to the length of metadataURIs."
        );

        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            owners[i] = ownerOf(tokenId);

            require(
                buidlerStatuses[tokenId] == Status.Active,
                "LXDAOBuidler: The token is not activating now."
            );
        }

        require(
            _verify(_hashBatch(owners, metadataURIs), signature),
            "LXDAOBuidler: Invalid signature."
        );

        ILXDAOBuidlerMetadata(metadataAddress).batchUpdate(
            tokenIds,
            metadataURIs
        );
    }

    function activate(uint256 tokenId) external onlyOwner {
        require(
            buidlerStatuses[tokenId] == Status.Suspended ||
                buidlerStatuses[tokenId] == Status.Archived,
            "LXDAOBuidler: The buidler is not suspended or archived now."
        );

        buidlerStatuses[tokenId] = Status.Active;
        emit StatusChanged(Status.Active);
    }

    function suspend(uint256 tokenId) external onlyOwner {
        require(
            buidlerStatuses[tokenId] == Status.Active,
            "LXDAOBuidler: The buidler is not activating now."
        );

        buidlerStatuses[tokenId] = Status.Suspended;
        emit StatusChanged(Status.Suspended);
    }

    function archive(uint256 tokenId) external {
        if (_msgSender() == owner()) {
            _archive(tokenId);
        } else {
            require(
                ownerOf(tokenId) == _msgSender(),
                "LXDAOBuidler: Only owner can archive."
            );
            _archive(tokenId);
        }
    }

    function _archive(uint256 tokenId) private {
        require(
            buidlerStatuses[tokenId] == Status.Active,
            "LXDAOBuidler: The buidler is not activating now."
        );

        buidlerStatuses[tokenId] = Status.Archived;
        emit StatusChanged(Status.Archived);
    }

    function approve(address, uint256) public pure override(ERC721A) {
        require(false, "LXDAOBuidler: Cannot approve.");
    }

    function setApprovalForAll(address, bool) public pure override(ERC721A) {
        require(false, "LXDAOBuidler: Cannot setApprovalForAll.");
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (_msgSender() == super.owner()) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) onlyOwner {
        safeTransferFrom(from, to, tokenId, bytes(""));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721A) onlyOwner {
        _transferToken(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) onlyOwner {
        _transferToken(from, to, tokenId, bytes(""));
    }

    function _transferToken(
        address from,
        address to,
        uint256 tokenId,
        bytes memory
    ) private {
        require(
            ownerOf(tokenId) == from,
            "LXDAOBuidler: `from` address has no token."
        );
        require(
            balanceOf(to) == 0,
            "LXDAOBuidler: `to` address already has token."
        );
        require(
            buidlerStatuses[tokenId] == Status.Suspended,
            "LXDAOBuidler: The Active or archived token cannot be transfer."
        );

        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            return "";
        }

        return ILXDAOBuidlerMetadata(metadataAddress).tokenURI(tokenId);
    }

    function tokenIdOfOwner(address owner) public view returns (uint256) {
        require(
            balanceOf(owner) > 0,
            "LXDAOBuidler: `from` address has no token."
        );
        uint256[] memory tokens = this.tokensOfOwner(owner);
        return tokens[0];
    }
}