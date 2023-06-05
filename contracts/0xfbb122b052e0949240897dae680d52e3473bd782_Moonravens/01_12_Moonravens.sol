pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Moonravens is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxSupply;

    bool public saleState;
    string public baseURI;

    uint256 public maxByWallet = 3;
    mapping(address => uint256) public mintedByWallet;

    constructor (
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        string memory _baseURI
    ) ERC721A(name, symbol) {
        maxSupply = _maxSupply;
        baseURI = _baseURI;
    }

    /******************** MODIFIER ********************/

    modifier _notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /******************** OVERRIDES ********************/

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /******************** OWNER ********************/

    /// @notice Set baseURI.
    /// @param newBaseURI New baseURI.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Set saleState.
    /// @param newSaleState New sale state.
    function setSaleState(bool newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    /******************** ALPHA MINT ********************/

    function alphaMint(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(!saleState, "sale is open!");
        require(addresses.length == count.length, "mismatching lengths!");

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }

        require(_totalMinted() <= maxSupply, "Exceed MAX_SUPPLY");
    }

    /******************** PUBLIC ********************/

    function mint(uint256 amount) external _notContract {
        require(saleState, "Sale is closed!");
        require(_totalMinted() + amount <= maxSupply, "Exceed MAX_SUPPLY");
        require(amount > 0, "Amount can't be 0");
        require(amount + mintedByWallet[msg.sender] <= maxByWallet, "Exceed maxByWallet");

        mintedByWallet[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}