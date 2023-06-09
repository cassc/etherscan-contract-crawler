// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
 * @author KryptKitties
 * @notice To the extent possible under law, Krypt Kitties has waived all copyright and related or neighboring rights to the collection.
 */
contract KryptKitties is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_TEAM_MINT = 3100;
    uint256 public constant MAX_FREE_MINT = 27100;
    uint256 public constant MAX_PAID_MINT = 800;
    uint256 public constant BASE_PRICE = 0.2 ether;
    uint256 private constant MAX_FREE_MINTS_PER_WALLET = 2;
    uint256 private constant MAX_PAID_MINTS_PER_WALLET = 2;

    bool public saleIsActive;
    bool public mintIsActive = true;
    uint256 public countFreeMint = 0;
    uint256 public countTeamMint = 0;
    uint256 public countPaidMint = 0;

    mapping(address => uint256) private MINTED_FREE;
    mapping(address => uint256) private MINTED_PAID;
    string private _baseTokenURI;

    constructor() ERC721A("KryptKitties", "KK") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "KryptKitties :: Cannot be called by a contract"
        );
        _;
    }

    function freeMint(uint256 quantity) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint KryptKitties");
        require(mintIsActive, "Mint must be active to mint KryptKitties");
        require(
            MINTED_FREE[msg.sender] + quantity <= MAX_FREE_MINTS_PER_WALLET,
            "reached max free mint per wallet"
        );
        require(
            countFreeMint + quantity <= MAX_FREE_MINT,
            "reached max supply for free mint"
        );

        MINTED_FREE[msg.sender] += quantity;
        countFreeMint += quantity;
        _safeMint(msg.sender, quantity);
    }

    function paidMint(uint256 quantity) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint KryptKitties");
        require(mintIsActive, "Mint must be active to mint KryptKitties");
        require(
            MINTED_PAID[msg.sender] + quantity <= MAX_PAID_MINTS_PER_WALLET,
            "reached max paid mint per wallet"
        );
        require(
            quantity + countPaidMint <= MAX_PAID_MINT,
            "reached max supply for paid mint"
        );
        require(
            BASE_PRICE * quantity <= msg.value,
            "Eth value sent is not sufficient"
        );
        countPaidMint += quantity;
        MINTED_PAID[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function teamMint(address to, uint256 quantity) external onlyOwner {
        require(mintIsActive, "Mint must be active to mint KryptKitties");
        require(
            countTeamMint + quantity <= MAX_TEAM_MINT,
            "reached max supply for team mint"
        );
        countTeamMint += quantity;
        _safeMint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function closeMint() public onlyOwner {
        mintIsActive = false;
    }

    function mintedFreeOf(address minter)
        public
        view
        virtual
        returns (uint256)
    {
        return MINTED_FREE[minter];
    }

    function mintedPaidOf(address minter)
        public
        view
        virtual
        returns (uint256)
    {
        return MINTED_PAID[minter];
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}