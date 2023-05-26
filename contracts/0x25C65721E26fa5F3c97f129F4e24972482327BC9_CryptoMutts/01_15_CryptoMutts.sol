// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//@version 0.3.0

import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CryptoMutts is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //Team
    address tm0 = 0xDc3Ee5969611a47C4Bd4ef088a55E1ba61701827;   //RvNhMn
    address tm1 = 0xA3BDaa505a72FC6B3e15E69Ac1577aEcd0E2736b;   //T.O.
    address tm2 = 0xb2EB33Fcd965C6635015b1D9E623717AC283FB11;   //K.

    string baseTokenURI;
    string constant PROVENANCE_HASH = "467126fbe3892c5eb3dc1d02d84f1620d974dd71adf2937f92703a05c2fe386b";

    uint private constant MAX_TOKENS = 10**4;       //10,000 Mutts
    uint private constant TXN_MINT_LIMIT = 50;      //50 per txn
    uint private mintPrice = 30000000 gwei;         //0.03 Ether
    bool private salePaused = true;

    constructor(string memory _baseTokenURI) ERC721("CryptoMutts", "CMUTT") {
        setBaseURI(_baseTokenURI);
    }

    function isSalePaused() public view returns (bool) {
        return salePaused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint) {
        return mintPrice;
    }

    function setPrice(uint _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function walletOfTokenOwner(address _tokenOwner) public view returns(uint[] memory) {
        uint tokenCount = balanceOf(_tokenOwner);

        uint[] memory tokensId = new uint[](tokenCount);
        for(uint i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_tokenOwner, i);
        }
        return tokensId;
    }

    function getMaxTokens() public pure returns (uint) {
        return MAX_TOKENS;
    }

    function getProvenance() public pure returns (string memory) {
        return PROVENANCE_HASH;
    }

    function putANameOnIt() public pure returns (string memory) {
        return "Project by Kenny Schachter.";
    }

    function saleToggle() public onlyOwner {
        salePaused = !salePaused;
    }

    function publicMint(uint _amount) public payable {
        uint _supply = totalSupply();

        require( !salePaused,                       "Contract is paused." );
        require( _amount > 0,                       "Must mint at least 1 Mutt");
        require( _supply + _amount <= MAX_TOKENS,   "Exceeds maximum token supply." );
        require( _amount <= TXN_MINT_LIMIT,         "Limited to 50 mints per transaction.");
        require( msg.value >= mintPrice * _amount,  "Ether sent is not correct for token price." );

        for(uint i; i < _amount; i++){
            _safeMint(msg.sender, _supply + i);
        }
    }

    function reservedMint(uint _amount) public payable {
        uint _supply = totalSupply();

        require( msg.sender == owner()
          || msg.sender == tm0
          || msg.sender == tm1
          //Assurance
          || msg.sender == tm2
        );

        require( _supply + _amount <= MAX_TOKENS,   "Exceeds maximum token supply.");

        for(uint i; i < _amount; i++){
            _safeMint(msg.sender, _supply + i);
        }
    }

    /**
    * Payout with withdrawal pattern
    */
    function withdraw() public payable onlyOwner {
        uint tenthCut = address(this).balance / 10;
        uint quarterCut = address(this).balance / 4;

        payable(tm0).send(tenthCut);                            //RvNhMn
        payable(tm1).send(quarterCut);                          //T.O
        payable(msg.sender).transfer(address(this).balance);    //Remainder to owner
    }

    /**
     * Recover any ERC20 tokens sent to contract
     */
    function withdrawTokens(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0));

        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
}