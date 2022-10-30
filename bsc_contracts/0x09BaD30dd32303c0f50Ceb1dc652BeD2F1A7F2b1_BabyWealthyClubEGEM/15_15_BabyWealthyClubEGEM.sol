// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BabyWealthyClubEGEM is ERC721("BWC - Energy Stone", "EGEM"), Ownable {
    uint constant MAX_SUPPLY = 10000;
    mapping(address => bool) public isMinner;

    event Mint(address account, uint256 tokenId);
    event NewMinner(address account);
    event DelMinner(address account);

    function addMinner(address _minner) external onlyOwner {
        require(
            _minner != address(0),
            "BWCSEED: minner is zero address"
        );
        isMinner[_minner] = true;
        emit NewMinner(_minner);
    }

    function delMinner(address _minner) external onlyOwner {
        require(
            _minner != address(0),
            "BWCSEED: minner is zero address"
        );
        isMinner[_minner] = false;
        emit DelMinner(_minner);
    }

    function mint(address to, uint256 tokenId) external onlyMinner {
        require(
            to != address(0),
            "BWCSEED: recipient is zero address"
        );
        _mint(to, tokenId);
        require(totalSupply() <= MAX_SUPPLY, "already full");
        emit Mint(to, tokenId);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _setBaseURI(baseUri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }

    modifier onlyMinner() {
        require(
            isMinner[msg.sender],
            "BWCGTOOL: caller is not the minner"
        );
        _;
    }
}