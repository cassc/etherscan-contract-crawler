// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Auth.sol";
import "./ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

struct TokenConfig {
    bool added;
    bool canMint;
    bool canBurn;
    uint256 supplyLimit;
}

contract Token is ERC1155, Pausable, Ownable, Auth {
    string public name;
    string public symbol;
    string public contractURI;
    string private _uri;

    mapping(address => bool) private _approvalAllowlist;

    uint16 public constant ROLE_ADD_FT = 1 << 0;
    uint16 public constant ROLE_MODIFY_FT = 1 << 1;
    uint16 public constant ROLE_MINT_FT = 1 << 2;
    uint16 public constant ROLE_MINT_NFT = 1 << 3;
    uint16 public constant ROLE_BATCH_MINT_NFT = 1 << 4;
    uint16 public constant ROLE_BURN_FT = 1 << 5;
    uint16 public constant ROLE_BURN_NFT = 1 << 6;
    uint16 public constant ROLE_BATCH_BURN_NFT = 1 << 7;
    uint16 public constant ROLE_REFRESH_METADATA = 1 << 8;
    uint16 public constant ROLE_SET_PAUSED = 1 << 9;
    uint16 public constant ROLE_BYPASS_PAUSE = 1 << 10;

    uint256 public constant FUNGIBLE_TOKEN_UPPER_BOUND = 10_000;

    mapping(uint256 => TokenConfig) private _added;

    mapping(uint256 => uint256) private _minted;
    mapping(uint256 => uint256) private _burned;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) ERC1155() {
        setMetadata(name_, symbol_, contractURI_, uri_);

        // Contract owner gets all roles by default. (11 roles, so the mask is 2^12 - 1 = 0b111_1111_1111.)
        setRole(msg.sender, (1 << 12) - 1);
    }

    function setMetadata(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) public onlyOwner {
        name = name_;
        symbol = symbol_;
        contractURI = contractURI_;
        _uri = uri_;
    }

    function uri(
        uint256
    ) public view override(ERC1155) returns (string memory) {
        return _uri;
    }

    function setApprovalAllowlist(
        address operator,
        bool approved
    ) public onlyOwner {
        _approvalAllowlist[operator] = approved;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override(ERC1155) returns (bool) {
        if (_approvalAllowlist[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setPaused(bool b) public requireRole(ROLE_SET_PAUSED) {
        if (b) {
            require(b && !paused(), "Contract is already paused");
            _pause();
            return;
        }

        require(!b && paused(), "Contract is not paused");
        _unpause();
    }

    function _isFungible(uint256 id) internal pure returns (bool) {
        return id < FUNGIBLE_TOKEN_UPPER_BOUND;
    }

    function _supplyLimit(uint256 id) internal view returns (uint256) {
        if (!_isFungible(id)) {
            return 1;
        }

        return _added[id].supplyLimit;
    }

    function supplyLimit(uint256 id) public view returns (uint256) {
        return _supplyLimit(id);
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _minted[id] - _burned[id];
    }

    function addFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public requireRole(ROLE_ADD_FT) {
        require(_added[id].added == false, "Token already added.");

        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);

        emit TransferSingle(_msgSender(), address(0), address(0), id, 0);
    }

    function modifyFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public requireRole(ROLE_MODIFY_FT) {
        require(_added[id].added == true, "Token not added.");

        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
    }

    function mintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_MINT_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canMint, "Token cannot be minted.");
        require(
            supplyLimit(tokenID) == 0 ||
                (_minted[tokenID] + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _mint(to, tokenID, quantity, "");
        _minted[tokenID] += quantity;
    }

    function mintNFT(
        address to,
        uint256 tokenID
    ) public requireRole(ROLE_MINT_NFT) {
        require(!_isFungible(tokenID), "Token is fungible.");
        require(_minted[tokenID] == 0, "Token is already minted.");

        _minted[tokenID]++;
        _mint(to, tokenID, 1, "");
    }

    function batchMintNFT(
        address to,
        uint256[] calldata ids
    ) public requireRole(ROLE_BATCH_MINT_NFT) {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(!_isFungible(id), "Token is fungible.");
            require(_minted[id] == 0, "Token is already minted.");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            _minted[id]++;
            _mint(to, id, 1, "");
        }
    }

    function burnFT(
        address owner,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_BURN_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canBurn, "Token cannot be burned.");

        _burn(owner, tokenID, quantity);
    }

    function burnNFT(
        address owner,
        uint256 tokenID
    ) public requireRole(ROLE_BURN_NFT) {
        require(!_isFungible(tokenID), "Token is fungible.");
        require(_minted[tokenID] == 1, "Token is not minted.");

        _burned[tokenID]++;
        _burn(owner, tokenID, 1);
    }

    function batchBurnNFT(
        address owner,
        uint256[] calldata ids
    ) public requireRole(ROLE_BATCH_BURN_NFT) {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(!_isFungible(id), "Token is fungible.");
            require(_minted[id] == 1, "Token is not minted.");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            _burned[id]++;
            _burn(owner, id, 1);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155) {
        if (paused()) {
            if (!_hasRole(_msgSender(), ROLE_BYPASS_PAUSE)) {
                revert("Token is paused");
            }
        }

        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155) {
        if (paused()) {
            if (!_hasRole(_msgSender(), ROLE_BYPASS_PAUSE)) {
                revert("Token is paused");
            }
        }

        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(
        uint256 id
    ) public requireRole(ROLE_REFRESH_METADATA) {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public requireRole(ROLE_REFRESH_METADATA) {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setRole(address operator, uint16 mask) public onlyOwner {
        _setRole(operator, mask);
    }

    function hasRole(address operator, uint16 role) public view returns (bool) {
        return _hasRole(operator, role);
    }

    function _repeat(
        uint256 value,
        uint256 length
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = value;
        }

        return array;
    }
}