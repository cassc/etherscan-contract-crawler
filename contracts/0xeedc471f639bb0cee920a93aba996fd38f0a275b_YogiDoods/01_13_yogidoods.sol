// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
....................................................................................................
....................................................................................................
....................................................................................................
..................------------......................................................................
...........-..----------------------://+oossssssoo++/::-............................................
......-.----------------------:+syyyso+/::-------:/++osyys-.........................................
....----------------------:+yys+:.`                    `.yh-........................................
..---------------------:+yyo-`                           `hh........................................
----------------------sho-                                `dy.......................................
---------------------dy.                                   .mo-.....................................
------------------:sdM.                                     -Nmhs:..................................
-----------------ymosm                                       /N//hd+................................
---------------:my..hy                 `-://+ooossssooo++.    om+.:dh...............................
---------------dh...N+         `-/oyyyyso+/::-........--:.     .+hhodd..............................
--------------/M:..-M-     ./syyo/-`                              .+hMs.............................
--------------+M.../M`   :hs/.`                                      -sdo...........................
--------------:M/..ym    ``                                         ``.:hmo.........................
---------------ym:hy.                             ``.--::/+ooosssyhmhhyyydNd........................
----------------dmo`                   `.--:+oossyyyssoo++/:::----:Ny//oydy:........................
---------------om:             `.-/+osyysso+/::--................../Nhhhsssso:......................
--------------sd-       ``.:+oyyss+/:-..............-:/+++++::-.....sN:+m+::/ds.....................
-------------yd.   `.-+oyyso/:-.....-+++/-......-/syhyssoosssyhyo:..-M/:/....:/......-:++/-.........
------------sm-`:+shdNh:...........odo/+yd:...-sdy+:--/dmmmmo--/ohh/.No............-shs++ohh-.......
-----------+Mhhhyso+/hd............s/....o/..+ms:-----oNMMMMy-----+mydd...........om+......M+.......
-----------mms+//////yM.....................sm/--------/ymds-::----:dddh.........yd-......yd-......-
-----------ymyo+////oN+....................+N/-----:ydhhdyshdhhmo---:MoN+.......ym-...../my-......--
------------:oyhhdddNh.....................dy------dh----/+:---oM:---dydy......oN-.....sN/.......---
--------------------No.....................ms------M+-/ooo+/---sN----msdy.....:N/.....oNshh/....----
--------------------No.....................yd------Nmhs+++oydo:Ns---oN:N+.....dh-::-..d/../dy.------
--------------------hh.....................-my-----ym:......:dNy---oN+yd..../ymhyssyhyo-...:M:------
--------------------/N/.....................:dh/---:hd+-...-oms--/hd/sm:../dy/-......:sd/..sNy:-----
---------------------sm:......................ohh+:--+yhyyyhy+/ohh+/hh:..+m/...y:....../Nshs:om/----
----------------------omo......................./shyysoossyyyhyo::sdo-...No....ods/---:oN/-...my----
----------------.------:hd+-.......................-:/++++//:--/hdo-....:M:.....-+smhymd:...-oN+----
.......................:hdyhs/-...........................-:+yhyym:.....-Ns.....-/yd-.:yhsoydh/-----
......................-dh--:+yhyo+:--..............---/+syhyo/---my...--+mmo....ss/.....-/dm/-------
......................-M+------:+oyhhhyyysssssyyyhhhyys+/:------:No----ym/:yd+-.........:hh:--------
......................:md:-------------:://///::--------------:smy--:sms----:sdy+:-.-:ohd+----------
....................:hdoodds+:-----------------------------/sddshmhdho---------:osydMyo:------------
...................sm+-----/sy:-------------------------+ydho:::+mN/--------------+No---------------
..................yd:-------------------------------/shdy+:::/ydh++N+------------sm+----------------
.................yd:----------------------------:+ydho/:::/sdho:---+N/---------/dh/-----------------
................sm:--------------------------/shhy+/:::/sdho:-------ym-------:sdo:----------------::
.............../N/-----------------------:+yhyo/:::::::+Ny----------:N+----:sds:----------:---:::-::
..............-ms--------------------:+shhs+/:::::+ss/::+my----------hd-:+yhs/-------:::::::::::::::
..............yd-----------s:----:/shhyo/:::::/+yhhmmdo::+N+---------/Mhhy+:---:::::::::::::::::::::
.............+N:----------oN::+shhyo/::::::/oyhyo/:dy-dy::ym----------Ny::::::::::::::::::::::::::::
............-No-----------mmhhyo/::::::/+shhy+:::::sm:yd::sN----------hh::::::::::::::::::::::::::::
............hh-----------+M+::::::::/oydho/:::::::::oso/::dh----------sm::::::::::::::::::::::::::::
```````````+N:-----------mh:::::/+yhdy+::::::::::::::::::sN:----------oN::::::::::::::::::::::::::::
``````````-No-----------+M/::::odyo/:::::::::::::::::::/hd:-----------oM::::::::::::::::::::::::::::
``````````hh------------dh::::::::::::::::::::::::::/sddo-------------+M::::::::::::::::::::::::::::
*/

contract YogiDoods is ERC721Enumerable, Ownable
{
    using Strings for string;

    uint public MAX_TOKENS = 5555;
    uint256 public PRICE = 30000000000000000; //0.03 ether

    uint public maxInTx = 10;

    bool public saleIsActive = false;
    bool public revealed = false;

    string private _baseTokenURI;
    string public notRevealedUri;

    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    constructor() ERC721("Yogi Doods", "YD") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= maxInTx, "Max NFTs per transaction violation");
        require(totalSupply() + amount <= MAX_TOKENS, "Purchase would exceed max supply");
        require((totalSupply() < 555) || msg.value >= PRICE * amount, "Not enough ETH for transaction");

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }

    function setMaxInTx(uint num) public onlyOwner
    {
        maxInTx = num;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function reserve(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= MAX_TOKENS, "Purchase would exceed max supply");
        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function withdraw() external
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = devguy.call{value: address(this).balance / 100 * 5}("");
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////
    //URI management part
    ////

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false)
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}