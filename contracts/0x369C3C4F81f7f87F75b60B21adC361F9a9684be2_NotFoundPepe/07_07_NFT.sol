// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/Strings.sol";
import "./libraries/Ownable.sol";

contract NotFoundPepe is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;

    uint256 public price = 0.00404 ether;

    uint256 public maxPerTx = 4;

    uint256 public maxSupply = 404;

    bool public mintEnabled = false;

    constructor(address owner_) ERC721A("NotFoundPepe", "NFP") {
        setBaseURI("ipfs://QmcBUPwprqSd5qNw5U1JWJopdf3JNdU6kvNe5bR1J7MHN9/");
        transferOwnership(owner_);
    }

    function mint(uint256 count) external payable {
        uint256 cost = price * count;
        require(msg.value >= cost, "Please send the exact amount");
        require(totalSupply() + count <= maxSupply, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(count <= maxPerTx, "Max per TX reached");

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}