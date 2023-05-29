// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title ERC721 NFT for TP
/// @author PonziCoin, Kyle Stargarden, penguin
/// @dev Built using output from the OpenZeppelin Contracts Wizard: https://wizard.openzeppelin.com/#erc721
/// @notice Rainbow Roll (ROLLS) NFTs are in short supply. Get them while they last.

interface FungibleTokens {
    function balanceOf(address account) external view returns (uint256);
}

contract NFTP is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseTokenURI;
    string public METADATA_PROVENANCE_HASH;
    uint256 public maxMint = 20;
    uint256 public price = 1337 * 10**14; //0.1337 ETH;
    bool public salePaused = true;
    bool public presalePaused = true;
    uint public constant MAX_ENTRIES = 10000;
    uint public constant MAX_PRESALE = 1520;
    address promoAddress;

    address[] public whitelistERC721;
    address[] public whitelistERC20;
    uint[] public requiredERC20;


    constructor() ERC721("Rainbow Rolls", "ROLLS") {
        setBaseURI("http://nftp.fun/rolls/");
        // Team gets 25 and 75 are minted for promo and giveaways
        _tokenIdCounter.increment();
        promoAddress = 0x48B8cB893429D97F3fECbFe6301bdA1c6936d8d9;
        mint(promoAddress, 100);

        whitelistERC721 = [
        0xf1eF40f5aEa5D1501C1B8BCD216CF305764fca40,
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D,
        0x711d2aC13b86BE157795B576dE4bbe6827564111,
        0x30d5977e4C9B159C2d44461868Bdc7353C2e425b,
        0x7F0AB6a57cfD191a202aB3F813eF9B851C77e618,
        0xE203cDC6011879CDe80c6a1DcF322489e4786eB3,
        0x8b13e88EAd7EF8075b58c94a7EB18A89FD729B18,
        0xf7E1FEEf85B9c2337A087439AbF364b9DD21a562];

        whitelistERC20 = [
        0x1e3a2446C729D34373B87FD2C9CBb39A93198658,
        0xa6610Ed604047e7B76C1DA288172D15BcdA57596,
        0x26FA3fFFB6EfE8c1E69103aCb4044C26B9A106a9,
        0x2d94AA3e47d9D5024503Ca8491fcE9A2fB4DA198,
        0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F,
        0x5dD57Da40e6866C9FcC34F4b6DDC89F1BA740DfE,
        0xD56daC73A4d6766464b38ec6D91eB45Ce7457c44,
        0x87b008E57F640D94Ee44Fd893F0323AF933F9195,
        0x3472A5A71965499acd81997a54BBA8D852C6E53d,
        0x34A01C0A95B0592cc818Cd846c3Cf285d6C85A31,
        0x6b4d5e9ec2aceA23D4110F4803Da99E25443c5Df];

        requiredERC20 = [
        200000000000000000000,
        1000000000000000000,
        100000000000000000000000,
        10000000000000000000000,
        100000000000000000000,
        500000000000000000000,
        2000000000000000000000,
        100000000000000000000,
        40000000000000000000,
        8000000000000000000,
        1000000000000000000];
    }

    /**
     * @dev Public function for purchasing {num} amount of tokens. Checks for current price. 
     * Calls mint() for minting processs
     * @param _to recipient of the NFT minted
     * @param _num number of NFTs minted (Max is 20)
     */
    function buy(address _to, uint256 _num) 
        public 
        payable 
    {
        require(!salePaused, "Sale hasn't started");
        require(_num < (maxMint+1),"You can mint a maximum of 20 NFTPs at a time");
        require(msg.value >= price * _num,"Ether amount sent is not correct");
        mint(_to, _num);
    }

    /**
     * @dev Public function for purchasing presale {num} amount of tokens. Requires whitelistEligible()
     * Calls mint() for minting processs
     * @param _to recipient of the NFT minted
     * @param _num number of NFTs minted (Max is 20)
     */
    function presale(address _to, uint256 _num)
        public
        payable
    {
        require(!presalePaused, "Presale hasn't started");
        require(whitelistEligible(_to), "You're not eligible for the presale");
        require(_num < (maxMint+1),"You can mint a maximum of 20 NFTPs at a time");
        require(msg.value >= price * _num,"Ether amount sent is not correct");
        mint(_to, _num);
    }

    /**
     * @dev Private function for minting. Should not be called outside of buy(), presale() or the constructor
     * Wraps around _safeMint() to enable batch minting
     * @param _to recipient of the NFT minted
     * @param _num number of NFTs minted
     */
    function mint(address _to, uint256 _num)
        private
    {
        require(_tokenIdCounter.current() + _num < MAX_ENTRIES, "Exceeds maximum supply");
        for(uint256 i; i < _num; i++){
          _safeMint( _to, _tokenIdCounter.current());
          _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Public function for checking whitelist eligibility.
     * Called in the presale() function
     * @param _to verify address is eligible for presale
     */
    function whitelistEligible(address _to)
        public
        view
        returns (bool)
    {
        if(_ERC721Eligible(_to) || _ERC20Eligible(_to)) {
            return true;
        }
        else {
            return false;
        }
    }

    /**
     * @dev Private helper function returning eligibility for presale
     * @param _to address to check balanceOf() ERC721
     */
    function _ERC721Eligible(address _to)
        private
        view
        returns (bool)
    {
        for (uint i=0; i < whitelistERC721.length; i++) {
            if (IERC721(whitelistERC721[i]).balanceOf(_to) > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Private helper function returning eligibility for presale
     * @param _to address to check balanceOf() ERC20 against requirements
     */
    function _ERC20Eligible(address _to)
        private
        view
        returns (bool)
    {
        for (uint i=0; i < whitelistERC20.length; i++) {
            if (FungibleTokens(whitelistERC20[i]).balanceOf(_to) >= requiredERC20[i]) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Function for setting the BaseURI.
    * Intended for onlyOwner to call in the case the URI details need to be relocated
    */
    function setBaseURI(string memory _baseTokenURI)
        public
        onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    * @dev Function for reading total minted Rainbow Rolls
    * Intended for displaying Rainbow Roll minting stats during sale
    */
    function totalCount()
        external
        view
        returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
    * @dev Function for overriding behavior of _baseURI() virtual function from ERC721 base contract
    */
    function _baseURI()
    internal
    view
    override
    returns (string memory) {
        return baseTokenURI;
    }

    /**
    * @dev Function for setting provenance hash which verifies no data was altered during or after sale
    * Helps provide added security for staged metadata and asset uploading during sale
    * @param _hash signature of the entire collection's assets and metadata
    */
    function setProvenanceHash(string memory _hash)
        public
        onlyOwner
    {
        METADATA_PROVENANCE_HASH = _hash;
    }

    /** @dev Function for withdrawing sale ETH
    * Allows hungry monkeys to taste the bananas
    */
    function withdrawAll()
        public
        onlyOwner
    {
        require(payable(owner()).send(address(this).balance));
    }

    /**
     * @dev Function for the owner to start or pause the sale depending on {bool}.
     */
    function setSalePauseStatus(bool val)
        public
        onlyOwner
    {
        salePaused = val;
    }

    /**
     * @dev Function for the owner to start or pause the presale depending on {bool}.
     */
    function setPresalePauseStatus(bool val)
        public
        onlyOwner
    {
        presalePaused = val;
    }
}