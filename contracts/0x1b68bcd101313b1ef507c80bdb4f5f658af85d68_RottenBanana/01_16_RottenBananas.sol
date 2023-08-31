// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RottenBanana is
DefaultOperatorFilterer,
ERC721("Rotten Bananas", "BANANA")
{

    string public baseURI;
    bool public isSaleActive;
    uint256 public circulatingSupply;
    address public owner = msg.sender;
    uint256 public itemPrice = 0.0069 ether;
    uint256 public constant totalSupply = 10000;

    address public lab = 0xBa34F93DBadd48111982a049f6244507C3276ab8;
    address public dev = 0x36bc29c6C36D8f60b08fb9Fe6e7D4649707Aecc7;

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Mint multiple Bananas at once
    function mintBananas(uint256 _howMany)
        external
        payable
        bananasAvailable(_howMany)
    {
        require(
            isSaleActive,
            "Sale is not active"
        );
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Wrong amount of ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 _90_percent = (balance * 0.90 ether) / 1 ether;
        uint256 _10_percent = (balance * 0.10 ether) / 1 ether;

        payable(msg.sender).transfer(_10_percent);
        payable(lab).transfer(_90_percent);
    }

    // Change price in case ETH moons
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    // Update metadata
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * To renounce ownership set the 0x00 address as the new owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    ///////////////////
    // Query Method  //
    ///////////////////

    function bananasRemaining() public view returns (uint256) {
        return totalSupply - circulatingSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///////////////////
    //  Helper Code  //
    ///////////////////

    modifier bananasAvailable(uint256 _howMany) {
        require(_howMany <= bananasRemaining(), "Try minting less bananas");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //////////////////////////////
    // Opensea OperatorFilterer //
    //////////////////////////////

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}