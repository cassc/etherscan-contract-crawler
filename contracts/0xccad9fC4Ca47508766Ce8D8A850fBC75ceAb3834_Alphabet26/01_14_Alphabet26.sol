// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";

contract Alphabet26 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    string baseURI = "https://alphabet26.infura-ipfs.io/ipfs/QmcZVsfTcVinhdRShYUee3k4N8Mk6KRFLzjURxcYRYpUZZ/";
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 26;
    uint256 public maxMintAmount = 1;
    mapping(address => string) customNames;

    constructor() ERC721("Alphabet26", "APB26") {}

    function setCustomNameByUser(string memory _customName) public {
        uint256 ownerTokenCount = balanceOf(msg.sender);
        require(ownerTokenCount > 0);
        customNames[msg.sender] = _customName;
    }

    function getCustomNameByUser(address _owner)
        public
        view
        returns (string memory)
    {
        return customNames[_owner];
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function mint(uint256 tokenId) public payable {
        uint256 supply = totalSupply();
        require(tokenId >= 0);
        require(supply + 1 <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost * 1);
        }
        _safeMint(msg.sender, tokenId);
    }
    
    // Use transfer method to withdraw an amount of money and for updating automatically the balance
    function withdrawMoney(uint _value) public onlyOwner {
        payable(owner()).transfer(_value);
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
    function contractURI() public view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "contract",
                        baseExtension
                    )
                )
                : "";
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
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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
}