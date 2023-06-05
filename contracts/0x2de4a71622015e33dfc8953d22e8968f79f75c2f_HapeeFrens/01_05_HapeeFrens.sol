// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract HapeeFrens is Ownable, ERC721 {
    error QueryForNonExistentToken();
    error TokenLimitReached();
    error Greedy();
    error Paused();

    uint8 public paused = 1;

    uint256 public constant MAX_TOKENS = 3000;
    uint8 public constant MAX_MINT_AMOUNT = 7;

    string private baseUri;

    mapping(address => uint8) public minted;
    uint256 public totalMinted = 0;

    constructor() ERC721("Hapee Frens", "HPFS") {}

    modifier whenUnpaused() {
        if (paused == 1) {
            revert Paused();
        }
        _;
    }

    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function pause() external onlyOwner {
        paused = 1;
    }

    function unpause() external onlyOwner {
        paused = 2;
    }

    function mintFren(uint8 amount) external whenUnpaused {
        // Check if 3000 tokes reached
        uint256 _totalMinted = totalMinted;
        if (_totalMinted + amount > MAX_TOKENS) {
            revert TokenLimitReached();
        }

        // Check if address minted more than 7
        uint8 mintedSoFar = minted[msg.sender];
        if (mintedSoFar + amount > MAX_MINT_AMOUNT) {
            revert Greedy();
        }

        minted[msg.sender] += amount;
        totalMinted += amount;
        uint256 baseIndex = _totalMinted + 1;
        for (uint8 i = 0; i < amount; ) {
            _safeMint(msg.sender, baseIndex + i);
            unchecked {
                i++;
            }
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_ownerOf[id] == address(0)) revert QueryForNonExistentToken();
        return string(abi.encodePacked(baseUri, Strings.toString(id)));
    }
}