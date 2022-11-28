// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./extensions/ERC721Enumerable.sol";
import "../../access/Ownable.sol";

error Forbidden();
error AllMinted();

contract BrainWasher is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public immutable maxSupply;
    uint256 private totalSupply_ = 0;
    string private baseURI;
    address private minter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        address _minter
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        maxSupply = _maxSupply;
        minter = _minter;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint() external {
        if (msg.sender != minter) revert Forbidden();
        if (totalSupply_ == maxSupply) revert AllMinted();
        _safeMint(msg.sender, ++totalSupply_);
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}