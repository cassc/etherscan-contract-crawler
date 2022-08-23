// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IWithBalance.sol"; // needed for auction, see usage in NFTAuction.sol (hasWhitelistedToken)
import "ERC1155.sol";
import "Ownable.sol";

contract MultipleCollectionMH is IWithBalance, ERC1155, Ownable {
    string public name;
    string public symbol;

    bool internal isLockedURI;

    uint256 public tokensTypes;

    // Mapping owner address to token count
    mapping(address => uint256) private _totalBalances;
    //for ERC1155Supply
    mapping(uint256 => uint256) private _totalSupply;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, address receiver_,
                uint256[] memory tokensCounts_) ERC1155(baseURI_) {
        name = name_;
        symbol = symbol_;

        tokensTypes = tokensCounts_.length;

        uint256[] memory ids = new uint256[](tokensTypes);

        for (uint256 i = 0; i < tokensTypes; i++) {
            uint256 tokenId = i + 1;
            ids[i] = tokenId;
            _totalSupply[tokenId] = tokensCounts_[i];
            _totalBalances[receiver_] += tokensCounts_[i];
        }

        _mintBatch(receiver_, ids, tokensCounts_, "");
    }

    // Total amount of tokens in with a given id
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    // Total amount of tokens
    function totalSupply() public view virtual returns (uint256) {
        uint256 supply = 0;

        for (uint256 id = 1; id <= tokensTypes; id++) {
            supply += _totalSupply[id];
        }

        return supply;
    }

    // Indicates whether any token exist with a given id, or not
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    // Lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner external
    {
        require(!isLockedURI, "URI change has been locked");
        _setURI(newBaseURI);
    }

    // total balance
    function balanceOf(address owner) external view returns (uint256) {
        return _totalBalances[owner];
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) return; // minting already handled

        uint256 tokensToTransfer;
        for(uint256 i = 0; i < amounts.length; i++) tokensToTransfer += amounts[i];

        _totalBalances[from] -= tokensToTransfer;
        if (to != address(0)) _totalBalances[to] += tokensToTransfer;
    }
}