// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BabySBTs is ERC721("Baby BAB Family", "BBF"), Ownable {
    address public constant SBTs = 0x2B09d47D550061f995A3b5C6F0Fd58005215D7c8;
    uint public constant MAX_SUPPLY = 10000;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public userClaimed;

    event Mint(address account, uint256 tokenId);
    event NewMinter(address account);
    event DelMinter(address account);

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
        require(totalSupply() <= MAX_SUPPLY, "already full");
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

    function claim() external {
        require(!userClaimed[msg.sender] && ERC721(SBTs).balanceOf(msg.sender) > 0, "cannot claim");
        uint256 _tokenId = totalSupply() + 1;
        _mint(msg.sender, _tokenId);
        emit Mint(msg.sender, _tokenId);
        userClaimed[msg.sender] = true;
        require(totalSupply() <= MAX_SUPPLY, "already full");
    }

    function avaliable(address user) external view returns(bool) {
        if (totalSupply() >= MAX_SUPPLY) {
            return false;
        }
        if (userClaimed[user]) {
            return false;
        }
        if (ERC721(SBTs).balanceOf(user) <= 0) {
            return false;
        }
        return true;
    }
}