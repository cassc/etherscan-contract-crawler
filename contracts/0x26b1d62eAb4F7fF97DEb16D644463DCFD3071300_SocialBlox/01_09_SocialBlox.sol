// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SocialBlox is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    //SALE STATES
    // 0 - Sale Disabled
    // 1 - Public Sale

    uint8 public saleState = 0;

    //PER TXN LIMITS
    // 0 - No limit
    // >0 - Limit of # nfts per txn

    uint64 public maxPerTxn = 0;
    uint16 public teamAllocation = 1520;
    uint16 public maxSupply = 5021;
    uint256 public pricePublic = 0.2 ether;

    string private baseURI;
    address private team;

    constructor(address _team) ERC721A("SocialBlox", "SBLX") {
        team = _team;
    }

    modifier perTxnCheck(uint64 quantity) {
        if (maxPerTxn > 0) {
            require(quantity <= maxPerTxn, "Exceeded per transaction limit");
        }
        _;
    }

    function publicMint(uint64 quantity)
        external
        payable
        nonReentrant
        perTxnCheck(quantity)
    {
        require(saleState == 1, "Public sale has not started yet");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(msg.value >= quantity * pricePublic, "Incorrect ETH amount");
        require(tx.origin == _msgSender(), "No contracts");
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setSaleState(uint8 _state) external onlyOwner {
        saleState = _state;
    }

    function setMaxPerTxn(uint8 _perTxn) external onlyOwner {
        maxPerTxn = _perTxn;
    }

    function setBaseURI(string calldata _data) external onlyOwner {
        baseURI = _data;
    }

    function setPrice(uint64 _price) external onlyOwner {
        pricePublic = _price;
    }

    function devMint(uint16 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity <= teamAllocation,
            "Team allocation exceeding limit"
        );
        _safeMint(team, _quantity);
    }

    function preSale(address receiver, uint16 _quantity) external onlyOwner {
        _safeMint(receiver, _quantity);
    }

    function burnSupply(uint16 _maxSupply) external onlyOwner {
        require(
            _maxSupply < maxSupply,
            "New max supply should be lower than current max supply"
        );
        require(
            _maxSupply > totalSupply(),
            "New max suppy should be higher than current number of minted tokens"
        );
        maxSupply = _maxSupply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(team).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    receive() external payable {}
}