// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@orderinbox/royalties/contracts/impl/RoyaltiesImpl.sol";
import "@orderinbox/royalties/contracts/RoyaltiesUpgradeable.sol";
import "@orderinbox/mint/contracts/erc-721/IERC721Mint.sol";
import "./Mint721Validator.sol";

abstract contract ERC721Mint is IERC721Mint, ERC721URIStorageUpgradeable, Mint721Validator, RoyaltiesUpgradeable, RoyaltiesImpl {
    
    using SafeMathUpgradeable for uint;

    event Creators(uint256 tokenId, LibPart.Part[] creators);

    // tokenId => creators
    mapping(uint256 => LibPart.Part[]) private creators;

    function __ERC721Mint_init_unchained() internal onlyInitializing {
        _registerInterface(0x8486f69f);
    }

    function transferFromOrMint(
        LibERC721Mint.Mint721Data memory data,
        address from,
        address to
    ) override external {
        if (_exists(data.tokenId)) {
            safeTransferFrom(from, to, data.tokenId);
        } else {
            _mintAndTransfer(data, to);
        }
    }

    function _mintAndTransfer(LibERC721Mint.Mint721Data memory data, address to) internal {
        address minter = data.creators[0].account;
        address sender = _msgSender();

        require(data.creators.length == data.signatures.length);
        require(minter == sender || isApprovedForAll(minter, sender), "ERC721: transfer caller is not minter nor approved");

        bytes32 hash = LibERC721Mint.hash(data);
        for (uint i = 0; i < data.creators.length; i++) {
            address creator = data.creators[i].account;
            if (creator != sender) {
                validate(creator, hash, data.signatures[i]);
            }
        }

        _safeMint(to, data.tokenId);
        _saveRoyalties(data.tokenId, data.royalties);
        _saveCreators(data.tokenId, data.creators);
        _setTokenURI(data.tokenId, data.tokenURI);
    }

    function _saveCreators(uint tokenId, LibPart.Part[] memory _creators) internal {
        LibPart.Part[] storage creatorsOfToken = creators[tokenId];
        uint total = 0;
        for (uint i = 0; i < _creators.length; i++) {
            require(_creators[i].account != address(0x0), "Account should be present");
            require(_creators[i].value != 0, "Creator share should be positive");
            creatorsOfToken.push(_creators[i]);
            total = total.add(_creators[i].value);
        }
        require(total == 10000, "total amount of creators share should be 10000");
        emit Creators(tokenId, _creators);
    }

    function updateAccount(uint256 _id, address _from, address payable _to) external {
        require(_msgSender() == _from, "not allowed");
        super._updateAccount(_id, _from, _to);
    }

    function getCreators(uint256 _id) public view returns (LibPart.Part[] memory) {
        return creators[_id];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable, ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyCreators(uint256 _id) {
        LibPart.Part[] memory creatorsOfToken = creators[_id];

        bool isCreator = false;
        for (uint i = 0; i < creatorsOfToken.length; i++) {
            address creator = creatorsOfToken[i].account;
            if (creator == _msgSender()) {
                isCreator = true;
                break;
            }            
        }

        require(isCreator, "ERC721Mint: not creator");
        _;
    }

    function updateRoyaltiesInterfaces() external {
        _registerRoyaltiesInterfaces();
    }

    uint256[50] private __gap;
}