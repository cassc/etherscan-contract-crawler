// SPDX-License-Identifier: MIT LICENSE


/*
Collect, trade, stake and earn SEMI with your TRUCK NFTs!!
Twitter: @RowdyUnicorns
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.0;

contract TheRowdyUnicornCarriersKlub is ERC721Enumerable, Ownable {

    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;
    
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 cost = 0.05 ether; 
    uint256 public maxSupply = 7210;
    uint256 public maxMintAmount = 5;
    bool public paused = false;

    constructor() ERC721("The Rowdy Unicorn Carriers Klub NFT Collection", "TRUCK") {}

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return "ipfs://QmPEThXUCBgVb3vmeiUi45MkZK6iknjSsuDcYLqgu49rkW/";

    }

    
    function mint(address _to, uint256 _mintAmount) public payable {
            uint256 supply = totalSupply();
            require(!paused);
            require(_mintAmount > 0);
            require(_mintAmount <= maxMintAmount);
            require(supply + _mintAmount <= maxSupply);
            
            if (msg.sender != owner()) {
            require(msg.value == cost * _mintAmount, "Not enough balance to complete transaction.");
            }
            
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
    }


    function mintpid(address _to, uint256 _mintAmount, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
            
            if (msg.sender != owner()) {
            require(msg.value == cost * _mintAmount, "Not enough balance to complete transaction.");
            }
            
            for (uint256 i = 1; i <= _mintAmount; i++) {
                paytoken.transferFrom(msg.sender, address(this), cost);
                _safeMint(_to, supply + i);
            }
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
    
        
        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory) {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token"
                );
                
                string memory currentBaseURI = _baseURI();
                return
                bytes(currentBaseURI).length > 0 
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        }
        // only owner
        
        function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
            maxMintAmount = _newmaxMintAmount;
        }
        
        function setBaseURI(string memory _newBaseURI) public onlyOwner() {
            baseURI = _newBaseURI;
        }
        
        function setBaseExtension(string memory _newBaseExtension) public onlyOwner() {
            baseExtension = _newBaseExtension;
        }
        
        function pause(bool _state) public onlyOwner() {
            paused = _state;
        }

        function getNFTCost(uint256 _pid) public view virtual returns(uint256) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            uint256 cost;
            cost = tokens.costvalue;
            return cost;
        }

        function getCryptotoken(uint256 _pid) public view virtual returns(IERC20) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            return paytoken;
        }
        
        function withdraw(uint256 _pid) public payable onlyOwner() {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
        }

}