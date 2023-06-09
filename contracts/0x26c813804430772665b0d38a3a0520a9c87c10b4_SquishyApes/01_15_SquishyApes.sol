// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Enum.sol";
import "./library/Strings.sol";

contract SquishyApes is ERC721Enum, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public maxSupply = 3333;
    uint256 public maxMint = 20;
    bool public status = false;

    // Current price.
    uint256 public CURRENT_PRICE = 0.01 ether;

    constructor() ERC721S("Squishy Apes", "SQUAPES") {
        setBaseURI("");
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(status, "Contract Not Enabled");
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxMint, "Cant mint more then maxmint");
        require(s + _mintAmount <= maxSupply, "Cant go over supply");
        require(
            CURRENT_PRICE * _mintAmount <= msg.value,
            "Value sent is not correct"
        );
        for (uint256 i = 1; i <= _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    function reserve(uint256 _mintAmount) public onlyOwner nonReentrant {
        uint256 s = totalSupply();
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxMint, "Cant mint more then maxmint");
        require(s + _mintAmount <= maxSupply, "Cant go over supply");
        for (uint256 i = 1; i <= _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSaleStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        CURRENT_PRICE = newPrice;
    }

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}