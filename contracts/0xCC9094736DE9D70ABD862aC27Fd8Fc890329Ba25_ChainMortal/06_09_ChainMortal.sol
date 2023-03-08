pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ChainmortalFactory.sol";

contract ChainMortal is ERC721A, Ownable, ReentrancyGuard {
    uint256 public price = 0.004 ether;
    bool public forSale = false;
    uint256 supplyCap = 6000;

    mapping(uint256 => uint256) internal idToSeed;

    constructor() ERC721A("Chainmortal", "CM") {}

    function mint(uint256 quantity) external payable {
        require(forSale, "ERROR: Mint not enabled");
        require(quantity < 100, "ERROR: Mint limit Exceeds");
        require(msg.value >= price * quantity, "ERROR: insufficient balance");
        require(
            totalSupply() + quantity <= supplyCap,
            "ERORR: Supply cap reached"
        );

        uint256 nextTokenId = _nextTokenId();

        for (uint32 i; i < quantity; ) {
            idToSeed[nextTokenId] = random(nextTokenId);
            unchecked {
                ++nextTokenId;
                ++i;
            }
        }

        _mint(msg.sender, quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "ERROR: query for nonexistent token");
        uint256 seed = idToSeed[tokenId];
        return ChainmortalFactory.art(seed, tokenId);
    }

    function toggleSale() external onlyOwner {
        forSale = true;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        idToSeed[tokenId] = seed;
    }

    // function generateSeed(uint256 tokenId) private view returns (uint256) {
    //     uint256 r = random(tokenId);
    //     uint256 topSeed = 100 * ((r % 7) + 10) + (((r >> 48) % 20) + 10);
    //     uint256 eyeSeed = 100 *
    //         (((r >> 96) % 6) + 10) +
    //         (((r >> 96) % 20) + 10);
    //     uint256 nodeSeed = 100 *
    //         (((r >> 144) % 7) + 10) +
    //         (((r >> 144) % 20) + 10);
    //     uint256 mouthSeed = 100 *
    //         (((r >> 192) % 2) + 10) +
    //         (((r >> 192) % 20) + 10);
    //     return
    //         10000 *
    //         (10000 * (10000 * topSeed + eyeSeed) + nodeSeed) +
    //         mouthSeed;
    // }

    function random(
        uint256 tokenId
    ) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}