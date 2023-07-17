//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./util/ERC1155Pausable.sol";
import "./util/ERC1155.sol";
import "./AniftyERC20.sol";

contract AniftyERC1155 is AccessControl, ERC1155Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _adminTokenIds;
    Counters.Counter private _tokenIds;

    // Mapping of whitelisted addresses, addresses include lootbox contracts
    mapping(address => bool) public whitelist;
    mapping (uint256 => address) public creators;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event TokenERC1155Mint(
        address account,
        uint256 id,
        uint256 amount,
        uint256 timestamp,
        string name,
        string creatorName,
        string description,
        string mediaUri
    );
    event TokenERC1155MintBatch(
        address to,
        uint256[] ids,
        uint256[] amounts,
        uint256 timestamp,
        string[] name,
        string[] creatorName,
        string[] description,
        string[] mediaUri
    );

    constructor(address _admin,
        string memory _uri)
        public
        ERC1155(_uri)
    {
        _tokenIds._value = 1000000;
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
    }

    modifier onlyWhitelist() {
        require(
            whitelist[msg.sender] == true,
            "Caller is not from a whitelist address"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Caller must be admin"
        );
        _;
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AniftyERC1155: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AniftyERC1155: must have pauser role to unpause"
        );
        _unpause();
    }

    function mint(
        uint256 amount,
        string memory name,
        string memory creatorName,
        string memory description,
        string memory mediaUri,
        bytes calldata data
    ) external whenNotPaused returns(uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        creators[tokenId] = msg.sender;
        _mint(msg.sender, tokenId, amount, data);
        emit TokenERC1155Mint(
            msg.sender,
            tokenId,
            amount,
            block.timestamp,
            name,
            creatorName,
            description,
            mediaUri
        );
        return tokenId;
    }

    function mintBatch(
        uint256[] memory amounts,
        string[] memory names,
        string[] memory creatorNames,
        string[] memory descriptions,
        string[] memory mediaUris,
        bytes calldata data
    ) external whenNotPaused returns(uint256[] memory) {
        require(amounts.length == names.length && amounts.length == creatorNames.length && amounts.length == descriptions.length && amounts.length == mediaUris.length, "AniftyERC1155: Incorrect parameter length");
        uint256[] memory tokenIds = new uint256[](amounts.length);
        for (uint256 j = 0; j < amounts.length; j++) {
            _tokenIds.increment();
            tokenIds[j] = _tokenIds.current();
            creators[tokenIds[j]] = msg.sender;
        }
        _mintBatch(msg.sender, tokenIds, amounts, data);
        emit TokenERC1155MintBatch(
            msg.sender,
            tokenIds,
            amounts,
            block.timestamp,
            names,
            creatorNames,
            descriptions,
            mediaUris
        );
        return tokenIds;
    }

    function whitelistMint(
        uint256 amount,
        string memory name,
        string memory creatorName,
        string memory description,
        string memory mediaUri,
        bytes calldata data
    ) external whenNotPaused onlyWhitelist returns(uint256) {
        _adminTokenIds.increment();
        uint256 tokenId = _adminTokenIds.current();
        creators[tokenId] = msg.sender;
        _mint(msg.sender, tokenId, amount, data);
        emit TokenERC1155Mint(
            msg.sender,
            tokenId,
            amount,
            block.timestamp,
            name,
            creatorName,
            description,
            mediaUri
        );
        return tokenId;
    }

    function whitelistMintBatch(
        uint256[] memory amounts,
        string[] memory names,
        string[] memory creatorNames,
        string[] memory descriptions,
        string[] memory mediaUris,
        bytes calldata data
    ) external whenNotPaused onlyWhitelist returns(uint256[] memory) {
        require(amounts.length == names.length && amounts.length == creatorNames.length && amounts.length == descriptions.length && amounts.length == mediaUris.length, "AniftyERC1155: Incorrect parameter length");
        uint256[] memory tokenIds = new uint256[](amounts.length);
        for (uint256 j = 0; j < amounts.length; j++) {
            _adminTokenIds.increment();
            tokenIds[j] = _adminTokenIds.current();
            creators[tokenIds[j]] = msg.sender;
        }
        _mintBatch(msg.sender, tokenIds, amounts, data);
        emit TokenERC1155MintBatch(
            msg.sender,
            tokenIds,
            amounts,
            block.timestamp,
            names,
            creatorNames,
            descriptions,
            mediaUris
        );
        return tokenIds;
    }

    function burn(uint256 _id, uint256 _amount) external whenNotPaused {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts) external whenNotPaused {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function setURI(string memory newuri) external onlyAdmin {
        _setURI(newuri);
    }

    function removeWhitelistAddress(address[] memory _whitelistAddresses)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelist[_whitelistAddresses[i]] = false;
        }
    }

    function addWhitelistAddress(address[] memory _whitelistAddresses)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelist[_whitelistAddresses[i]] = true;
        }
    }
}