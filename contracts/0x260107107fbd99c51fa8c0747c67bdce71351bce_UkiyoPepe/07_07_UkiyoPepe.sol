// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./LilOwnable.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error DoesNotExist();
error NoTokensLeft();
error NotEnoughETH();
error MaxMinted();

contract UkiyoPepe is ERC721, LilOwnable {

    using Strings for *;

    uint256 public constant TOTAL_SUPPLY = 500;
    uint16 public constant MAX_MINT_PER_WALLET = 2; 

    mapping(address => uint256) public minted;


    uint256 public totalSupply;

    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) ERC721(name, symbol) {
        baseURI = _baseURI;
    }

    function mint(uint16 amount) external {
    if (totalSupply + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
    require (minted[msg.sender] + amount <= MAX_MINT_PER_WALLET, "mint: Greedy Frog, no more free pepe for you... Buy more on NFT Embed.");

    unchecked {
        for (uint16 index = 0; index < amount; index++) {
            _mint(msg.sender, totalSupply++);
        }
    }
    minted[msg.sender] += amount; 
}


    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert DoesNotExist();

        // return string(abi.encodePacked(baseURI, id, ".json"));
        return string(abi.encodePacked(baseURI, '/', id.toString(), '.json'));
    }

    function withdraw() external {
        if (msg.sender != _owner) revert NotOwner();

        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, LilOwnable)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}