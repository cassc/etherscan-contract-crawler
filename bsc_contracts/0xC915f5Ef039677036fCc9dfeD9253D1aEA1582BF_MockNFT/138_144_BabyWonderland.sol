// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BabyWonderland is ERC721("Baby Wonderland", "BLand"), Ownable {
    mapping(address => bool) public isMinter;

    event Mint(address account, uint256 tokenId);
    event NewMinter(address account);
    event DelMinter(address account);

    uint skipTokenIds = 0;

    function setSkipTokenIds(uint _value) external onlyOwner {
        skipTokenIds = _value;
    }

    function totalSupply() public view virtual override(ERC721) returns (uint256) {
        return ERC721.totalSupply() + skipTokenIds;
    }

    function addMinter(address _minter) external onlyOwner {
        require(
            _minter != address(0),
            "BabyWonderland: minter is zero address"
        );
        isMinter[_minter] = true;
        emit NewMinter(_minter);
    }

    function delMinter(address _minter) external onlyOwner {
        require(
            _minter != address(0),
            "BabyWonderland: minter is the zero address"
        );
        isMinter[_minter] = false;
        emit DelMinter(_minter);
    }

    function mint(address _recipient) public onlyMinter {
        require(
            _recipient != address(0),
            "BabyWonderland: recipient is zero address"
        );
        uint256 _tokenId = totalSupply() + 1;
        _mint(_recipient, _tokenId);
        emit Mint(_recipient, _tokenId);
    }

    function batchMint(address _recipient, uint256 _number)
        external
        onlyMinter
    {
        for (uint256 i = 0; i != _number; i++) {
            mint(_recipient);
        }
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external {
        for (uint256 i = 0; i != tokenIds.length; ++i) {
            transferFrom(from, to, tokenIds[i]);
        }
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

    modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "BabyWonderland: caller is not the minter"
        );
        _;
    }
}