// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bonalisa is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 500;

    /**
     * Each Bonalisa image is firstly hashed using SHA-256 algorithm.
     * A combined string is obtained by concatenating SHA-256 of each Bonalisa image in the specific order.
     * You can see this specific order in the initial_sequence_index field of tokenURI metadata.
     * The final proof is obtained by SHA-256 hashing this combined string.
     * This is the final provenance record stored on the smart contract.
     */
    string public bonalisaProvenance;

    /**
     * Each Bonalisa token ID is assigned to an artwork image from the initial sequence with this formula:
     * (tokenId + startingIndex) % 500 → Initial Sequence Index
     *
     * NOTE: StartingIndex will take the block difficulty of the last transaction which mint bonalisa succeeded.
     */
    uint256 public startingIndex;

    bool public paused = true;
    string private baseURI;

    constructor() ERC721A("Bonalisa", "Bonalisa") {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint() external mintCompliance(1) {
        require(!paused, "The mint is paused!");
        require(balanceOf(_msgSender()) == 0, "This wallet has been used!");

        _safeMint(_msgSender(), 1);
    }

    function mintForAddress(address _receiver, uint256 _mintAmount) external mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBonalisaProvenance(string memory _bonalisaProvenance) external onlyOwner {
        bonalisaProvenance = _bonalisaProvenance;
    }

    function setStartingIndex(uint256 _startingIndex) external onlyOwner {
        startingIndex = _startingIndex;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}