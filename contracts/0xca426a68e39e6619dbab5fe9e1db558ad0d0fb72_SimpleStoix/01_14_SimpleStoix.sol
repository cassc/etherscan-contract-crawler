// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleStoix is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    uint16 public constant MAX_SUPPLY = 9997;
    uint16 public freemints = 500;
    uint16 public reserved = 300;
    uint256 public constant PRICE = 27000000000000000;
    uint256 public startingIndex = 0;
    address private _teamAddress;
    string public provenance = "";
    string public baseURI =
        "https://abtrum80la.execute-api.us-east-1.amazonaws.com/";

    constructor(address teamAddress) ERC721("Simple Stoix", "STOIX") {
        _teamAddress = teamAddress;
    }

    // - Minting
    function _mintStoix(uint16 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(sender, mintIndex);
        }
    }

    function mintStoix(uint16 numberOfTokens) public payable {
        require(saleIsActive, "sale is not active");
        require(freemints == 0, "paid period is not active");
        require(numberOfTokens <= 30, "can only mint 30");
        require(
            totalSupply().add(numberOfTokens).add(reserved) <= MAX_SUPPLY,
            "exceeded max supply"
        );
        require(PRICE.mul(numberOfTokens) <= msg.value, "incorrect eth value");

        _mintStoix(numberOfTokens, msg.sender);
    }

    function mintFreeStoix() public {
        require(saleIsActive, "sale is not active");
        require(freemints > 0, "free minting is over");
        require(
            totalSupply().add(1).add(reserved) <= MAX_SUPPLY,
            "exceeded max supply"
        );

        freemints = freemints - 1;
        _mintStoix(1, msg.sender);
    }

    // Owner Only
    function pauseSale() public onlyOwner {
        require(saleIsActive == true, "sale already paused");
        saleIsActive = false;
    }

    function startSale() public onlyOwner {
        require(saleIsActive == false, "sale already started");
        saleIsActive = true;
    }

    function stopFreeSale() public onlyOwner {
        require(freemints > 0, "free sale is already over");
        freemints = 0;
    }

    function setProvenance(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "already set");

        uint256 _block_shift = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        _block_shift = 1 + (_block_shift % 255);

        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint256(blockhash(_block_ref)) % MAX_SUPPLY;

        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(payable(_teamAddress).send(contractBalance));
    }

    function claimReserved(uint16 number, address receiver) external onlyOwner {
        require(number <= reserved, "would exceed the max reserved");

        uint256 tokenId = totalSupply();
        for (uint256 i; i < number; i++) {
            _safeMint(receiver, tokenId + i);
        }

        reserved = reserved - number;
    }

    // View Helpers
    function allStoixOfWallet(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function freePeriodActive() public view returns (bool) {
        return freemints > 0;
    }

    // Overrides
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // Mandatory
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}