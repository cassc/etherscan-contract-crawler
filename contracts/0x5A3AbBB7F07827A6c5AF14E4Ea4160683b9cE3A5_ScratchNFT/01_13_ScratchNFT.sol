// SPDX-License-Identifier: MIT LICENSE
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract ScratchNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply = 141;
    uint256 public maxMintAmount = 10;
    bool public paused = false;
    address payable _seller;

    constructor() ERC721("RadioHeadz Evolution", "scrp") {
        _seller = payable(msg.sender);
        baseURI = "https://scratch.mypinata.cloud/ipfs/QmR9M3GKCJRc1UfUmiT8fTrH1yzqeTEzFsogUsjQvW6Qmy/";
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(supply + 1 <= maxSupply);

        // different prices for diffrent classes
        if (supply < 14 || supply >= 114) {
            cost = 0.2 ether;
        } else {
            cost = 0.1 ether;
        }

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Insufficient ether!");
        }

        _seller.transfer(cost * _mintAmount );

        // return extra eth to buyer
        payable(msg.sender).transfer(msg.value - (cost * _mintAmount ));


        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
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

    // only owner

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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}