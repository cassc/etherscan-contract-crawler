// SPDX-License-Identifier: MIT

/////////////     ////        ////        ///////////
    ////          ////        ////        ///
    ////          ////        ////        ///
    ////          ////////////////        ///
    ////          ////        ////        ///
    ////          ////        ////        ///
    ////          ////        ////        ///////////


////        ////    //////////////    /////////////     ////        ////
////        ////         ////         ////              ////        ////
////        ////         ////         ////              ////        ////
////////////////         ////         ////   ///////    ////////////////
////        ////         ////         ////      ////    ////        ////
////        ////         ////         ////      ////    ////        ////
////        ////     /////////////    //////////////    ////        ////


      /////          /////////////    //////////////    ////////////////
   ////  ////        ///       ///    ////              ////
////       ////      ///       ///    ////              ////
///         ///      ///       ///    ////              ////
///////////////      /////////////    ///////////       ////////////////
/// /////// ///      ///              ////                          ////
///         ///      ///              ////                          ////
///         ///      ///              //////////////    ////////////////


pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheHighApesClub is ERC721A, Ownable {
    using Strings for uint256;

    // URI
    string public baseURI;
    string public baseExtension = ".json";

    // Supply & Cost
    uint256 public highlistcost = 0.05 ether;
    uint256 public whitelistcost = 0.055 ether;
    uint256 public publiccost = 0.06 ether;
    uint256 public maxSupply = 4200;

    // Mint Limits
    uint256 public maxHighlistMint = 3;
    uint256 public maxWhitelistMint = 3;
    uint256 public maxPublicMint = 5;
    uint256 public maxApePassMint = 1;

    // Sale Info
    // 0 = Inactive, 1 = Highlist, 2 = Whitelist, 3 = Public
    uint256 public currentSale = 0;
    bool public paused = false;
    bool public apepaused = false;

    // Wallets Segregation
    mapping(address => bool) public highlisted;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public apelisted;

    // Claimed High Apes
    mapping(address => uint256) public _PreClaimed;
    mapping(address => uint256) public _PublicClaimed;
    mapping(address => uint256) public _ApeClaimed;

    constructor(
        string memory _initBaseURI
    ) ERC721A("The High Apes Club", "THC") {
        setBaseURI(_initBaseURI);
    }

    // Minting

    function presaleMint(uint256 _mintAmount) public payable
    {
        require(!paused, "THC: Sale is paused");
        require(currentSale == 1 || currentSale == 2, "THC: Sale not active");
        require(_mintAmount > 0, "THC: Must mint at least one");
        require((totalSupply() + _mintAmount) <= maxSupply, "THC: Cannot exceed supply");

               if (currentSale == 1)
                {
                    // Highlist Mint

                     require(highlisted[msg.sender] == true, "THC: Address is not Highlisted");
                     require(_PreClaimed[msg.sender] + _mintAmount <= maxHighlistMint, "THC: Max Highlist mint count exceeded");
                     require(msg.value >= highlistcost * _mintAmount, "THC: Cost not received!");
                }
                else if (currentSale == 2)
                {
                    // Whitelist Mint

                    require(highlisted[msg.sender] == true || whitelisted[msg.sender] == true, "THC: You are not Highlisted or Whitelisted");

                    if (whitelisted[msg.sender] == true)
                    {
                        require((_PreClaimed[msg.sender] + _mintAmount) <= maxWhitelistMint, "THC: Max Whitelist mint count exceeded");
                    }
                    else if (highlisted[msg.sender] == true)
                    {
                        require((_PreClaimed[msg.sender] + _mintAmount) <= (maxHighlistMint + maxWhitelistMint), "THC: Max Whitelist mint count exceeded");
                    }

                    require(msg.value >= whitelistcost * _mintAmount, "THC: Cost not received!");
                }

        _PreClaimed[msg.sender] = _PreClaimed[msg.sender] + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable
    {
        require(!paused, "THC: Sale is paused");
        require(currentSale == 3, "THC: Public Sale not active");
        require(_mintAmount > 0, "THC: Must mint at least one");
        require((totalSupply() + _mintAmount) <= maxSupply, "THC: Cannot exceed supply");

        require(_PublicClaimed[msg.sender] + _mintAmount <= maxPublicMint, "THC: Max Public Mint count exceeded");
            
        require(msg.value >= publiccost * _mintAmount, "THC: Cost not received!");

        _PublicClaimed[msg.sender] = _PublicClaimed[msg.sender] + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function apePassMint(uint256 _mintAmount) public
    {
        require(!paused, "THC: Sale is paused");
        require(!apepaused, "THC: Ape Pass is paused");
        require(currentSale >= 1 && currentSale <= 3, "THC: Cannot use Ape Pass");
        require(_mintAmount > 0, "THC: Must mint at least one");
        require((totalSupply() + _mintAmount) <= maxSupply, "THC: Cannot exceed supply");
        require(apelisted[msg.sender], "THC: You do not have a THC Ape Pass");

        require(_ApeClaimed[msg.sender] + _mintAmount <= maxApePassMint, "THC: Ape Pass Mint count exceeded");

        _ApeClaimed[msg.sender] = _ApeClaimed[msg.sender] + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

   // Internal

    function mintOwner(address _to, uint256 _mintAmount) public onlyOwner
    {
        require((totalSupply() + _mintAmount) <= maxSupply, "THC: Cannot exceed supply");
        _safeMint(_to, _mintAmount);
    }

    function setCurrentSale(uint256 _newSale) public onlyOwner {
        currentSale = _newSale;
    }

    function updateHighlist(uint256 _newHighlistMax, uint256 _newHighlistCost) public onlyOwner {
        maxHighlistMint = _newHighlistMax;
        highlistcost = _newHighlistCost;
    }

    function updateWhitelist(uint256 _newWhitelistMax, uint256 _newWhitelistCost) public onlyOwner {
        maxWhitelistMint = _newWhitelistMax;
        whitelistcost = _newWhitelistCost;
    }

    function updatePublic(uint256 _newPublicMax, uint256 _newPublicCost) public onlyOwner {
        maxPublicMint = _newPublicMax;
        publiccost = _newPublicCost;
    }

    function updateApePass(uint256 _newApePassMax) public onlyOwner {
        maxApePassMint = _newApePassMax;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

     function apepasspause(bool _state) public onlyOwner {
        apepaused = _state;
    }

    // URI 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Add Listings

    function addHighlistedUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            highlisted[_users[i]] = true;
        }
    }

    function removeHighlistedUser(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            highlisted[_users[i]] = false;
       }
    }

    function addWhitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function removeWhitelistUser(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = false;
       }
    }

    function addApePassUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            apelisted[_users[i]] = true;
        }
    }

    function removeApePassUser(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            apelisted[_users[i]] = false;
       }
    }

    // Withdraw

    function withdraw() public payable onlyOwner {

        uint colbal = address(this).balance / 100;

        // Jay
        (bool a, ) = payable(0xd2a76Bfb1275bd36a8299b8F00c634fB1E4200CA).call{value: colbal * 35}("");
        require(a);

        // Kush
        (bool b, ) = payable(0xf299955D204fD09CEE7A0787993C2851e6DFf497).call{value: colbal * 35}("");
        require(b);

        // Staked Whole Percentages
        (bool c, ) = payable(0x28528eb8221DDA7A145Ac2FdF40bb5430Fed0289).call{value: colbal * 6}("");
        require(c);
        
        (bool d, ) = payable(0xBd0fff1d40f14187D89E74369571d75aEC4608A2).call{value: colbal * 2}("");
        require(d);

        (bool e, ) = payable(0xeE645d6a20F49639A6AA436d3cd334105Bd12b41).call{value: colbal * 3}("");
        require(e);
        
        // Community Wallet (Disperse S1 + S2 Percentages [420Verse] + Remainder Used as Community Funds)
        (bool f, ) = payable(0x9779908B8069E9cF38342DDa4C14e7C3fcbf6AD6).call{value: address(this).balance}("");
        require(f);
    }
}