// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './utils/Adminable.sol';

/**
 * @title NFT Smart Contract made by Artiffine
 * @author https://artiffine.com/
 */
contract SkodaNFT is ERC1155, Adminable {
    using Strings for uint256;

    uint256 public immutable MAX_ID;

    struct TokenInfo {
        uint256 maxSupply;
        uint256 totalSupply;
    }

    mapping(uint256 => TokenInfo) private _tokenInfo;
    string private _contractURI;

    error MaxSupplyReached(uint256 tokenId);
    error TokenIdDoesNotExist(uint256 tokenId);
    error ArgumentIsAddressZero();
    error ContractBalanceIsZero();

    /**
     * @param _tokenUri URI to tokens metadata, can be set up later.
     * @param _contractUri URI to the contract-metadata, can be set up later.
     * @param _maxId Maximum token id, settable only once.
     */
    constructor(string memory _tokenUri, string memory _contractUri, uint256 _maxId) ERC1155(_tokenUri) {
        require(_maxId != 0);
        MAX_ID = _maxId;
        _contractURI = _contractUri;
    }

    /* External Functions */

    /**
     * @notice Returns URI of contract-level metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Returns array of available supplies per token id.
     */
    function getAvailableSupplies() external view returns (uint256[] memory availableSupplies) {
        availableSupplies = new uint256[](MAX_ID);
        for (uint256 i = 0; i < MAX_ID; ++i) {
            TokenInfo memory tokenInfo = _tokenInfo[i];
            unchecked {
                availableSupplies[i] = tokenInfo.maxSupply - tokenInfo.totalSupply;
            }
        }
    }

    /**
     * @notice Returns total supply of given token id.
     *
     * @dev Returns zero for nonexisting token ids.
     *
     * @param _id Token id.
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _tokenInfo[_id].totalSupply;
    }

    /**
     * @notice Returns total supply of token id.
     */
    function getTotalSupplies() external view returns (uint256[] memory totalSupplies) {
        totalSupplies = new uint256[](MAX_ID);
        for (uint256 i = 0; i < MAX_ID; ++i) {
            TokenInfo memory tokenInfo = _tokenInfo[i];
            totalSupplies[i] = tokenInfo.totalSupply;
        }
    }

    /* External Admin Functions */

    /**
     * @notice Increase all supplies of all token ids.
     *
     * @param _increment Number by which to increment max supply.
     */
    function increaseSupplies(uint256 _increment) external onlyAdmin {
        for (uint256 i = 0; i < MAX_ID; ++i) {
            _tokenInfo[i].maxSupply += _increment;
        }
    }

    /**
     * @notice Increase supply of given token id.
     *
     * @param _id Token id.
     * @param _increment Number by which to increment max supply.
     */
    function increaseSupply(uint256 _id, uint256 _increment) external onlyAdmin {
        if (_id >= MAX_ID) revert TokenIdDoesNotExist(_id);
        _tokenInfo[_id].maxSupply += _increment;
    }

    /**
     * @notice Free mints one token id to specified address.
     *
     * @param _id Token id.
     * @param _to Address that will recieve minted NFT.
     */
    function mint(uint256 _id, address _to) external onlyAdmin {
        if (_id >= MAX_ID) revert TokenIdDoesNotExist(_id);
        TokenInfo storage tokenInfo = _tokenInfo[_id];
        if (tokenInfo.totalSupply == tokenInfo.maxSupply) revert MaxSupplyReached(_id);
        ++tokenInfo.totalSupply;
        _mint(_to, _id, 1, '');
    }

    /**
     * @notice Sets URI of contract-level metadata.
     *
     * @param _URI URI of contract-level metadata.
     */
    function setContractURI(string memory _URI) external onlyAdmin {
        _contractURI = _URI;
    }

    /**
     * @notice Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * @param _URI URI of token metadata.
     */
    function setTokenURI(string memory _URI) external onlyAdmin {
        _setURI(_URI);
    }

    /* External Owner Functions */

    /**
     * @notice Recovers ERC20 token back to the owner, callable only by the owner.
     *
     * @param _token IERC20 token address to recover.
     */
    function recoverToken(IERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert ArgumentIsAddressZero();
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) revert ContractBalanceIsZero();
        _token.transfer(owner(), balance);
    }
}