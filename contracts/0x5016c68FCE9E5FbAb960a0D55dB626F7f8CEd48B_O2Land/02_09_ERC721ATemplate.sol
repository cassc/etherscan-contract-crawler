// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract ERC721ATemplate is Ownable, ERC721ABurnable {
    using Strings for uint256;
    uint256 public maxTotalSupply;
    address public minter;
    string private _baseURIExtended = "https://api.o2meta.io/token/";
    event Minted(address to, uint256 quantity);

    constructor(
        string memory name,
        string memory ticker,
        uint256 _maxTotalSupply
    ) ERC721A(name, ticker) {
        maxTotalSupply = _maxTotalSupply;
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "not a minter");
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        require(
            totalSupply() + quantity <= maxTotalSupply,
            "exceeds max total supply"
        );
        _safeMint(to, quantity);
        emit Minted(to, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}