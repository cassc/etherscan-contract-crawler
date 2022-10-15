// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../../eip712/NativeMetaTransaction.sol";
import "../../eip712/ContextMixin.sol";
import "./ERC721APausable.sol";

contract Teaser is
ERC721A,
ERC721ABurnable,
ERC721AQueryable,
ERC721APausable,
AccessControl,
Ownable,
ContextMixin,
NativeMetaTransaction
{
    // Create a new role identifier for the pauser role
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;
    string private collectionURI;
    State public state;
    mapping(address => bool) minted;
    enum State {
        PRE,
        ALLOW,
        FINISH
    }
    event StateChange(State state);

    constructor() ERC721A("NRJJungleVIBES", "NRJJV") {
        _initializeEIP712("NRJJungleVIBES");
        baseTokenURI = "https://cdn.nftstar.com/neymar/junglevibes/metadata/";
        collectionURI = "https://cdn.nftstar.com/neymar/junglevibes/contract.json";
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSenderERC721A());
        _setupRole(PAUSER_ROLE, _msgSenderERC721A());
    }
    modifier isState(State _state) {
        require(state == _state, "Teaser: Wrong state for this action");
        _;
    }
    function mint() external isState(State.ALLOW){
        if(minted[_msgSenderERC721A()]){
            require(
                balanceOf(_msgSenderERC721A())==0,
                "TEASER:mint:Only one per address"
            );
        }else{
            minted[_msgSenderERC721A()] = true;
        }
        _safeMint(_msgSenderERC721A(), 1);
    }

    function mintTo(address to, uint256 quantity) external onlyRole(PAUSER_ROLE) {
        _safeMint(to, quantity);
    }
    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "TEASER: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "TEASER: must have pauser role to unpause"
        );
        _unpause();
    }

    function current() public view returns (uint256) {
        return _totalMinted();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function setContractURI(string memory _contractURI)
    external
    onlyRole(PAUSER_ROLE)
    {
        collectionURI = _contractURI;
    }
    function setState(State _state) external onlyRole(PAUSER_ROLE) {
        state = _state;
        emit StateChange(_state);
    }
    function isFinish() external view returns (bool){
        return state == State.FINISH;
    }
    function canMint(address addr) external view returns (uint8) {
        if(minted[addr]){
            return  balanceOf(addr)==0?1:0;
        }
        return 1;
    }
    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI)
    external
    onlyRole(PAUSER_ROLE)
    {
        baseTokenURI = _baseTokenURI;
    }

    function transferRoleAdmin(address newDefaultAdmin)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721A)
    returns (bool)
    {
        return
        super.supportsInterface(interfaceId) ||
        ERC721A.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _msgSenderERC721A()
    internal
    view
    virtual
    override
    returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}