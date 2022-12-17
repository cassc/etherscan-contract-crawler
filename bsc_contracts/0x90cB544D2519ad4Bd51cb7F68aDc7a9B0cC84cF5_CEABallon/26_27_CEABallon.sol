// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./interfaces/ICEABallonGlobal.sol";

contract CEABallon is
    ERC721PresetMinterPauserAutoIdUpgradeable,
    OwnableUpgradeable,
    ICEABallonGlobal
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    mapping(uint256 => Nft) public nfts;
    mapping(uint256 => string) private _tokenURIs;
    CountersUpgradeable.Counter private tokenIdTracker;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GATEWAY_ROLE = keccak256("GATEWAY_ROLE");
    uint256 public nftLimitQuantity;
    string private _baseTokenURI;

    function nftInitialize() public initializer {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __Ownable_init();
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(GATEWAY_ROLE, _msgSender());

        __ERC721PresetMinterPauserAutoId_init("Mainet URL 1", "URL1", "");
        nftLimitQuantity = 1000;
    }

    event MintNft(address user, uint256 tokenId);

    function setNftLimitQuantity(
        uint256 _nftLimitQuantity
    ) public onlyRole(ADMIN_ROLE) {
        nftLimitQuantity = _nftLimitQuantity;
    }

    function safeMint(
        address account,
        NftInput memory nftInput
    ) public onlyRole(GATEWAY_ROLE) returns (uint256) {
        uint256 tokenId = getTokenIdTracker();
        require(tokenId <= nftLimitQuantity, "WHALE_NFT_HAS_REACH_LIMIT");
        mint(account);
        nfts[tokenId] = Nft(tokenId, nftInput.typeId, tx.origin, block.number);
        tokenIdTracker.increment();
        _setTokenURI(tokenId, tokenId.toString());
        require(ownerOf(tokenId) == account, "Create Nft not success");
        emit MintNft(account, tokenId);
        return tokenId;
    }

    function safeBatchMint(
        address account,
        NftInput[] memory nftInputs
    ) external onlyRole(GATEWAY_ROLE) returns (uint256[] memory) {
        uint256 length = nftInputs.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            uint256 id = safeMint(account, nftInputs[index]);
            ids[index] = id;
        }
        return ids;
    }

    function updateNft(
        uint256 tokenId,
        NftInput memory nftInput
    ) external onlyRole(GATEWAY_ROLE) returns (Nft memory) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        nfts[tokenId].typeId = nftInput.typeId;
        return nfts[tokenId];
    }

    function getNftById(uint256 tokenId) external view returns (Nft memory) {
        return nfts[tokenId];
    }

    function getNftByAddress(
        address _address,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (Nft[] memory) {
        Nft[] memory emptyResponse = new Nft[](0);
        uint256 limitIndex = balanceOf(_address) > toIndex
            ? toIndex
            : balanceOf(_address);
        uint256 length = limitIndex.sub(fromIndex);
        if (length == 0) return emptyResponse;
        if (fromIndex >= length) return emptyResponse;

        Nft[] memory _nfts = new Nft[](length);

        for (uint256 index = fromIndex; index < length; index++) {
            uint256 tokenId = tokenOfOwnerByIndex(_address, index);
            _nfts[index - fromIndex] = nfts[tokenId];
        }
        return _nfts;
    }

    function getNftByRanking(
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory emptyResponse = new NftInfo[](0);
        uint256 limitIndex = getTokenIdTracker() > toIndex
            ? toIndex
            : getTokenIdTracker();
        uint256 length = limitIndex.sub(fromIndex);
        if (length == 0) return emptyResponse;
        if (fromIndex >= length) return emptyResponse;

        NftInfo[] memory _nfts = new NftInfo[](length);

        for (uint256 index = fromIndex; index < length; index++) {
            uint256 tokenId = tokenByIndex(index);
            address _owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
            _nfts[index - fromIndex] = NftInfo(
                nfts[tokenId],
                _exists(tokenId),
                _owner
            );
        }
        return _nfts;
    }

    function getNftByTokenIds(
        uint256[] memory ids
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory emptyResponse = new NftInfo[](0);
        uint256 length = ids.length;
        if (length == 0) return emptyResponse;
        NftInfo[] memory _nfts = new NftInfo[](length);

        for (uint256 index = 0; index < length; index++) {
            uint256 tokenId = ids[index];
            address _owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
            _nfts[index] = NftInfo(nfts[tokenId], _exists(tokenId), _owner);
        }
        return _nfts;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyRole(ADMIN_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        if (hasRole(GATEWAY_ROLE, _msgSender())) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function getTokenIdTracker() public view returns (uint256) {
        return tokenIdTracker.current();
    }

    event SetBaseURI(string baseUri);

    function setBaseURI(string memory _baseUri) external {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have admin role to set value"
        );
        _baseTokenURI = _baseUri;
        emit SetBaseURI(_baseTokenURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}