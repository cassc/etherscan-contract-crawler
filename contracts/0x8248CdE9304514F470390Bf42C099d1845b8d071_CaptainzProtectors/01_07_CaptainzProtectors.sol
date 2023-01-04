// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//   _____          __       _            ___           __          __
//  / ___/__ ____  / /____ _(_)__  ___   / _ \_______  / /____ ____/ /____  _______
// / /__/ _ `/ _ \/ __/ _ `/ / _ \/_ /  / ___/ __/ _ \/ __/ -_) __/ __/ _ \/ __(_-<
// \___/\_,_/ .__/\__/\_,_/_/_//_//__/ /_/  /_/  \___/\__/\__/\__/\__/\___/_/ /___/
//         /_/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CaptainzProtectors is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 400;
    uint256 public MINT_PRICE = .005 ether;
    uint256 public MAX_PER_TX = 3;
    bool public paused = true;
    string public baseURI = "ipfs://QmbwSgyS9sPHaJzft82tDbL9KrBv3jhfhZJThZNPQUE4y4/";
    mapping(address => uint256) public walletMintCount;

    constructor() ERC721A("Captainz Protectors", "CP") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Mint paused");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Max supply reached"
        );
        require(
            (walletMintCount[msg.sender] + _quantity) <= MAX_PER_TX,
            "Max mint per wallet reached"
        );
        require(msg.value >= (MINT_PRICE * _quantity), "Send the exact amount");

        walletMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setStatus(uint256 _newAmount) external onlyOwner {
        MAX_SUPPLY = _newAmount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function setMaxPerTx(uint256 _quantity) external onlyOwner {
        MAX_PER_TX = _quantity;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}