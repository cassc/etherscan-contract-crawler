// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OopsIDidItAgain is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    uint256 public immutable TOTAL_TOKENS;
    uint256 public TOTAL_MINT_MAX_PER_ADDR = 2;
    uint256 public FREE_NUMBER = 300;

    // mint related
    uint256 public MINT_PRICE = 0.008 ether;

    // private
    string private _baseTokenURI;
    Counters.Counter private _tokenIds;

    constructor(
        uint256 total_tokens,
        string memory base_uri,
        uint256 mint_price,
        uint256 free_number
    ) ERC721("Oops I Did It Again", "OIDIA") {
        TOTAL_TOKENS = total_tokens;
        _baseTokenURI = base_uri;
        MINT_PRICE = mint_price;
        FREE_NUMBER = free_number;
        _pause();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function Mint(uint256 number) external payable whenNotPaused{
        require(number >= 1, "Number is 0");
        require(balanceOf(msg.sender) + number <= TOTAL_MINT_MAX_PER_ADDR, "Beyond max number of tokens");
        require(totalSupply() + number <= TOTAL_TOKENS, "Sold out");
        if (_tokenIds.current() + number > FREE_NUMBER){
            uint256 pay_number = number;
            if (_tokenIds.current() < FREE_NUMBER){
                pay_number = number - (FREE_NUMBER - _tokenIds.current());
            }
            require(MINT_PRICE * pay_number <= msg.value, "Invalid payment amount");
        }
        for (uint256 i = 0; i < number; i++) {
            uint256 currentTokenId = _tokenIds.current() + 1;
            _tokenIds.increment();
            _safeMint(msg.sender, currentTokenId);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    function setMintPrice(uint256 price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setBaseURI(string memory base_uri) external onlyOwner{
        _baseTokenURI = base_uri;
    }
}