// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//  __  _   _  _  ___  _    _ _  ___  _    ___  __   __  ___  ___ _ _  __   ___  _ _  _  __
// / _|/ \ | \| ||_ _|/ \  | U || __|| |  | o \/ _| |  \| __|| o ) | |/ _| |_ _|| U || |/ _|
// \_ \ o || \\ | | || o | |   || _| | |_ |  _/\_ \ | o ) _| | o \ U ( |_n  | | |   || |\_ \
// |__/_n_||_|\_| |_||_n_| |_n_||___||___||_|  |__/ |__/|___||___/___|\__/  |_| |_n_||_||__/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SantaHelpsDebugThis is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 855;
    uint256 public mintPrice = .002 ether;
    uint256 public maxPerTransaction = 5;
    bool public paused = true;
    string private baseTokenUri = "";
    string public hiddenTokenUri = "ipfs://Qmb21Mrbh53z5zHCLJwV8qM1SwT4FtGUso3DasGHJBtguM/unrevealed.json";
    mapping(address => uint256) public mintedPerAddress;
    bool public isRevealed;

    constructor() ERC721A("Santa Helps Debug This", "SANTA") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Santa could not debug this.");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "Santa could not debug this."
        );
        require(
            (mintedPerAddress[msg.sender] + _quantity) <= maxPerTransaction,
            "Santa could not debug this."
        );
        require(msg.value >= (mintPrice * _quantity), "Santa could not debug this.");

        mintedPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address receiver, uint256 amount) external onlyOwner {
        _safeMint(receiver, amount);
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

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return hiddenTokenUri;
        }
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

     function setHiddenTokenUri(string memory _hiddenTokenUri) external onlyOwner {
        hiddenTokenUri = _hiddenTokenUri;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed.");
    }
}