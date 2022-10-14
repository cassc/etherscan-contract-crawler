// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "./utils/Hierarchy.sol";
import "./utils/SafePct.sol";


contract LushLinkCronosUnlimitedDrop is Pausable, ERC721Enumerable, ERC2981, Hierarchy {
    using Strings for uint256;
    using SafePct for uint256;
    using SafeMathLite for uint256;

    string public baseURI;

    // Costs.
    uint256 public regularCost;
    uint256 public memberCost;

    //Restrictions.
    address ownerAddress;

    // Rev Split.
    address[] private payees;
    uint16[] private shares;

    // Drop Timing.
    uint256 publicStartTime;
    address immutable FACTORY_ADDRESS;

    //
    struct Infos {
        uint256 regularCost;
        uint256 memberCost;
        uint256 totalSupply;
        uint256 maxMintPerAddress;
        uint256 maxMintPerTx;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address ownerAddress_
    )
    ERC721(name_, symbol_)
    Hierarchy(ownerAddress_)
    {
        setBaseURI(baseURI_);
        ownerAddress = ownerAddress_;
        FACTORY_ADDRESS = msg.sender;

    }

    function getInfo() public view returns (Infos memory) {
        Infos memory allInfos;
        allInfos.regularCost = regularCost;
        allInfos.memberCost = memberCost;
        allInfos.totalSupply = totalSupply();
        return allInfos;
    }

    // Pricing.
    function mintCost(address _address) public view returns (uint256) {
        require(_address != address(0), "not address 0");
        return regularCost;
    }

    function setRegularCost(uint256 _cost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        regularCost = _cost;
    }

    function setMemberCost(uint256 _cost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        memberCost = _cost;
    }


    // Minting.
    function mint(uint256 _mintAmount) public payable whenNotPaused {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to mint");
        require(_mintAmount > 0, "need to mint at least 1 NFT");

         uint256 cost = mintCost(msg.sender);
         uint256 totalCost = cost.mul(_mintAmount);

         require(totalCost <= msg.value, "Insufficient Funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mintNextId(msg.sender);
        }
    }

    function airdropMint(address _to, uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to airdrop");
        for (uint256 i = 1; i <= _amount; i++) {
            _mintNextId(_to);
        }
    }

    function airdropMintBatch(address[] memory destinations) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to airdrop");

        for (uint i=0; i<destinations.length; i++) {
            _mintNextId(destinations[i]);
        }
    }

    function _mintNextId(address to) private {
        uint256 id = totalSupply() + 1;
        _safeMint(to, id);
    }

    // Burn.
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }



    // Metadata.
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      string memory _tokenURI = string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId),".json"));
      return _tokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to set base uri");
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Pausing.
    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to pause contract");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _unpause();
    }


    // Access
    function grantAdminRole(address account) public {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdminRole(address account) public {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    }

    // Royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not allowed to set royalty");
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}