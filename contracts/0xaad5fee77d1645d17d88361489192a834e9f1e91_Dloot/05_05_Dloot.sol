// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dloot is ERC721A, Ownable {
    // Placeholder price
    uint256 public price = 0.004 ether;
    uint256 public maxPerMint = 10;

    string private baseURI =
        "ipfs://bafybeidmlj2esp4p2steb2xwq3tszzf5bggfs7tnrs45rnfnn6rues647q/";

    uint64 public immutable _maxSupply = 2222;

    constructor() ERC721A("FTX Dumped Loot", "DLOOT") {}

    /*///////////////////////////////////
                    Mint
    //////////////////////////////////*/

    function mint(uint256 quantity) external payable {
        require(msg.value == price * quantity, "The price is invalid");
        require(quantity <= maxPerMint, "Too Many Minted");
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external payable onlyOwner {
        require(quantity <= maxPerMint * 5, "The price is invalid");
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        _mint(msg.sender, quantity);
    }

    /*/////////////////////////////////////////////////////////////////////////////
        Below is the base URI stuff, it will point to the lyra server, which will
        be a proxy for more permanent storage solutions such as IPFS.
    /////////////////////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    /*///////////////////////////////////////////////////////////
        Withdraw function to get ether out of the contract
    ///////////////////////////////////////////////////////////*/

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }

    /*///////////////////////////////////////////////////////////
        Price
    ///////////////////////////////////////////////////////////*/

    function getPrice() public view returns (uint256) {
        return price;
    }

    function changePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /*///////////////////////////////////////////////////////////
        Token URI
    ///////////////////////////////////////////////////////////*/
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(_tokenId), ".json"));
    }
}