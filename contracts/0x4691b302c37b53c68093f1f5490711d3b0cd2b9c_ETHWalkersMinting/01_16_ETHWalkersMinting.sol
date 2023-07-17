// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract BOREDAPES is IERC721 {}
abstract contract MUTANTAPES is IERC721 {}
abstract contract NERDYNUGGETS is IERC721 {}
abstract contract ZENACADEMY is IERC1155 {}

contract ETHWalkersMinting is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string public ethWalkersProvenance = ""; // IPFS added once sold out
    uint8 public constant maxETHWalkersPurchase = 20;
    uint8 public saleState = 0;
    uint public maxEthWalkers = 10060;
    uint public constant MAXIMUM_RAISE_WALKERS_LIMIT = 12060; // If updating maximum, cannot update past 12,060
    uint private _eTHWalkersReserve = 300;
    address payable public payoutsAddress = payable(address(0x812bDAD0057B78251412Db8B1FB92e210ecbF108)); 

    uint public presaleNuggetStart = 1640109600; // Tuesday, December 21, 2021 6:00:00 PM UTC / 1:00:00 PM EST
    uint public presaleApeStart = 1640196000;   // Wednesday, December 22, 2021 6:00:00 PM UTC / 1:00:00 PM EST
    uint public publicSale = 1640282400;   // Thursday, December 23, 2021 6:00:00 PM UTC / 1:00:00 PM EST

    address boredApesAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address mutantApesAddress = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address nerdyNuggetsAddress = 0xb45F2ba6b25b8f326f0562905338b3Aa00D07640;
    address zenAcademyAddress = 0xf64e6fB725f04042b5197e2529b84be4a925902C;

    BOREDAPES private boredApes = BOREDAPES(boredApesAddress);
    MUTANTAPES private mutantApes = MUTANTAPES(mutantApesAddress);
    NERDYNUGGETS private nerdyNuggets = NERDYNUGGETS(nerdyNuggetsAddress);
    ZENACADEMY private zenAcademy = ZENACADEMY(zenAcademyAddress);

    uint256 private _eTHWalkersPrice = 42000000000000000; // 0.042 ETH
    string private baseURI;

    mapping(uint256 => bool) nuggetsEarlyMintRedeemed;
    mapping(uint256 => bool) nuggetPartOfSixPackRedeemed;

    constructor() ERC721("ETH Walkers", "EWALK") { }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _eTHWalkersPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _eTHWalkersPrice;
    }

    function getnuggetsEarlyMintRedeemed(uint256 _id) public view returns (bool){
        return nuggetsEarlyMintRedeemed[_id];
    }

    function getNuggetPartOfSixPackRedeemed(uint256 _id) public view returns (bool){
        return nuggetPartOfSixPackRedeemed[_id];
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyOwner {
        require(_newTimes.length == 3, "You need to update all times at once");
        presaleNuggetStart = _newTimes[0];
        presaleApeStart = _newTimes[1];
        publicSale = _newTimes[2];
    }

    function reserveETHWalkers(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= _eTHWalkersReserve, "Reserve limit has been reached");
        require(totalSupply().add(_reserveAmount) <= maxEthWalkers, "No more tokens left to mint");
        _eTHWalkersReserve = _eTHWalkersReserve.sub(_reserveAmount);
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }


    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        ethWalkersProvenance = provenanceHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setNewMaximumETHWalkersCount(uint16 newMaximumCount) public onlyOwner {
        require(newMaximumCount <= MAXIMUM_RAISE_WALKERS_LIMIT, "You can't set the total this high");
        if(newMaximumCount >= totalSupply()){
            maxEthWalkers = newMaximumCount;
        }
    }

    function setSaleState(uint8 newSaleState) public onlyOwner {
        saleState = newSaleState;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintPreSaleRedeemSixPackNuggets(uint256[] memory ids) external nonReentrant {
        require(saleState >= 1, "Pre-sale must be active to mint");
        require(block.timestamp >= presaleNuggetStart, "Pre-sale must be active to mint");
        require(totalSupply().add(1) <= maxEthWalkers, "Purchase exceeds max supply of ETHWalkers");
        require(ids.length == 6, "Must redeem exactly 6 nuggets for Six Pack");

        for(uint i = 0; i < ids.length; i++) {
            uint id = uint(ids[i]);
            require(nerdyNuggets.ownerOf(id) == msg.sender, "Must own a Nerdy Nugget to mint ETH Walkers in presale");
            require(!nuggetPartOfSixPackRedeemed[id], "This nugget already redeemed");
            nuggetPartOfSixPackRedeemed[ids[i]] = true;
        }


        uint mintIndex = totalSupply();
        if (totalSupply() < maxEthWalkers) {
            _safeMint(msg.sender, mintIndex);
        }
    }

    function mintPreSaleNuggetsEthWalkers(uint256[] memory ids) external payable {
        uint numberOfTokens = ids.length;
        require(saleState >= 1, "Sale must be active");
        require(block.timestamp >= presaleNuggetStart, "Pre-sale must be active to mint");
        require(numberOfTokens > 0 && numberOfTokens <= maxETHWalkersPurchase, "Oops - you can only mint 20 ETHWalkers at a time");
        require(msg.value >= _eTHWalkersPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= maxEthWalkers, "Purchase exceeds max supply of ETHWalkers");

        for(uint i = 0; i < numberOfTokens; i++) {
            require(nerdyNuggets.ownerOf(ids[i]) == msg.sender, "Must own a Nerdy Nugget to mint ETH Walkers in presale");
            require(!nuggetsEarlyMintRedeemed[ids[i]], "This nugget already redeemed for mint");
            nuggetsEarlyMintRedeemed[ids[i]] = true;
            uint mintIndex = totalSupply();
            if (totalSupply() < maxEthWalkers) {
                _safeMint(msg.sender, mintIndex);
            }
        }
        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function preSaleApesZenMintETHWalkers(uint numberOfTokens, address _to) external payable {
        require(saleState >= 1, "Sale must be active to mint");
        require(numberOfTokens > 0 && numberOfTokens <= maxETHWalkersPurchase, "Oops - you can only mint 20 ETHWalkers at a time");
        require(msg.value >= _eTHWalkersPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= maxEthWalkers, "Purchase exceeds max supply of ETHWalkers");

        if(block.timestamp >= publicSale) {
       		// No extra check needed for public sale
       	} else if(block.timestamp >= presaleApeStart) {
            require((boredApes.balanceOf(_to) > 0 || mutantApes.balanceOf(_to) > 0 || zenAcademy.balanceOf(_to, 1) > 0 || zenAcademy.balanceOf(_to, 333) > 0), "Must own BAYC, MAYC, or ZA token to mint during Ape presale");
        } else {
            require(false, "Pre-sale has not started yet");
        }


        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxEthWalkers) {
                _safeMint(_to, mintIndex);
            }
        }
        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function mintETHWalkers(uint numberOfTokens) external payable {
        require(saleState >= 1, "Sale must be active to mint");
        require(numberOfTokens > 0 && numberOfTokens <= maxETHWalkersPurchase, "Oops - you can only mint 20 ETHWalkers at a time");
        require(msg.value >= _eTHWalkersPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= maxEthWalkers, "Purchase exceeds max supply of ETHWalkers");
        require(block.timestamp >= publicSale, "Public sale not started");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxEthWalkers) {
                _safeMint(msg.sender, mintIndex);
            }
        }
        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function isContract(address _addr) private view returns (bool){
          uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }

}