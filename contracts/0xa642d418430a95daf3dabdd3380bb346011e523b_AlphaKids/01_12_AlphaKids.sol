// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract AlphaKids is Ownable, ERC721A {
    using Strings for uint256;
    uint256 public maxTotalSupply;
    address public minter;
    string private _baseURIExtended;
    event Minted(address to, uint256 quantity);

    constructor() ERC721A("Alpha Kids", "APKD") {
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

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        require(_maxTotalSupply > 0, "_maxTotalSupply has to be larger than 0");
        require(maxTotalSupply == 0, "can only set once");
        maxTotalSupply = _maxTotalSupply;
    }

    function airdrop(address[] memory receivers, uint256[] memory quantity)
        external
        onlyOwner
    {
        require(receivers.length == quantity.length, "array length mismatch");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantity[i]);
            emit Minted(receivers[i], quantity[i]);
        }
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        if (maxTotalSupply != 0) {
            require(
                totalSupply() + quantity <= maxTotalSupply,
                "exceeds max total supply"
            );
        }

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