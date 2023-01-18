// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./IUtilityPolymonTracker.sol";

interface IPolkamonERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function burn(uint256 tokenId) external;
}

interface IOpener {
    function registeredHashes(address owner, bytes32 hash) external view returns (bool);

    function alreadyMinted(uint256 nftId) external view returns (bool);
}

interface ISoftMinterWrapper {
    function registeredHashes(address to, uint256[] memory ids) external view returns (bool);

    function alreadyMinted(uint256 nftId) external view returns (bool);
}

interface IBurnTrackable {
    function burnedTokens(uint256 nftId) external view returns (bool);
}

struct IsMintedResult {
    bool isOwner;
    uint256 polkamonERC721Index;
}

contract UtilityPolymonTrackerV2 is AccessControlEnumerableUpgradeable, IUtilityPolymonTracker {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IBurnTrackable public reverseSwap;
    // unused
    IOpener public opener;
    ISoftMinterWrapper public softMinterWrapper;

    IPolkamonERC721[] public polkamonERC721List;

    mapping(uint256 => bool) private _burnedTokens;

    IOpener[] public openerList;

    event Burn(address indexed owner, uint256 indexed tokenId);
    event BurnOwnHardMinted(address indexed owner, uint256 indexed tokenId);
    event BurnOwnSoftMinted(address indexed owner, uint256 indexed tokenId);
    event BurnOwnSoftMintedOld(address indexed owner, uint256 indexed tokenId);

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert("Only allowed for specific role");
        }
        _;
    }

    function initialize(
        IBurnTrackable _reverseSwap,
        IOpener _opener,
        ISoftMinterWrapper _softMinterWrapper,
        IPolkamonERC721[] memory _polkamonERC721List
    ) public initializer {
        reverseSwap = _reverseSwap;
        opener = _opener;
        softMinterWrapper = _softMinterWrapper;
        polkamonERC721List = _polkamonERC721List;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        if (address(reverseSwap) != address(0)) {
            _setupRole(BURNER_ROLE, address(reverseSwap));
        }
    }

    /// @notice get owner status for multiple tokens. If the owner of any of these tokens does not match the owner
    /// passed to this function the result is false.
    function isOwner(
        address owner,
        SoftMintedData[] memory softMinted,
        SoftMintedDataOld[] memory softMintedOld,
        uint256[] memory hardMinted
    ) external view override returns (bool) {
        bool result = true;
        for (uint256 i; i < softMinted.length && result; i++) {
            result = isOwnerSoftMinted(owner, softMinted[i]);
        }
        for (uint256 i; i < softMintedOld.length && result; i++) {
            result = isOwnerSoftMintedOld(owner, softMintedOld[i]);
        }
        for (uint256 i; i < hardMinted.length && result; i++) {
            result = isOwnerHardMinted(owner, hardMinted[i]);
        }
        return result;
    }

    /// @notice get owner status from the opener contract (only for soft minted tokens)
    function isOwnerSoftMinted(address owner, SoftMintedData memory data) public view override returns (bool) {
        return
            _requireTokenToBeSoftMinted(data.id) &&
            _ownsRegisteredHash(owner, data) &&
            !_isBurned(data.id);
    }

    /// @notice get owner status from the soft minter contract (only for old soft minted tokens on ethereum)
    function isOwnerSoftMintedOld(address owner, SoftMintedDataOld memory data) public view override returns (bool) {
        return _requireTokenToBeSoftMintedOld(data.id) && softMinterWrapper.registeredHashes(owner, data.ids) && !_isBurned(data.id);
    }

    /// @notice get owner status from the ERC721 contract (only for hard minted tokens)
    function isOwnerHardMinted(address owner, uint256 nftId) public view override returns (bool) {
        return _isOwnerHardMinted(owner, nftId).isOwner;
    }

    function _isOwnerHardMinted(address owner, uint256 nftId) internal view returns (IsMintedResult memory result) {
        for (uint256 i; i < polkamonERC721List.length && !result.isOwner; i++) {
            try polkamonERC721List[i].ownerOf(nftId) returns (address _owner) {
                if (owner == _owner) {
                    result.isOwner = true;
                    result.polkamonERC721Index = i;
                }
            } catch Error(string memory _err) {
                // token is burned
            }
        }
        return result;
    }

    function _requireTokenToBeSoftMinted(uint256 nftId) internal view returns (bool) {
        for (uint256 i; i < openerList.length; i++) {
            if (openerList[i].alreadyMinted(nftId))
                return false;
        }
        return true;
    }

    function _ownsRegisteredHash(address owner, SoftMintedData memory data) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(owner, data.first, data.last));
        for (uint256 i; i < openerList.length; i++) {
            if (openerList[i].registeredHashes(owner, hash))
                return true;
        }
        return false;
    }

    function _requireTokenToBeSoftMintedOld(uint256 nftId) internal view returns (bool) {
        return !softMinterWrapper.alreadyMinted(nftId);
    }

    function _isBurned(uint256 nftId) internal view returns (bool) {
        return _burnedTokens[nftId] || (address(reverseSwap) != address(0) && reverseSwap.burnedTokens(nftId));
    }

    function _burnToken(
        address owner,
        uint256 nftId,
        bool hardminted
    ) internal {
        _burnedTokens[nftId] = true;
        if (hardminted) {
            IsMintedResult memory res = _isOwnerHardMinted(owner, nftId);
            polkamonERC721List[res.polkamonERC721Index].burn(nftId);
        }
        emit Burn(owner, nftId);
    }

    function burnOwnHardMintedToken(uint256 nftId) external {
        require(isOwnerHardMinted(msg.sender, nftId), "Not own hard minted nft");
        _burnToken(msg.sender, nftId, true);
        emit BurnOwnHardMinted(msg.sender, nftId);
    }

    function burnOwnSoftMintedToken(SoftMintedData memory data) external {
        require(isOwnerSoftMinted(msg.sender, data), "Not own soft minted nft");
        _burnToken(msg.sender, data.id, false);
        emit BurnOwnSoftMinted(msg.sender, data.id);
    }

    function burnOwnSoftMintedOldToken(SoftMintedDataOld memory data) external {
        require(isOwnerSoftMintedOld(msg.sender, data), "Not own soft minted old nft");
        _burnToken(msg.sender, data.id, false);
        emit BurnOwnSoftMinted(msg.sender, data.id);
    }

    function burnToken(
        address owner,
        uint256 nftId,
        bool hardminted
    ) external override onlyRole(BURNER_ROLE) {
        _burnToken(owner, nftId, hardminted);
    }

    function burnedTokens(uint256 nftId) external view returns (bool) {
        return _isBurned(nftId);
    }

    function setReverseSwap(IBurnTrackable _reverseSwap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(reverseSwap) != address(0)) {
            revokeRole(BURNER_ROLE, address(reverseSwap));
        }
        reverseSwap = _reverseSwap;
        if (address(reverseSwap) != address(0)) {
            _setupRole(BURNER_ROLE, address(reverseSwap));
        }
    }

    function setSoftMinterWrapper(ISoftMinterWrapper _softMinterWrapper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        softMinterWrapper = _softMinterWrapper;
    }

    function setPolkamonERC721List(IPolkamonERC721[] memory _polkamonERC721List) external onlyRole(DEFAULT_ADMIN_ROLE) {
        polkamonERC721List = _polkamonERC721List;
    }

    function setOpenerList(IOpener[] memory _openerList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openerList = _openerList;
    }
}