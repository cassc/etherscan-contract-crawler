pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BurnSwapNFT is ERC721, ERC721Enumerable, Ownable {
    string public baseURI;
    string public contractURI_;

    address payable public TREASURY;
    uint256 public cost;

    uint256 public maxSupply;

    bool public mintingEnabled = true;

    constructor(
        string memory baseURI_,
        string memory contractURI__,
        address payable treasury_,
        uint256 cost_,
        uint256 maxSupply_
    ) ERC721("BurnSwap Prelaunch NFT", "BURNSNFT") {
        baseURI = baseURI_;
        contractURI_ = contractURI__;

        TREASURY = treasury_;
        cost = cost_;

        maxSupply = maxSupply_;
    }

    function updateBaseURI(string memory value) public onlyOwner {
        baseURI = value;
    }

    function updateContractURI(string memory value) public onlyOwner {
        contractURI_ = value;
    }

    function updateTreasury(address payable value) public onlyOwner {
        TREASURY = value;
    }

    function updateCost(uint256 value) public onlyOwner {
        cost = value;
    }

    function updateMaxSupply(uint256 value) public onlyOwner {
        maxSupply = value;
    }

    function updateMintingEnabled(bool value) public onlyOwner {
        mintingEnabled = value;
    }

    function contribute(uint256 amount) public payable {
        require(mintingEnabled, "CONT: Minting not live yet.");
        uint256 totalCost = amount * cost;
        require(msg.value >= totalCost, "CONT: Not enough allowance.");
        require(totalSupply() + 1 < maxSupply, "CONT: Sold out!");

        (bool sent, ) = TREASURY.call{value: msg.value}("");
        require(sent, "CONT: Failed to send Ether");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    function mint(address to) public onlyOwner {
        _safeMint(to, totalSupply() + 1);
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }
}