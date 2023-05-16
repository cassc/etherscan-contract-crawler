// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./base/NoDelegateCall.sol";
import "./interfaces/IGrittiMetathon.sol";
import "./interfaces/IGrittiMetathonFactory.sol";
import "./interfaces/IGrittiMetathonDeployer.sol";

contract GrittiMetathon is ERC721, ERC721Enumerable, NoDelegateCall, IGrittiMetathon {
    /// @inheritdoc IGrittiMetathon
    address public immutable override factory;

    /// @inheritdoc IGrittiMetathon
    uint256 public override maxSupply;

    /// @inheritdoc IGrittiMetathon
    string public override eventSlug;
    /// @inheritdoc IGrittiMetathon
    string public override eventName;
    /// @inheritdoc IGrittiMetathon
    string public override rootHash;

    string private _name;
    string private _symbol;

    /// @inheritdoc IGrittiMetathon
    string public baseURI;

    // Mapping from token ID to minter address
    mapping(uint256 => address) private _minters;

    // Mapping minter address to token ids
    mapping(address => uint256[]) private _minterTokenIds;

    /// @dev Prevents calling a function from anyone except the address returned by IGrittiMetathonFactory#owner()
    modifier onlyFactoryOwner() {
        require(msg.sender == IGrittiMetathonFactory(factory).owner(), "caller is not the factory owner");
        _;
    }

    constructor() ERC721("", "") {
        (factory, eventSlug, maxSupply, eventName, rootHash, _name, _symbol, baseURI) = IGrittiMetathonDeployer(
            msg.sender
        ).parameters();

        require(factory != address(0), "Invalid factory");
        require(!isEmpty(eventSlug), "Invalid eventSlug");
        require(!isEmpty(eventName), "Invalid eventName");
        require(maxSupply > 0, "Invalid maxSupply");
        require(!isEmpty(rootHash), "Invalid rootHash");
        require(!isEmpty(_name), "Invalid name");
        require(!isEmpty(_symbol), "Invalid symbol");
        require(!isEmpty(baseURI), "Invalid baseURI");
    }

    /// @inheritdoc IGrittiMetathon
    function minterOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _minters[tokenId];
        require(owner != address(0), "invalid token ID");
        return owner;
    }

    /// @inheritdoc IGrittiMetathon
    function countOfMinter(address minter) public view virtual override returns (uint256) {
        require(minter != address(0), "address zero is not a valid minter");
        return _minterTokenIds[minter].length;
    }

    /// @inheritdoc IGrittiMetathon
    function tokenOfMinterByIndex(address minter, uint256 index) public view virtual override returns (uint256) {
        require(index < countOfMinter(minter), "minter index out of bounds");
        return _minterTokenIds[minter][index];
    }

    /**
     * @dev Mint Metathon NFT
     */
    function mint(address to, uint256 tokenId) public onlyFactoryOwner {
        require(maxSupply > totalSupply(), "Purchase would exceed max supply");
        _safeMint(to, tokenId);
        _minters[tokenId] = to;
        _minterTokenIds[to].push(tokenId);
    }

    receive() external payable {}

    function withdraw() public payable onlyFactoryOwner {
        require(address(this).balance > 0, "balance is not enough");
        payable(msg.sender).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function name() public view virtual override(ERC721, IGrittiMetathon) returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override(ERC721, IGrittiMetathon) returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, IGrittiMetathon) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
}