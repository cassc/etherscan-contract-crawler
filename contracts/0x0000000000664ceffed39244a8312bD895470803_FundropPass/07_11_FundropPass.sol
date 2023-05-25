// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

import "./NonTransferrableERC721.sol";
import "./IERC4906.sol";
import "./IFundropRewards.sol";
import "./IMetadataRenderer.sol";

contract FundropPass is NonTransferrableERC721, IERC4906, Ownable {
    address public metadataRenderer;
    address public rewardsDistributor;

    address public metadataUpdater;
    address public signer;
    bool public mintOpen;

    error InvalidSignature();
    error MintClosed();
    error OnlyOwnerOrMetadataUpdater();

    event MinterReferred(address referrer);

    constructor() NonTransferrableERC721("mint.fun !fundrop pass", "FUNPASS") {
        if (msg.sender != tx.origin) {
            transferOwnership(tx.origin);
        }
    }

    function mint(address referrer, bytes calldata signature) public {
        if (!mintOpen) revert MintClosed();
        address recovered = ECDSA.tryRecoverCalldata(keccak256(abi.encodePacked(msg.sender, referrer)), signature);
        if (recovered != signer) revert InvalidSignature();
        if (referrer != address(0)) emit MinterReferred(referrer);
        _mint(msg.sender);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert InvalidTokenId();
        return IMetadataRenderer(metadataRenderer).tokenURI(id);
    }

    // Admin functions

    function refreshMetadata() public {
        if (msg.sender != metadataUpdater && msg.sender != owner()) {
            revert OnlyOwnerOrMetadataUpdater();
        }
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
        refreshMetadata();
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setRewardsDistributor(address _rewardsDistributor) public onlyOwner {
        rewardsDistributor = _rewardsDistributor;
    }

    function setMintOpen(bool _mintOpen) public onlyOwner {
        mintOpen = _mintOpen;
    }

    function adminBurn(uint256[] calldata ids) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _burn(ids[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }
}