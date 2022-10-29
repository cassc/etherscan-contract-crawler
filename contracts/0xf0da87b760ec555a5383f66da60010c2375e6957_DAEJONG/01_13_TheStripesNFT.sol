//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/access/Ownable.sol";

contract DAEJONG is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    
    uint256 public cost = 0.03 ether;
    uint256 public precost = 0.0285 ether;

    uint256 public maxsupply = 230;
    


    bool public paused = false;
    bool public freeminting = false;
    bool public presale = false;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;
    mapping(address => uint8) public mintAmount; 


    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mintwithTokenURI(address _to, uint256 tokenId, string memory tokenURI) public payable {
        require(!paused);
        uint256 supply = totalSupply();
        require(supply + 1 <= maxsupply);

        if (msg.sender != owner()) {
            if (!freeminting) {

                if (!presale) {
                    require(mintAmount[msg.sender]<9);
                    require(msg.value >= cost);
                    mintAmount[msg.sender] += 1;
                } else {
                    require(mintAmount[msg.sender]<24);
                    require(msg.value >= precost);
                    mintAmount[msg.sender] += 1;

                }
            } else {
                    require(mintAmount[msg.sender]<1);
                    mintAmount[msg.sender] += 1;

            }

        }

        _mint(_to, tokenId);
        _setTokenURI(tokenId, tokenURI);       
        
    }

    function walletOfOwner(address _owner)
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

 /*   function tokenURI(uint256 tokenId)
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
                        type,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
*/

    // function _setTokenURI(uint256 tokenId, string memory uri) internal {
    //     require(_exists(tokenId), "KIP17Metadata: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = uri;
    // }


    // function tokenURI(uint256 tokenId) external view returns (string memory) {
    //     require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
    //     return _tokenURIs[tokenId];
    // }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

   function setmaxsupply(uint256 _maxsupply) public onlyOwner {
        maxsupply = _maxsupply;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function freeminting_status(bool _state) public onlyOwner {
        freeminting = _state;
    }
    
    function presale_status(bool _state) public onlyOwner {
        presale = _state;
    }
    

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function addPresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = true;
    }

    function add100PresaleUsers(address[100] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 2; i++) {
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}