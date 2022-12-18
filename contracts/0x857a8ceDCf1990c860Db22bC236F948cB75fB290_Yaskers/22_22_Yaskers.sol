// contracts/IconsForNewAge.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721Tradable.sol";

contract Yaskers is ERC721Tradable {
    string private _contractUri;
    string private _baseTokenUri;
    uint256 private _maxSupply;
    uint256 private _price;
    address private _master;

    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs.
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    Counters.Counter private _nextTokenId;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMaster() {
        require(_master == _msgSender(), "Caller is not master");
        _;
    }

    constructor(
        address _proxyRegistryAddress,
        address masterAddress,
        uint96 feeNumerator,
        uint256 _mintPrice,
        string memory baseTokenUri,
        string memory contractUri
    ) ERC721Tradable("Yaskers", "YSKRS", _proxyRegistryAddress) {
        // Set the master address
        _master = masterAddress;
        // Set the fee recipient to the master address
        _setDefaultRoyalty(_master, feeNumerator);

        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _contractUri = contractUri;
        _baseTokenUri = baseTokenUri;

        // Set the price
        _price = _mintPrice;
    }

    function master() public view returns (address) {
        return _master;
    }

    function withdraw() public onlyMaster {
        payable(_master).transfer(address(this).balance);
    }

    /**
     * @dev Mints a token to an address.
     */
    function mint() external payable {
        address _to = _msgSender();

        require(
            _nextTokenId.current() <= _maxSupply,
            "No more tokens left to mint"
        );
        require(msg.value >= _price, "Not sufficient funds");
        require(_to != address(0), "Cannot mint to address 0");

        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /**
     * @dev Mints a sequence of tokens to an address.
     */
    function batchMint(uint256 count) external payable {
        address _to = _msgSender();

        require(count > 0, "Count must be greater than 0");
        require(
            _nextTokenId.current() - 1 + count <= _maxSupply,
            "No more tokens left to mint"
        );
        require(msg.value >= _price * count, "Not sufficient funds");
        require(_to != address(0), "Cannot mint to address 0");

        for (uint256 i = 0; i < count; ++i) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(_to, currentTokenId);
        }
    }

    /**
     * @dev Returns the total tokens minted so far.
     * 1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function availableSupply() public view returns (uint256) {
        // 1 is always subtracted from the Counter since it tracks the next available tokenId.
        return _maxSupply - (_nextTokenId.current() - 1);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        _maxSupply = supply;
    }

    function mintPrice() public view returns (uint256) {
        return _price;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setContractURI(string memory contractUri) public onlyOwner {
        _contractUri = contractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseTokenURI(string memory baseTokenUri) public onlyOwner {
        _baseTokenUri = baseTokenUri;
    }

    function baseTokenURI() public view override returns (string memory) {
        return _baseTokenUri;
    }

    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 curr = 0;
            for (uint256 i = 0; i < totalSupply(); i++) {
                if (ownerOf(i + 1) == owner) {
                    result[curr] = i + 1;
                    curr++;
                }
            }

            return result;
        }
    }

    function tokenOwners() public view returns (address[] memory) {
        uint256 tokenCount = totalSupply();
        address[] memory result = new address[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            address owner = ownerOf(i + 1);
            result[i] = owner;
        }

        return result;
    }
}