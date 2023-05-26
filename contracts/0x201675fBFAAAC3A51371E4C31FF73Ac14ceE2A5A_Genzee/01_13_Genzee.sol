// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Genzee is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant TOTAL_TOKENS = 10001;
    uint256 public constant RESERVED_TOKENS = 100;

    uint256 public unitPrice = 70000000000000000;
    uint256 public tripleUnitPrice = 60000000000000000;

    address private _payoutAddress;
    address private _devAddress;

    uint256 public startingIndex = 0;
    string public provenance = "";
    string public baseURI =
        "https://iyf4zjkulg.execute-api.us-east-1.amazonaws.com/token/";

    uint256 public reservedsLeft = RESERVED_TOKENS;
    uint256 public threshold = 0;
    
    bool public saleIsActive = false;

    constructor(address payoutAddress, address devAddress)
        ERC721("Genzee", "GZ")
    {
        _payoutAddress = payoutAddress;
        _devAddress = devAddress;
    }

    modifier whenSaleIsActive {
      require(saleIsActive, "sale is not active");
      _;
    }

    // - Owner Only
    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    function startSale(uint256 newThreshold) public onlyOwner {
        require(newThreshold >= 0);
        threshold = newThreshold;
        saleIsActive = true;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setProvenance(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function updatePrice(uint256 newUnitPrice, uint256 newTripleUnitPrice) public onlyOwner {
        unitPrice = newUnitPrice;
        tripleUnitPrice = newTripleUnitPrice;
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
        startingIndex = uint256(blockhash(_block_ref)) % TOTAL_TOKENS;

        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function claimReserved(address to, uint256 amount) public onlyOwner {
        require(
            reservedsLeft >= amount,
            "will exceed max reserved supply"
        );
        require(
            tokensLeft() >= amount,
            "will exceed max supply"
        );
        _mintMultipleGz(to, amount);
        reservedsLeft = reservedsLeft - amount;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;

        uint256 devShare = contractBalance * 7 / 100;
        uint256 payoutShare = contractBalance - devShare;

        require(payable(_devAddress).send(devShare));
        require(payable(_payoutAddress).send(payoutShare));
    }

    // - Minting
    function _mintMultipleGz(address to, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply());
        }
    }

    function mintOneGenzee() public payable whenSaleIsActive {
        require(tokensLeft() >= reservedsLeft + 1, "will exceed max supply");
        require(threshold >= totalSupplyMinusReserved() + 1, "will exceed threshold");
        require(msg.value >= unitPrice, "incorrect eth value");
        _safeMint(msg.sender, totalSupply());
    }

    function mintThreeGenzee() public payable whenSaleIsActive {
        require(tokensLeft() >= reservedsLeft + 3, "will exceed max supply");
        require(threshold >= totalSupplyMinusReserved() + 3, "will exceed threshold");
        require(msg.value >= tripleUnitPrice * 3, "incorrect eth value");
        _mintMultipleGz(msg.sender, 3);
    }

    // Views
    function allGenzeesOfWallet(address owner)
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

    function tokensLeft() public view returns (uint256) {
        return TOTAL_TOKENS - totalSupply();
    }

    function totalSupplyMinusReserved() public view returns(uint256) {
        return totalSupply() + reservedsLeft - RESERVED_TOKENS;
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