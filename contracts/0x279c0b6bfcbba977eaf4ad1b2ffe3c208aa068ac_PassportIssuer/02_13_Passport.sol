// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ERC721, ERC721TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Controlled} from "../utils/Controlled.sol";
import {Renderer} from "./render/Renderer.sol";

/// @notice Non-fungible, limited-transferable token that grants citizen status in Nation3.
/// @author Nation3 (https://github.com/nation3/app/blob/main/contracts/contracts/passport/Passport.sol).
/// @dev Most ERC721 operations are restricted to controller contract.
/// @dev Is modified from the EIP-721 because of the lack of enough integration of the EIP-4973 at the moment of development.
/// @dev Token metadata is renderer on-chain through an external contract.
contract Passport is ERC721, Controlled {
    /*///////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotMinted();
    error NotAuthorized();
    error InvalidFrom();
    error NotSafeRecipient();

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    // @notice On-chain metadata renderer.
    Renderer public renderer;

    /// @dev Tracks the number of tokens minted & not burned.
    uint256 internal _supply;
    /// @dev Tracks the next id to mint.
    uint256 internal _idTracker;

    // @dev Timestamp of each token mint.
    mapping(uint256 => uint256) internal _timestampOf;
    // @dev Authorized address to sign messages in behalf of the passport holder, it can be different from the owner.
    // @dev Could be used for IRL events authentication.
    mapping(uint256 => address) internal _signerOf;

    /*///////////////////////////////////////////////////////////////
                            VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total number of tokens in supply.
    function totalSupply() external view virtual returns (uint256) {
        return _supply;
    }

    /// @notice Gets next id to mint.
    function getNextId() external view virtual returns (uint256) {
        return _idTracker;
    }

    /// @notice Returns the timestamp of the mint of a token.
    /// @param id Token to retrieve timestamp from.
    function timestampOf(uint256 id) public view virtual returns (uint256) {
        if (_ownerOf[id] == address(0)) revert NotMinted();
        return _timestampOf[id];
    }

    /// @notice Returns the authorized signer of a token.
    /// @param id Token to retrieve signer from.
    function signerOf(uint256 id) external view virtual returns (address) {
        if (_ownerOf[id] == address(0)) revert NotMinted();
        return _signerOf[id];
    }

    /// @notice Get encoded metadata from renderer.
    /// @param id Token to retrieve metadata from.
    function tokenURI(uint256 id) public view override returns (string memory) {
        return renderer.render(id, ownerOf(id), timestampOf(id));
    }

    /*///////////////////////////////////////////////////////////////
                           CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets name & symbol.
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    /*///////////////////////////////////////////////////////////////
                       USER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the owner of a passport to update the signer.
    /// @param id Token to update the signer.
    /// @param signer Address of the new signer account.
    function setSigner(uint256 id, address signer) external virtual {
        if (_ownerOf[id] != msg.sender) revert NotAuthorized();
        _signerOf[id] = signer;
    }

    /*///////////////////////////////////////////////////////////////
                       CONTROLLED ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC721 method to set allowance. Only allowed to controller.
    /// @dev Prevent approvals on marketplaces & other contracts.
    function approve(address spender, uint256 id) public override onlyController {
        getApproved[id] = spender;

        emit Approval(_ownerOf[id], spender, id);
    }

    /// @notice ERC721 method to set allowance. Only allowed to controller.
    /// @dev Prevent approvals on marketplaces & other contracts.
    function setApprovalForAll(address operator, bool approved) public override onlyController {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Allows controller to transfer a passport (id) between two addresses.
    /// @param from Current owner of the token.
    /// @param to Recipient of the token.
    /// @param id Token to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyController {
        if (from != _ownerOf[id]) revert InvalidFrom();
        if (to == address(0)) revert TargetIsZeroAddress();

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        _timestampOf[id] = block.timestamp;
        _signerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    /// @notice Allows controller to safe transfer a passport (id) between two address.
    /// @param from Curent owner of the token.
    /// @param to Recipient of the token.
    /// @param id Token to transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyController {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NotSafeRecipient();
    }

    /// @notice Allows controller to safe transfer a passport (id) between two address.
    /// @param from Curent owner of the token.
    /// @param to Recipient of the token.
    /// @param id Token to transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override onlyController {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NotSafeRecipient();
    }

    /// @notice Mints a new passport to the recipient.
    /// @param to Token recipient.
    /// @dev Id is auto assigned.
    function mint(address to) external virtual onlyController returns (uint256 tokenId) {
        tokenId = _idTracker;
        _mint(to, tokenId);

        // Realistically won't overflow;
        unchecked {
            _timestampOf[tokenId] = block.timestamp;
            _signerOf[tokenId] = to;
            _idTracker++;
            _supply++;
        }
    }

    /// @notice Mints a new passport to the recipient.
    /// @param to Token recipient.
    /// @dev Id is auto assigned.
    function safeMint(address to) external virtual onlyController returns (uint256 tokenId) {
        tokenId = _idTracker;
        _safeMint(to, tokenId);

        // Realistically won't overflow;
        unchecked {
            _timestampOf[tokenId] = block.timestamp;
            _signerOf[tokenId] = to;
            _idTracker++;
            _supply++;
        }
    }

    /// @notice Burns the specified token.
    /// @param id Token to burn.
    function burn(uint256 id) external virtual onlyController {
        _burn(id);

        // Would have reverted before if the token wasnt minted
        unchecked {
            delete _timestampOf[id];
            delete _signerOf[id];
            _supply--;
        }
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the owner to update the renderer contract.
    /// @param _renderer New renderer address.
    function setRenderer(Renderer _renderer) external virtual onlyOwner {
        renderer = _renderer;
    }

    /// @notice Allows the owner to withdraw any ERC20 sent to the contract.
    /// @param token Token to withdraw.
    /// @param to Recipient address of the tokens.
    function recoverTokens(ERC20 token, address to) external virtual onlyOwner returns (uint256 amount) {
        amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
    }
}