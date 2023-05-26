// SPDX-License-Identifier: GPL-3.0
// LICENSE
// This is a modified version of the original code from the
// NounsToken.sol— an implementation of OpenZeppelin's ERC-721:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsToken.sol
// The original code is licensed under the GPL-3.0 license
// Thank you to the Nouns team for the inspiration and code!

pragma solidity ^0.8.6;

import "./IERC721.sol";
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";
import {Ownable} from "./Ownable.sol";
import {ERC721} from "./ERC721.sol";
import {IERC721} from "./IERC721.sol";
import {Strings} from "./Strings.sol";
import {WildNFT} from "./WildNFT.sol";
import {Base64} from "./Base64.sol";
import {Math} from "./Math.sol";

interface IWildNFT is IERC721 {
    event TokenCreated(uint256 indexed tokenId, address mintedTo);

    event TokenBurned(uint256 indexed tokenId);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function mint(address _to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function setBaseURI(string memory _newBaseURI) external;

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

abstract contract WildNFT is
    IWildNFT,
    Ownable,
    RevokableDefaultOperatorFilterer,
    ERC721
{
    // An address who has permissions to mint qf tokens
    address public minter;

    // Mapping of operators to whether they are approved or not
    mapping(address => bool) public authorized;

    // Mapping of addresses flagged for denying token interactions
    mapping(address => bool) public blockList;

    // The internal ID tracker
    uint256 public _currentTokenId;

    uint256 public maxSupply;

    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        address _minter,
        uint256 _maxSupply
    ) ERC721(name_, symbol_) {
        minter = _minter;
        maxSupply = _maxSupply;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    /**
     * @notice updates the deny list
     * @param flaggedOperator the address to be added to the deny list
     * @param status whether the address is to be added or removed from the deny list
     */
    function updateDenyList(address flaggedOperator, bool status)
        public
        onlyOwner
    {
        _updateDenyList(flaggedOperator, status);
    }

    /*
     * @notice Override isApprovedForAll
     * @param owner The owner of the Nouns
     * @param operator The operator to check if approved
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(IERC721, ERC721)
        returns (bool)
    {
        require(
            blockList[operator] == false,
            "Operator has been denied by contract owner."
        );

        if (authorized[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }

    /* OS */
    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721, ERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(IERC721, ERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @notice sets the authorized operators for interacting with the contract
     * @param operator the address to be added to the authorized operators
     * @param approved whether the address is approved or not within authorized operators
     */
    function setAuthorized(address operator, bool approved) public onlyOwner {
        authorized[operator] = approved;
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     * @param _minter The address of the new minter.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /**
     * @notice updates the deny list
     * @param flaggedOperator The address to be approved.
     * @param status True if the operator is approved, false to revoke approval.
     */
    function _updateDenyList(address flaggedOperator, bool status)
        internal
        virtual
    {
        blockList[flaggedOperator] = status;
    }

    /**
     * @notice Mint a token to the given address.
     * @dev Only callable by the minter.
     * @param _to The address to mint the qf token to.
     * @return The ID of the newly minted qf token.
     */
    function mint(address _to) public override onlyMinter returns (uint256) {
        require(_currentTokenId < maxSupply, "Max supply reached");
        return _mintTo(_to, _currentTokenId++);
    }

    /**
     * @notice Burn a pass.
     * @dev Only callable by the minter.
     * @param tokenId The ID of the qf token to burn.
     */
    function burn(uint256 tokenId) public override onlyMinter {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /**
     * @notice Set the base URI.
     * @dev Only callable by the owner.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    /** @notice Mints a new token
     * @param to: the address of the new owner looking to mint
     * @param tokenId: the token ID
     * @return the ID of the newly minted token
     */
    function _mintTo(address to, uint256 tokenId) internal returns (uint256) {
        _mint(to, tokenId);
        emit TokenCreated(tokenId, to);

        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }
}