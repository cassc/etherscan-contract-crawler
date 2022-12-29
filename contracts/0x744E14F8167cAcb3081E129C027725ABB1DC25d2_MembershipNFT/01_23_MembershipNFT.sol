pragma solidity ^0.8.17;

import "ERC721Votes.sol";
import "ERC721Burnable.sol";
import "EIP712.sol";
import "ERC721.sol";
import "Ownable.sol";
import "ERC2981.sol";


contract MembershipNFT is ERC721, ERC2981, Ownable, EIP712, ERC721Votes, ERC721Burnable {
    uint256 constant public MAX_SUPPLY = 10000;
    uint256 constant public MAX_PUBLIC_SUPPLY = 2000;
    uint256 constant public PRICE = 0.25 ether;

    uint256 private lastTokenId = 0;
    bool private individualURIs = false;

    string private baseURI;

    mapping (address => uint256) public allocations;
    uint256 public purchaseCount = 0;

    address public daoAddress;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address _daoAddress,
        address[] memory teamAddresses,
        uint256[] memory teamAllocations
    ) ERC721(name, symbol) EIP712(name, "1") {
        require(teamAddresses.length == teamAllocations.length, "Invalid input");

        daoAddress = _daoAddress;
        uint256 allocated = 0;

        for (uint256 i = 0; i < teamAllocations.length; i++) {
            allocated += teamAllocations[i];
            allocations[teamAddresses[i]] = teamAllocations[i];
        }

        require(allocated + MAX_PUBLIC_SUPPLY == MAX_SUPPLY, "Invalid allocation");

        baseURI = uri;
    }

    function setDaoAddress(address _daoAddress) onlyOwner external {
        daoAddress = _daoAddress;
    }

    function setRoyalty(address receiver, uint96 numerator) onlyOwner external {
        _setDefaultRoyalty(receiver, numerator);
    }

    function toggleIndividualURIs(bool on) onlyOwner external {
        individualURIs = on;
    }

    function setBaseURI(string memory uri) onlyOwner external {
        baseURI = uri;
    }

    function mint(uint256 amount) external {
        require(allocations[msg.sender] >= amount, "Supply exceeded");
        require(lastTokenId + amount <= MAX_SUPPLY, "Supply exceeded");

        allocations[msg.sender] -= amount;

        for (uint256 i = 0; i < amount; i++) {
          	_mint(msg.sender, ++lastTokenId);
        }
    }

    function purchase(uint256 amount) external payable {
        require(msg.value == amount * PRICE, "Insufficient payment");
        require(purchaseCount + amount <= MAX_PUBLIC_SUPPLY, "Supply exceeded");
        require(lastTokenId + amount <= MAX_SUPPLY, "Supply exceeded");

        purchaseCount += amount;

        for (uint256 i = 0; i < amount; i++) {
          	_mint(msg.sender, ++lastTokenId);
        }
        (bool sent, bytes memory data) = daoAddress.call{value: msg.value}("");
        require(sent == true, "Failed to complete purchase");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (individualURIs) {
          return super.tokenURI(tokenId);
        } else {
          _requireMinted(tokenId);
          return baseURI;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Votes) {
        _transferVotingUnits(from, to, batchSize);
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}