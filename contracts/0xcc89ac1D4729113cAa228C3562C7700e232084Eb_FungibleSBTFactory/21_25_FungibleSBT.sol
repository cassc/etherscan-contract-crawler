// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IFungibleSBT.sol";
import "./libs/TokenUriSupplier.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FungibleSBT is
    IFungibleSBT,
    ERC1155,
    Ownable,
    AccessControl,
    TokenUriSupplier
{
    using Strings for uint256;

    // ==================================================
    // Constants
    // ==================================================
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant MINTER = "MINTER";

    // ==================================================
    // Variables
    // ==================================================
    uint256 public nextId = 1;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    string public contractURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseContractURI,
        address _owner,
        address _minter,
        address _ope
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;

        contractURI = string(
            abi.encodePacked(
                _baseContractURI,
                Strings.toHexString(address(this)),
                "/collection.json"
            )
        );

        baseURI = string(
            abi.encodePacked(
                _baseContractURI,
                Strings.toHexString(address(this)),
                "/metadata/"
            )
        );

        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER, ADMIN);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _ope);
        
        _grantRole(ADMIN, _owner);
        _grantRole(ADMIN, _ope);
        
        _grantRole(MINTER, _minter);
        
        _transferOwnership(_owner);
    }

    // ==================================================
    // For contract-level metadata
    // ==================================================
    function setContractURI(string memory value) external onlyRole(ADMIN) {
        contractURI = value;
    }

    // ==================================================
    // For adding id
    // ==================================================
    function add() external onlyRole(MINTER) {
        nextId++;
    }

    function exists(uint256 id) public view returns (bool) {
        return id < nextId;
    }

    // ==================================================
    // For mint
    // ==================================================
    // external function
    function airdrop(address[] calldata to, uint256 id)
        external
        onlyRole(ADMIN)
    {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id);
        }
    }

    function mint(address to, uint256 id) external onlyRole(MINTER) {
        _mint(to, id);
    }

    // internal function
    modifier existId(uint256 id) {
        require(exists(id), "Not exist id.");
        _;
    }

    modifier notHave(address to, uint256 id) {
        require(balanceOf(to, id) == 0, "You are already have the token.");
        _;
    }

    function _mint(address to, uint256 id) private existId(id) notHave(to, id) {
        _mint(to, id, 1, "");
    }

    // ==================================================
    // For burn
    // ==================================================
    modifier onlyTokenOwner(uint256 id) {
        require(balanceOf(msg.sender, id) > 0, "You don't have the token.");
        _;
    }

    function burn(uint256 id) external onlyTokenOwner(id) {
        _burn(msg.sender, id, 1);
    }

    // ==================================================
    // interface
    // ==================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }

    // ==================================================================
    // For SBT
    // ==================================================================
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT, so this can not approve.");
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                from == address(0) || to == address(0),
                "This token is SBT, so this can not transfer."
            );
        }
    }

    // ==================================================================
    // override TokenUriSupplier
    // ==================================================================
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
    }

    function setBaseURI(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseExtension = _value;
    }

    function setExternalSupplier(address _value)
        external
        override
        onlyRole(ADMIN)
    {
        externalSupplier = ITokenUriSupplier(_value);
    }

    function owner()
        public
        view
        override(Ownable, IFungibleSBT)
        returns (address)
    {
        return Ownable.owner();
    }
}