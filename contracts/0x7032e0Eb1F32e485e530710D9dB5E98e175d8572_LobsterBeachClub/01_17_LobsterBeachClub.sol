// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title LobsterGenome interface
* @dev Describes the external LobsterGenome contract that handles lobster traits logic
*/
interface ILobsterGenome {
    function getGeneSequence(uint256 tokenId) external view returns (uint256 geneSequence);
    function getAssets() external view returns(uint16[] memory assets);
}

/**
* @title LobsterBeachClub contract
* @dev Extends ERC721 Non-Fungible Token Standard with enumeration and URIStorage
*/
contract LobsterBeachClub is VRFConsumerBase, ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    uint256 public maxSupply; // needed public for LobsterGenome
    uint256 public seedNumber; // needed public for LobsterGenome
    
    string internal baseURI;

    bytes32 internal keyHash;
    uint256 internal linkFee;

    uint16 internal maxPurchase;
    uint256 internal mintingFee;

    uint256 internal maxPresaleSupply;
    uint256 internal revealDate;
    uint256 internal presaleStartingSupply;

    bool internal saleIsActive;
    bool internal presaleIsActive;
    bool internal seedNumberRequested;
    bool internal seedNumberSet;

    mapping(uint256 => uint256) internal promoLobster;
    mapping(address => bool) internal isWhitelisted;

    event SeedRequested(bool _value);
    event SeedSet(bool _value, uint256 _seedNumber);
    event PresaleState(bool _value, uint256 _startingSupply);
    event SaleState(bool _value);
    event Whitelist(address indexed _address, bool _value);
    event Minted(uint256 _value);
    event RevealTime(uint256 _time);
    event MintFee(uint256 _value);

    // External contract to fetch lobster genes from
    ILobsterGenome public lobsterGenome;
    
    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) ERC721Enumerable() VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        mintingFee = 0.085 * 10 ** 18;
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        linkFee = 2 * 10 ** 18; // 2 LINK required to call VRF
        baseURI = "https://pegnc1ml7b.execute-api.us-west-1.amazonaws.com/api/lobsters/";
        maxSupply = maxNftSupply;
        maxPresaleSupply = 1500;
        maxPurchase = 20;
        revealDate = saleStart + (86400 * 9); // 9 days from start
        emit RevealTime(revealDate);
        emit MintFee(mintingFee);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    function setLobsterGenome(address lgAddress) public onlyOwner {
        lobsterGenome = ILobsterGenome(lgAddress);
    }

    /**
    * @dev Set the minting fee
     */
    function setMintingFee(uint256 _mintingFee) public onlyOwner {
        mintingFee = _mintingFee;
        emit MintFee(mintingFee);
    }

    /**
    * @dev Start state of presale or sale
    */
    function setSaleState(bool _presale, bool _val) public onlyOwner {
        if (_presale) {
            presaleIsActive = _val;
            if (_val) {
                presaleStartingSupply = totalSupply();
            }
            emit PresaleState(_val, presaleStartingSupply);
        } else {
            saleIsActive = _val;
            emit SaleState(_val);
        }
    }

    /**
    * @dev Add or remove addresses from presale whitelist
    */
    function whitelist(address[] memory addresses, bool _val) public onlyOwner {
        for (uint i; i < addresses.length; i++) {
            isWhitelisted[addresses[i]] = _val;
            emit Whitelist(addresses[i], _val);
        }
    }

    /**
    * @dev Reserve some lobsters for these addresses
    */
    function reserveLobsters(address[] memory addresses) public onlyOwner {
        for(uint i; i < addresses.length; i++) {
            uint256 lobsterId = totalSupply();
            _mint(addresses[i], lobsterId);
            _setTokenURI(lobsterId, uint2str(lobsterId));
        }
        emit Minted(totalSupply());
    }

    /**
    * @dev Create promo lobsters for these addresses
    * @dev Promo lobsters are lobsters with predefined geneSequences
    * @dev Promo lobsters are non-transferrable so they're kept track of in a mapping
    */
    function createPromoLobsters(uint256[] memory geneSequences, address[] memory addresses) public onlyOwner {
        require(geneSequences.length == addresses.length, "Argument lengths must be equal");
        for(uint i = 0; i < geneSequences.length; i++) {
            uint256 lobsterId = totalSupply();
            _mint(addresses[i], lobsterId);
            _setTokenURI(lobsterId, uint2str(lobsterId));
            promoLobster[lobsterId] = geneSequences[i];
        }
        emit Minted(totalSupply());
    }

    /**
    * @dev Mint lobsters to an address
    * @dev Presale must be active or sale must be active to mint
    * @dev To mint during presale the msg.sender must be whitelisted and can't exceed presaleStartSupply + maxPresaleSupply
    * @dev To mint you must provide minting fee for each token requested and cannot exceed max token supply
    * @dev If minting after reveal date or minting last available supply, submit request from Chainlink VRF
    * @dev If maxSupply reached then sale is no longer active
    * @dev If presaleStartingSupply + maxPresaleSupply is reached then presale is no longer active
    */
    function mint(uint256 numberOfTokens, address _to) public payable {
        require(numberOfTokens <= maxPurchase, "Exceeded the max purchase amount");
        if (presaleIsActive) {
            require(isWhitelisted[msg.sender], "Not whitelisted");
            require(totalSupply() + numberOfTokens <= presaleStartingSupply + maxPresaleSupply, "Exceeded max presale supply");
        } else {
            require(saleIsActive, "Sale must be active");
        }
        require(mintingFee * numberOfTokens <= msg.value, "Mint fee is not correct");
        require(totalSupply() + numberOfTokens <= maxSupply, "Purchase would exceed max supply");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint256 lobsterId = totalSupply();
            _mint(_to, lobsterId);
            _setTokenURI(lobsterId, uint2str(lobsterId));
        }
        emit Minted(totalSupply());

        if (!seedNumberRequested && (totalSupply() >= maxSupply || block.timestamp >= revealDate)) {
            getRandomNumber();
        }

        if (totalSupply() >= maxSupply) {
            saleIsActive = false;
            setSaleState(false, false);
        } else if (presaleIsActive && (totalSupply() >= (presaleStartingSupply + maxPresaleSupply))) {
            presaleIsActive = false;
            setSaleState(true, false);
        }
    }

    /**
    * @dev Gives contract owner ability to manually request seed number from Chainlink VRF
    */
    function emergencySetSeedNumber() public onlyOwner {
        getRandomNumber();
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        revealDate = revealTimeStamp;
        emit RevealTime(revealDate);
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /**
    * @dev Get the gene sequence of a lobster if seedNumberSet / lobsters are revealed
    * @dev If lobster is a promo, then return preset gene sequence
    * @dev Gene sequencing logic is outsourced to external LobsterGenome contract
    */
    function getLobster(uint256 tokenId) public view returns (uint256 geneSequence) {
        require(seedNumberSet, "Seed number is not set");
        require(_exists(tokenId), "Token id does not exist");
        if (promoLobster[tokenId] != 0) {
            return promoLobster[tokenId];
        }
        return lobsterGenome.getGeneSequence(tokenId);
    }

    /**
    * @dev Callback function for Chainlink VRF
    * @dev Randomness is set as the seedNumber, revealing all Lobsters
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        seedNumber = randomness;
        seedNumberSet = true;
        emit SeedSet(true, seedNumber);
    }

    /**
    * @dev Request a random number from Chainlink VRF
    */
    function getRandomNumber() internal {
        require(LINK.balanceOf(address(this)) > linkFee && !seedNumberSet, "Not enough LINK or seed set already");
        requestRandomness(keyHash, linkFee);
        seedNumberRequested = true;
        emit SeedRequested(true);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(promoLobster[tokenId] == 0, "Token id is non-transferrable");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        return super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
}