// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @title Republik DAO Heritage Collection NFT.
contract RepublikDao is ERC721, ERC2981, DefaultOperatorFilterer {
    /// @notice nft ipfs base uri.
    /// @dev this will be concatenated with the token id when calling tokenURI().
    string private _baseUri;

    /// @notice nft max supply.
    uint256 private _maxSupply = 1000;

    /// @notice the contract owner. will grant the authority to withdraw contract ETH balance.
    address payable private _owner;

    /// @notice nft token id tracker.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    /// @notice contract ETH balance.
    uint256 private _contractBalance;

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "RepublikDao : only owner can call this function"
        );
        _;
    }

    modifier onlyNotCapped() {
        require(
            _tokenIdTracker.current() < _maxSupply,
            "RepublikDao : nft max supply reached "
        );
        _;
    }

    modifier onlyFeeIsCorrect() {
        require(msg.value == 0.1 ether, "RepublikDao : incorrect fee");
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address contractOwner
    ) ERC721(name, symbol) {
        _baseUri = uri;
        _owner = payable(contractOwner);

        /// @dev default royalty set to 1000 because the fee denominator is 10000.
        /// this will make the default royalty of the contract to be 10% of sale price.
        /// see {ERC2981-_feeDenominator}
        uint96 defaultRoyalty = 1000;

        _setDefaultRoyalty(contractOwner, defaultRoyalty);
    }

    /// @notice internal function used to get nft base uri.
    /// @dev override the function so that we can assign the base uri at deployment.
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice internal function used to increment contract balance.
    /// should only be called when minting.
    /// @param value user mint fee
    function _incrementBalance(uint256 value) internal {
        _contractBalance += value;
    }

    /// @notice internal function used to reset the contract balance.
    /// should only be called when withdrawing.
    function _resetBalance() internal {
        _contractBalance = 0;
    }

    /// @notice function to withdraw user mint fee that is stored on the contract.
    /// @dev will transfer the all the contract ETH to the owner and reset it's balance to 0.
    function withdraw() external onlyOwner {
        _owner.transfer(_contractBalance);
        _resetBalance();
    }

    /// @notice mint nft
    /// @dev can only be called when the token id is not over the max supply and has the correct user fee(0.1 ETH).
    /// @param to address to mint the nft.
    function mint(address to) external payable onlyNotCapped onlyFeeIsCorrect {
        _incrementBalance(msg.value);
        _tokenIdTracker.increment();
        _safeMint(to, _tokenIdTracker.current());
    }

    /// @notice utility function to get max supply.
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /// @notice utility function to get the contract owner.
    function owner() external view returns (address) {
        return _owner;
    }

    /// @notice utility function to get the total nft minted.
    function hasMinted() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /// @notice utility function to get the contract balance.
    function contractBalance() external view returns (uint256) {
        return _contractBalance;
    }

    /// @notice function to change contract owner.
    /// can only be called by the contract owner.
    /// @param newOwner the new owner address.
    function changeOwner(address newOwner) external onlyOwner {
        _owner = payable(newOwner);
    }

    /// @dev Default fallback payable function.
    fallback() external payable {
        revert();
    }

    /// @dev Default payable function to not allow sending to contract
    ///  Remember this does not necessarily prevent the contract
    ///  from accumulating funds.
    receive() external payable {
        revert();
    }
}