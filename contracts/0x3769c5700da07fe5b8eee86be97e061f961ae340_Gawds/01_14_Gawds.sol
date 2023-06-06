// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/****************************************************************************

       ....        .                                     ..          .x+=:.
   .x88" `^x~  xH(`                 x=~               dF           z`    ^%
  X888   x8 ` 8888h                88x.   .e.   .e.  '88bu.           .   <k
 88888  888.  %8888         u     '8888X.x888:.x888  '*88888bu      [email protected]"
<8888X X8888   X8?       us888u.   `8888  888X '888k   ^"*8888N   [email protected]^%8888"
X8888> 488888>"8888x  [email protected] "8888"   X888  888X  888X  beWE "888L x88:  `)8b.
X8888>  888888 '8888L 9888  9888    X888  888X  888X  888E  888E 8888N=*8888
?8888X   ?8888>'8888X 9888  9888    X888  888X  888X  888E  888E  %8"    R88
 8888X h  8888 '8888~ 9888  9888   .X888  888X. 888~  888E  888F   @8Wou 9%
  ?888  -:8*"  <888"  9888  9888   `%88%``"*888Y"    .888N..888  .888888P`
   `*88.      :88%    "888*""888"    `~     `"        `"888*""   `   ^"F
      ^"~====""`       ^Y"   ^Y'                         ""

                            https://gawds.xyz
                     A Definitely Friends Production
                            HC SVNT DRACONES
                                  2021

***************************************************************************/

contract Gawds is Context, Ownable, ERC721, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    uint private _price;

    uint public maxSupply;
    bool public saleStarted = false;
    bool public baseURILocked = false;

    uint public constant maxStaffGawds = 200;
    uint public staffGawdsMintCount = 0;
    uint public constant maxPresaleGawds = 200;
    uint public presaleGawdsMintCount = 0;

    address public constant staffVaultAddress = 0x77De7bE18eec5C3c1B1a874816506ea594A5B1D7;

    event SaleState(bool);
    event BaseURILocked(bool);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint maxSupply_,
        uint price_)
        ERC721(name_, symbol_)
    {
        _baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
        _price = price_;

        _tokenIdTracker.increment(); // start at index 1
    }

    function calculatePrice() public view returns (uint256) {
        return _price;
    }

    function mint(address to) internal {
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function staffMint(uint count) public onlyOwner {
        require(totalSupply() + count <= maxSupply, "would exceed max supply");
        require(staffGawdsMintCount + count <= maxStaffGawds, "would exceed maxStaffGawds");
        for (uint i = 0; i < count; i++) {
            mint(staffVaultAddress);
            staffGawdsMintCount++;
        }
    }

    function presaleMint(address[] memory recipients) public virtual onlyOwner {
        require(totalSupply() + recipients.length <= maxSupply, "would exceed max supply");
        require(presaleGawdsMintCount + recipients.length <= maxPresaleGawds, "would exceed maxPresaleGawds");
        for (uint i = 0; i < recipients.length; i++) {
            address addr = recipients[i];
            mint(addr);
            presaleGawdsMintCount++;
        }
    }

    function summon(uint256 summonCount) public payable {
        require(saleStarted, "cannot summon before sale has started");
        require(summonCount > 0 && summonCount <= 10, "minimum 1, maximum 10 per transaction");
        require(msg.value >= calculatePrice() * summonCount, "sent insufficient Ether");
        require(totalSupply() + summonCount <= maxSupply, "would exceed max supply");

        for (uint i = 0; i < summonCount; i++) {
            mint(msg.sender);
        }
    }

    function startSale() public virtual onlyOwner {
        require(!saleStarted, "sale already started");
        emit SaleState(true);
        saleStarted = true;
    }

    function stopSale() public virtual onlyOwner {
        require(saleStarted, "not currently started");
        emit SaleState(false);
        saleStarted = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public virtual onlyOwner {
        require(!baseURILocked, "setBaseURI is locked");
        _baseTokenURI = baseTokenURI;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
        emit BaseURILocked(true);
    }

    function withdrawAll() public payable onlyOwner
    {
        uint balance = address(this).balance;
        // solhint-disable-next-line indent
        payable(staffVaultAddress).transfer(balance);
    }

    // function overrides required by Solidity
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}