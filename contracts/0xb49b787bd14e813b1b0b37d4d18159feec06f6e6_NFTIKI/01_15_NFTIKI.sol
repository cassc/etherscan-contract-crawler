// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract NFTIKI is Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;

    uint256 public constant TOKEN_LIMIT = 8000;
    uint256 public constant START_TIME = 1634929200;

    uint256 public ownerMintCount;

    mapping(address => bool) public whitelist;
    bool public isOpenToPublic;

    Counters.Counter private _tokenIds;

    string public _baseTokenURI;

    event AddToWhitelist(address[] accounts);
    event OpenToPublic();
    event UpdateBaseTokenURI(string baseTokenURI);

    constructor() ERC721("NFTIKI", "NFTIKI") {

    }

    function addToWhitelist(address[] memory accounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }

        emit AddToWhitelist(accounts);
    }

    function openToPublic() external onlyOwner {
        isOpenToPublic = true;
        emit OpenToPublic();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _mintTo(address _to) private {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(_to, newNftTokenId);
    }

    function price() public pure returns (uint256) {
        return 0.06 ether;
    }

    function mint(uint256 count) external whenNotPaused payable {
        if(msg.sender != owner()) {
            require(block.timestamp >= START_TIME, "Minting has not started");

            if(!isOpenToPublic) {
                require(whitelist[msg.sender], "Not on whitelist");
            }

            require(count <= 10, "Max mint of 10");

            uint256 totalPrice = price() * count;
            require(totalPrice == msg.value, "Wrong value sent");
        } else {
            ownerMintCount += count;
            require(ownerMintCount <= 100, "Owner can only mint 100");
        }

        uint256 totalSupplyAfter = totalSupply() + count;
        require(totalSupplyAfter <= TOKEN_LIMIT, "Higher than max supply");

        for (uint i = 0; i < count; i++) {
            _mintTo(msg.sender);
        }
    }

    function updateBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
        emit UpdateBaseTokenURI(newBaseTokenURI);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function withdrawAll() public onlyOwner {
        (bool success,) = owner().call {value: address(this).balance } ("");
        require(success, "Withdraw failed");
    }
}