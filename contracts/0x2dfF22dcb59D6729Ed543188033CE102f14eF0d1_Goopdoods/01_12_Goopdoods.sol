/*
SPDX-License-Identifier: GPL-3.0

                                            GOOPDOODS


xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddoolc:::cclodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc;,''',,,,,,,'''',:ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdo:'.':cloddxxxxxddoc;,.':odxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdo;..;ldxxxxdolcccclodxxdo:'.;oxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc..;oxxdoc:;..      ..,cdxxdc'.:dxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:..ldxdl;;,.             'cdxxo,.;dxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:..lxxo:,oKKkl.   .'.     ;c:oxxo,.cxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl..cxxo,;OWMWWO.   'd,    'OXd;lxxl.'oxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,.;dxd,,OWMMWXo.   'd;   'OWMNl,lxd'.lxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo..lxxl'oWMMMMMXc   .l,   ;KMMMO,;dd,.cxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl..oxxl'oWMMMMMWx,:ol:.   .OMMMK;,dd;.:dxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl..lxxd,:KMMMMMXxlol;,.   ,KMMM0,,dd,.:xxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo'.;dxxl,oNMMMMXl.   cc   ,KMMNo'cxo'.cxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc..cxxdc,dNMMMM0'   ..   cXMXo':dd:.'oxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:..ldxdc,oXMMMKc.     .oXW0:'cddc..lxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:..:dxxo::dOKNW0c.  .o0Ol,;oxd:.'ldxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc..:dxxdl:::codxoc::c;,;lddl'.;oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd; 'oxxxxxxdol:::::cloddoc,.'cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddoc;..;dxxxxxxxxxxxxxxxxdc,'';cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxddoc:;,,'''',;ldxxxxxxxxxxxxxxxxxl..cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxdl:,''''',;:clodxxxxxxxxxxxxxxxxxxxxxl..cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxo:'.';:loddxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl;'';codxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxl'.,ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc;,',:ldxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxo'.;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdo:,.,ldxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxd,.;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxdl'.:dxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxx:.'oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo'.cxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxo'.:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.,dxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxc..oxxxxxxxxxxxdodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo'.lxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxd;.;dxxxxxxxxxxxocoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddxxxxxd,.:xxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxo'.cxxxxxxxxxxxdc:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxocoxxxxxx:.,dxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxc..oxxxxxxxxxxxd;:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:lxxxxxxl.'oxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxd,.;dxxxxxxxxxxxl,cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:cxxxxxxo'.cxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxl..cxxxxxxxxxxxd:'lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd::dxxxxxd,.:dxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxd:.'oxxxxxxxxxxxd,'oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:;dxxxxxx:.,dxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxo' ;dxxxxxxxxxxxl.,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:,oxxxxxxc..oxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxc..lxxxxxxxxxxdd:.;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc,cxxxxxxo..cxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxd; 'oxxxxxxxxxxxd,.:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl':xxxxxxd,.;dxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxo. ;dxxxxxxxxxxxl..lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo';dxxxxxd:.'oxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxc..lxxxxxxxxxxxd:..oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo,,oxxxxxxc..lxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxd; 'oxxxxxxxxxxxd' 'dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,'lxxxxxxl..cxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxo..;dxxxxxxxxxxxl. ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;.cxxxxxxo'.:dxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxc..lxxxxxxxxxxxd:  :dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:.:xxxxxxd; ,dxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxd, 'oxxxxxxxxxxxd, .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.,dxxxxxd:.'oxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxo' ;dxxxxxxxxxxxo. .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.'dxxxxxx:..lxxxxxxxxxxxxxxxxxxx*/

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Goopdoods is ERC721A, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isGoopListActive = false;
    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN = .05 ether;

    mapping(address => uint8) private _goopList;

    constructor() ERC721A("Goopdoods", "GOOPDOOD") {
    }

    function setIsGoopListActive(bool _isGoopListActive) external onlyOwner {
        isGoopListActive = _isGoopListActive;
    }

    function setGoopList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _goopList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _goopList[addr];
    }

    function mintGoopList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isGoopListActive, "Gooplist is not active");
        require(numberOfTokens <= _goopList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _goopList[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
        _safeMint(msg.sender, n);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}