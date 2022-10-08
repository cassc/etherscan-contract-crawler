// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../erc1238/ERC1238.sol";
import "../../erc1238/extensions/ERC1238URIStorage.sol";

import "./IOath.sol";

contract Oath is ERC1238, IOath, AccessControlEnumerable, ERC1238URIStorage, Pausable {
    using Address for address;

    bytes32 public constant override MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant override PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant override TOTAL_MAX_PER_ADDRESS = 1;
    uint256 public constant override MAX_FACTION_ID = 5;

    // Wallet => Sum balanceOf(all token type ids)
    mapping(address => uint256) public override totalBalanceOf;
    // Token Type Id => Total Supply
    mapping(uint256 => uint256) public override totalSupplyOf;

    constructor(
        address adminAddress,
        address minterAddress,
        address pauserAddress,
        string memory baseURIValue
    ) ERC1238(baseURIValue) {
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);

        // Admin and minter are set up in super constructor.
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(MINTER_ROLE, minterAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);
    }

    function setBaseURI(string calldata newBaseURI) external override {
        require(hasRole(PAUSER_ROLE, _msgSender()), "!access_account");
        string memory oldBaseURI = _baseURI();
        _setBaseURI(newBaseURI);
        emit BaseURIUpdated(oldBaseURI, newBaseURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1238, AccessControlEnumerable, ERC1238URIStorage, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IOath).interfaceId ||
            ERC1238URIStorage.supportsInterface(interfaceId) ||
            ERC1238.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 id,
        bytes memory data
    ) external override {
        require(to != address(0x0), "!to");
        require(hasRole(MINTER_ROLE, _msgSender()), "!access_account");
        require(id > 0 && id <= MAX_FACTION_ID, "!id");
        require(totalBalanceOf[to] < TOTAL_MAX_PER_ADDRESS, "!max_balance_reached_out");

        uint256 amount = TOTAL_MAX_PER_ADDRESS;
        totalBalanceOf[to] = totalBalanceOf[to] + amount;
        totalSupplyOf[id] = totalSupplyOf[id] + amount;
        _mint(to, id, amount, data);

        if (to.isContract()) {
            _doSafeMintAcceptanceCheck(_msgSender(), to, id, amount, data);
        }
    }

    function burn(uint256 id) external override {
        address msgSender = _msgSender();
        uint256 amount = TOTAL_MAX_PER_ADDRESS;
        require(totalBalanceOf[msgSender] >= amount, "!balance");
        totalBalanceOf[msgSender] = totalBalanceOf[msgSender] - amount;
        totalSupplyOf[id] = totalSupplyOf[id] - amount;
        _burn(msgSender, id, amount);
    }

    /**
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory uri = _tokenURIs[id];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return
            bytes(uri).length > 0
                ? string(abi.encodePacked(_baseURI(), uri))
                : string(abi.encodePacked(_baseURI(), Strings.toString(id)));
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "!access_account");
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external override {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Oath: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external override {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Oath: must have pauser role to unpause");
        _unpause();
    }

    function totalSupply() external view override returns (uint256 total) {
        for (uint256 typeId = 1; typeId <= MAX_FACTION_ID; typeId++) {
            total = total + totalSupplyOf[typeId];
        }
    }

    /** Internal Functions */

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeMint(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._beforeMint(minter, to, id, amount, data);

        require(!paused(), "Oath: token transfer while paused");
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `burner` and `from` cannot be the zero address
     *
     */
    function _beforeBurn(
        address burner,
        address from,
        uint256 id,
        uint256 amount
    ) internal override {
        super._beforeBurn(burner, from, id, amount);

        require(!paused(), "Oath: token transfer while paused");
    }

    /** Events */
}