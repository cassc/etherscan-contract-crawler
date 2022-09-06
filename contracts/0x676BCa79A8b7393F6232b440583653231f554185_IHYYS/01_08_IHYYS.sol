// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IHYYS is ERC721A, Ownable {
    IERC721 public immutable ILYYW;
    uint256 public constant MAX_TOKEN_SUPPLY = 5000;
    bool    public paused = true;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor(string memory uri, address ilyyw) ERC721A("Scaries", "IHYYS") {
        baseURI = uri;
        ILYYW = IERC721(ilyyw);
    }

    modifier verifySupply() {
        require(tx.origin == msg.sender,               "We like humans.");
        require(!paused,                               "Minting is paused.");
        require(totalSupply() + 1 <= MAX_TOKEN_SUPPLY, "Exceeds max token supply.");

        _;
    }

    function mint(uint[] calldata tokenIds) public payable verifySupply() {
        require(ILYYW.isApprovedForAll(msg.sender, address(this)), "Need approval for all.");
        require(tokenIds.length > 0,                               "Must burn at least one ILYYW token.");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ILYYW.ownerOf(tokenIds[i]) == msg.sender, "You don't own these ILYYW tokens.");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ILYYW.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenIds[i]);

            _safeMint(msg.sender, 1);
        }
    }

    function pause(bool _value) external onlyOwner {
        paused = _value;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    // In case anyone stupid sends ETH to this contract.
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }
}