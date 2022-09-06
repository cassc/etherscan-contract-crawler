// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "erc721a/contracts/ERC721A.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NotANinjaFaith is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public PRICE = 0 ether;
    uint256 public PRICE_WL = 0 ether;
    uint256 public constant MAX_PER_ADDRESS = 2;
    uint256 public constant MAX_PER_WL_MINT_ADDRESS = 2;

    mapping(address => uint256) private _allowList;

    string private _baseTokenURI;
    bool private _presalePaused = true;
    bool private _publicPaused = true;

    constructor() ERC721A("Not A Ninja Faith", "NNF") {
        _baseTokenURI = 'ipfs://QmT2ivBBMv3dAPrtmEfj8DYo9KcvWYR3P7afFGEm4YMF3u?';
    }

    modifier mintCompliance(uint256 quantity) {
        require(!_publicPaused, "The contract is paused");
        require(
            quantity > 0 && quantity <= MAX_PER_ADDRESS,
            "Invalid mint amount"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "exceed supply");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_PER_ADDRESS,
            "max total mint 5 per address"
        );
        require(PRICE * quantity <= msg.value, "Insufficient funds");
        _;
    }

    modifier wlMintCompliance(uint256 quantity) {
        require(!_presalePaused, "The contract is paused");
        require(_allowList[msg.sender] >= 1, "Address not in Whitelist");
        require(
            quantity > 0 && quantity <= MAX_PER_WL_MINT_ADDRESS,
            "Invalid mint amount"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "exceed supply");
        require(PRICE_WL * quantity <= msg.value, "Insufficient funds");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPresalePrice(uint256 p) external onlyOwner {
        PRICE_WL = p;
    }

    function setPublicPrice(uint256 p) external onlyOwner {
        PRICE = p;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
        }
    }

    function togglePresale() external onlyOwner {
        _presalePaused = !_presalePaused;
    }

    function togglePublic() external onlyOwner {
        _publicPaused = !_publicPaused;
    }

    function airdrop(address receiver, uint256 quantity) external onlyOwner {
        _safeMint(receiver, quantity);
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity)
        external
        payable
        wlMintCompliance(quantity)
    {
        _safeMint(msg.sender,quantity);
        _allowList[msg.sender] = 0;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}