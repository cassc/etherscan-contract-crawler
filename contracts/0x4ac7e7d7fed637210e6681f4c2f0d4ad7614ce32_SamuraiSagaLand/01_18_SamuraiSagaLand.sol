// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/MinterAccess.sol";
import "./libraries/Recoverable.sol";

/**
 * @title SamuraiSagaLand
 * @notice SamuraiSagaLand ERC721 NFT collection
 * https://www.samuraisaga.com
 */
contract SamuraiSagaLand is Ownable, ERC721, MinterAccess, Recoverable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bool public isMetadataLocked;

    uint256 public immutable maxSupply;
    Counters.Counter private _totalSupply;

    address public transferOperator;
    string public baseURI;

    event TransferOperatorUpdated(address indexed operator);
    event LockMetadata();

    /**
     * @notice Constructor
     * @param maxSupply_: NFT max totalSupply
     */
    constructor(uint256 maxSupply_) ERC721("Samurai Saga Land", "SSL") {
        maxSupply = maxSupply_;
    }

    /**
     * @dev Returns the current supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    /**
     * @notice Allows a member of the minters group to mint a token to a specific address
     * @param to: address to receive the token
     * @param tokenId: tokenId
     * @dev Callable by minters
     */
    function mint(address to, uint256 tokenId) external onlyMinters {
        require(_totalSupply.current() < maxSupply, "NFT: Total supply reached");
        _totalSupply.increment();
        _mint(to, tokenId);
    }

    /**
     * @notice Allows a member of the minters group to mint a batch of tokens to a specific address
     * @param to: address to receive the token
     * @param tokenIds: the list of tokenId to mint
     * @dev Callable by minters
     */
    function mintBatch(address to, uint256[] calldata tokenIds) external onlyMinters {
        require(_totalSupply.current() < maxSupply, "NFT: Total supply reached");
        require(_totalSupply.current() + tokenIds.length <= maxSupply, "NFT: Not enough supply");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _totalSupply.increment();
            _mint(to, tokenIds[i]);
        }
    }

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Operations: Contract is locked");
        require(bytes(baseURI).length > 0, "Operations: BaseUri not set");
        isMetadataLocked = true;
        emit LockMetadata();
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isMetadataLocked, "Operations: Contract is locked");
        baseURI = _uri;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev update the `transferOperator` account.
     */
    function setTransferOperator(address operator) external onlyOwner {
        require(operator != transferOperator, "Already set");
        transferOperator = operator;
        emit TransferOperatorUpdated(operator);
    }

    /**
     * @dev _transfers are only allowed when operated by `transferOperator`
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require((transferOperator != address(0) && _msgSender() == transferOperator), "Transfer are not enabled");
        super._transfer(from, to, tokenId);
    }
}