// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// @creator: Beautiful People
// @title: Collective Drop for Earthquake Victims
// @author: @devbhang - devbhang.eth
// @author: @0xhazelrah - hazelrah.eth
// @author: @berkozdemir - berk.eth
// @author: @aertascom - aertas.eth

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract CDForTurkey is ERC1155, Ownable, Pausable, ERC1155Supply {
    address public ahbapWallet = 0xe1935271D1993434A1a59fE08f24891Dc5F398Cd;
    string public baseURI = "https://for-turkey-website-yf4vo.ondigitalocean.app/metadata/";

    uint256 public price = 0.006 ether;

    constructor() ERC1155("") {
        _pause();
    }

    /**
     ** Just in case AHBAP decides to change the relief wallet.
     ** They announced that they might create a new wallet in the future.
     */
    function setAhbapWallet(address _address) external onlyOwner {
        ahbapWallet = _address;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTotal(uint256 _total) external onlyOwner {
        require(total < _total, "VALUE NOT VALID");

        total = _total;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(uint256 _id, uint256 _amount) public payable whenNotPaused {
        require(_id < total, "TOKEN ID NOT VALID");
        require(msg.value >= price * _amount, "NOT ENOUGH ETHERS SEND");

        _mint(msg.sender, _id, _amount, "");
    }

    function mintBatch(uint256[] memory _ids, uint256[] memory _amounts) public payable whenNotPaused {
        require(msg.value >= price * _amounts.length, "NOT ENOUGH ETHERS SEND");

        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "INSUFFICIENT FUNDS");

        payable(ahbapWallet).transfer(address(this).balance);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        require(tokenId < total, "TOKEN ID NOT VALID");

        return (
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            )
        );
    }

    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(
            _operator,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
    }
}