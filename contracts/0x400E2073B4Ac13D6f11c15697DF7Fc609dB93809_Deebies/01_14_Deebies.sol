// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Deebies is AccessControl, ERC721Enumerable {
    using Strings for uint256;
    using SafeMath for uint256;

    uint public constant MAX_DEEBIES = 3053;
    uint private constant RESERVED_DEEBIES = 75;

	string private baseTokenURI;
    string private defaultTokenURI;
	bool public paused;
    address private ownerAddress;
    address private devAddress;
    uint private mintedTeamDeebies;
    

    constructor(address owner_, address dev_, string memory uri_) ERC721("Deebies", "DEEBIES")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        setOwner(owner_);
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        defaultTokenURI = uri_;
        devAddress = dev_;
        paused = true;
    }

    function mintDeebie() public payable {
        if(msg.sender != owner()){
            require(!paused, "Pause");
        }
        require(totalSupply() + 1 <= MAX_DEEBIES, "Sale ended");
        require(msg.value >= price(), "Value below price");

        _safeMint(_msgSender(), totalSupply());
    }

    function mintTeamDeebies(address _to, uint _count) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintedTeamDeebies <= RESERVED_DEEBIES, 'Reserved deebies are minted');

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }

        mintedTeamDeebies += _count;
    }

    function owner() public view virtual returns (address) {
        return ownerAddress;
    }

    function setOwner(address owner_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ownerAddress = owner_;
    }


    function price() public pure returns (uint256) {        
        return 100000000000000000; // 0.1 ETH
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : defaultTokenURI;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return result;
    }


    function pause(bool isPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = isPaused;
    }

    function withdrawAll() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 dev_balance = balance.sub(balance.div(100).mul(96));

        payable(ownerAddress).transfer(balance - dev_balance);
        payable(devAddress).transfer(dev_balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}