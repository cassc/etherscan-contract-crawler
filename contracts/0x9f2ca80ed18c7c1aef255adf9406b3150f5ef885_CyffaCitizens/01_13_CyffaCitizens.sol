// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CyffaCitizens is ERC721A, Ownable, ReentrancyGuard {
    enum Status {
        Waiting,
        Started,
        Finished
    }
    using Strings for uint256;
    Status public status;
    string private baseURI;
    uint256 public MAX_MINT_PER_ADDR = 5;
    uint256 public constant MAX_FREE_MINT_PER_ADDR = 1;
    uint256 public PUBLIC_PRICE = 0.001 * 10**18;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant FREE_MINT_SUPPLY = 700;
    uint256 public INSTANT_FREE_MINTED = 0;

    event Minted(address minter, uint256 amount);

    constructor(string memory initBaseURI) ERC721A("CyffaCitizens", "CYFFA") {
        baseURI = initBaseURI;
        _safeMint(msg.sender, MAX_FREE_MINT_PER_ADDR);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json")
            );
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(status == Status.Started, "-Not started yet-");
        require(tx.origin == msg.sender, "-Contract call not allowed-");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "-This is more than allowed-"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "-Not enough quantity-"
        );

        uint256 _cost;
        if (INSTANT_FREE_MINTED < FREE_MINT_SUPPLY) {
            uint256 remainFreeAmont = (numberMinted(msg.sender) <
                MAX_FREE_MINT_PER_ADDR)
                ? (MAX_FREE_MINT_PER_ADDR - numberMinted(msg.sender))
                : 0;

            _cost =
                PUBLIC_PRICE *
                (
                    (quantity <= remainFreeAmont)
                        ? 0
                        : (quantity - remainFreeAmont)
                );

            INSTANT_FREE_MINTED += (
                (quantity <= remainFreeAmont) ? quantity : remainFreeAmont
            );
        } else {
            _cost = PUBLIC_PRICE * quantity;
        }
        require(msg.value >= _cost, "-Not enough ETH-");
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function withdraw(address payable recipient)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "-Withdraw failed-");
    }

    function updatePrice(uint256 __price) external onlyOwner {
        PUBLIC_PRICE = __price;
    }

    function updateMaxMint(uint256 __maxmint) external onlyOwner {
        MAX_MINT_PER_ADDR = __maxmint;
    }
}