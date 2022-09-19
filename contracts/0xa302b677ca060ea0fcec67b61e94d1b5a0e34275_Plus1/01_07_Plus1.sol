// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
/// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
/// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
/// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
/// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
/// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
/// work with us: nervous.net
///                       __        _
///                      /\ \     /' \
///                      \_\ \___/\_, \
///                     /\___  __\/_/\ \
///                     \/__/\ \_/  \ \ \
///                         \ \_\    \ \_\
///                          \/_/     \/_/
///
/// @title  Plus1
/// @author Nervous
///         (work with us: nervous.net)
/// @notice Let owners of an original ERC-721 mint Plus1 versions.
/// The owned of the original has the ability to mint, transfer, and burn
/// Plus1 versions.
/// @dev    Intended to be used via a proxy. See Plus1Factory.
import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin/contracts/proxy/utils/Initializable.sol";
import "sol2string/LibUintToString.sol";
import "./ITokenOwner.sol";

contract Plus1 is ERC721, Initializable, Owned {
    using LibUintToString for uint256;

    error MintDisabled();
    error NotAuthorized();
    error InvalidFrom();
    error InvalidTo();

    string public _baseURI;
    ITokenOwner public original;
    bool public mintEnabled;

    constructor() Owned(address(0)) ERC721("", "") {}

    /// @notice Initializer
    /// @dev Initialize the contract. Can only be performed once.
    /// @param _owner          The owner that can perform administrative actions.
    /// @param _name           ERC721 name
    /// @param _symbol         ERC721 symbol
    /// @param _original       Address of the "original" token that determines mint/burn/transfer approval
    ///                        Must conform to ITokenOwner, meaning must have an ownerOf(tokenId) function.
    /// @param _initialBaseURI The initial base URI to be used in tokenURI function.
    ///                        Can be updated by owner.
    function init(
        address _owner,
        string memory _name,
        string memory _symbol,
        ITokenOwner _original,
        string memory _initialBaseURI
    ) external initializer {
        owner = _owner;
        name = _name;
        symbol = _symbol;
        original = _original;
        _baseURI = _initialBaseURI;
        mintEnabled = true;
    }

    ////////////////////////////////////////////////////////////////
    //              MINT, BURN, RECALL PLUS1 TOKENS
    ////////////////////////////////////////////////////////////////

    /// @notice Original token owner may mint a token
    /// @param id The tokenId to mint
    /// @param to The recipient of the mint
    function mint(uint256 id, address to) external {
        if (to == address(0)) {
            revert InvalidTo();
        }
        if (!mintEnabled) {
            revert MintDisabled();
        }
        if (original.ownerOf(id) != msg.sender) {
            revert NotAuthorized();
        }
        _mint(to, id);
    }

    /// @notice Original token owner may burn the token
    /// @param id The tokenId to burn
    function burn(uint256 id) external {
        if (original.ownerOf(id) != msg.sender) {
            revert NotAuthorized();
        }
        _burn(id);
    }

    ////////////////////////////////////////////////////////////////
    //                        ERC-721 OVERRIDES
    ////////////////////////////////////////////////////////////////

    /// @inheritdoc ERC721
    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string.concat(_baseURI, id.toString());
    }

    /// @notice Standard ERC-721 transferFrom (from solmate), with the
    ///         change that the original owner is a permitted msg.sender
    /// @inheritdoc ERC721
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (from != _ownerOf[id]) {
            revert InvalidFrom();
        }
        if (to == address(0)) {
            revert InvalidTo();
        }
        if (
            !(msg.sender == from ||
                msg.sender == original.ownerOf(id) ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id])
        ) {
            revert NotAuthorized();
        }
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    ////////////////////////////////////////////////////////////////
    //                        OWNER OPS
    ////////////////////////////////////////////////////////////////

    /// @notice Owner may update the base URI used in the tokenURI function
    /// @param newBaseURI The new base URI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    /// @notice Owner may enable or disable minting
    /// @param enabled Whether minting should be enabled
    function setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
    }
}