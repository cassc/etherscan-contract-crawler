// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.17;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/Base64.sol";


// @author: Bård Ionson
// @website: bardIonson.com
// @SoulScroll1
// Soul Scroll will send your supplications directly to God. Funds collected for the prayers are invested to maintain the work of the Council of Jacob. 
// Store up your wealth in heaven were it cannot be corrupted. Praise be. 
// The machine will select from various types of prayers for the good of the community of Christ. You may request special prayers be added to the 
// machines memory by contacting a Son of Jacob who will add it to the machine. At some point in the future when someone orders a new prayer your
// prayer request will fly to the heavens. Be generous with the number of times a prayer is read because it may be the prayer of your family or friend.

contract Prayer is ERC721, ERC721URIStorage, ERC721Burnable, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    uint256 public mintPrice;
    uint256 public initPrice;
    uint8 public prayersUsed;
    uint8 public prayersLoaded;
    uint8 public maxOrder;
    mapping(address => bool) public allowedAddresses;
    mapping(address => bool) public initiatedAddresses;

    struct ThePrayer {
        string prayerType;
        string text;
        string text2;
        string text3;
        string author_name;
        address payable sonOfJacob;
    }
    mapping(uint256 => ThePrayer) public prayers;

    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("Soul Scroll", "SOUL")  {
        _setDefaultRoyalty(msg.sender ,1000);
        mintPrice = 10000000000000000;
        initPrice = 100000000000000000; 
        maxOrder = 20;
        addSonOfJacob(msg.sender);
        initiatedAddresses[msg.sender] = true;
        createPrayer(unicode"Health 🏥", "Lord master, I ask that you fulfil your promise to me by", "restoring me to health and healing my wounds.", "Amen", "Bard Ionson", msg.sender);
        createPrayer(unicode"Birth 👶", "Give us a quiverfull of children and subdue the earth with","your power o great warrior Father", "Amen", "Bard Ionson", msg.sender);
        createPrayer(unicode"Wealth 💸", "God make Gilead Great Again and Again","to subdue the earth", "Amen", "Bard Ionson", msg.sender);
    }

    modifier isAllowedToPray(address _address) {
        require(allowedAddresses[_address], "You need to be listed for the Initiation");
        _;
    }


    function addSonOfJacob(address _addressToAllowlist) public onlyOwner {
        allowedAddresses[_addressToAllowlist] = true;
    }

    function verifySonOfJacob(address _allowedAddress) public view returns(bool) {
        bool sonCanPray = allowedAddresses[_allowedAddress];
        return sonCanPray;
    }

    modifier isInitiated(address _address) {
        require(initiatedAddresses[_address], "You need pay the initiation dues");
        _;
    }

    function excommunicate(address _addressToRemove) public onlyOwner {
        initiatedAddresses[_addressToRemove] = false;
        allowedAddresses[_addressToRemove] = false;
    }

    function payInitiation(address _addressToAllowlist) public payable isAllowedToPray(msg.sender) {
        require(msg.value >= initPrice, "Not enough ETH sent; check price!");
        initiatedAddresses[_addressToAllowlist] = true;
        payable(owner()).transfer(msg.value);
    }

    function verifyIntitiation(address _allowedAddress) public view returns(bool) {
        bool sonCanPray = initiatedAddresses[_allowedAddress];
        return sonCanPray;
    }

    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function setInitPrice(uint256 _newPrice) public onlyOwner {
        initPrice = _newPrice;
    }

    function setMaxOrder(uint8 _newMaxOrder) public onlyOwner {
        maxOrder = _newMaxOrder;
    }
  
    function sonCreatePrayer(string memory _prayerType, string memory _prayer, string memory _prayer2, string memory _prayer3, string memory _author_name, address _author)
        public isInitiated(msg.sender) {
            if (_author == address(0))
                _author = msg.sender;
            require(sLen(_prayerType) <= 20, "Type 20 character limit");
            require(sLen(_prayer) <= 62 && sLen(_prayer2) <= 62  && sLen(_prayer3) <= 62 , "Line 62 character limit.");
            createPrayer(_prayerType, _prayer, _prayer2, _prayer3, _author_name, _author);
    }

    function sLen(string memory s) internal pure returns (uint length) {
        uint i=0;
        bytes memory stringRep = bytes(s);

        while (i<stringRep.length)
            {
                if (stringRep[i]>>7==0)
                    i+=1;
                else if (stringRep[i]>>5==bytes1(uint8(0x6)))
                    i+=2;
                else if (stringRep[i]>>4==bytes1(uint8(0xE)))
                    i+=3;
                else if (stringRep[i]>>3==bytes1(uint8(0x1E)))
                    i+=4;
                else
                    //For safety
                    i+=1;

                length++;
            }
        return length;
    }

    function createPrayer(string memory _prayerType, string memory _prayer1, string memory _prayer2, string memory _prayer3, string memory _author_name, address _author) internal {
        prayers[prayersLoaded].prayerType = _prayerType;
        prayers[prayersLoaded].text = _prayer1;
        prayers[prayersLoaded].text2 = _prayer2;
        prayers[prayersLoaded].text3 = _prayer3;
        prayers[prayersLoaded].author_name = _author_name;
        prayers[prayersLoaded].sonOfJacob = payable(_author);
        prayersLoaded++;
    }

        /* Converts an SVG to Base64 string */
    function svgToImageURI(string memory svg)
        internal
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(svg));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /* Generates a tokenURI using Base64 string as the image */
    function formatTokenURI(string memory imageURI, string memory pType, string memory author, string memory prayer, string memory _numReadings)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Soul Scroll", "description": "', 
                                prayer ,'", "image":"',
                                imageURI,
                                '","attributes": [{"trait_type": "Number Of Prayers", "value":', _numReadings,'},{"trait_type": "PrayerType","value":"',pType,'"},{"trait_type": "Author","value":"',author,'"}]}'
                            )
                        )
                    )
                )
            );
    }
    
    function appendString(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e, string memory _f, string memory _g, string memory _h, string memory _j) internal pure returns (string memory)  {
        return string(abi.encodePacked(_a, _b, _c, _d, _e, _f, _g, _h, _j));
    }

       // Fallback function is called when msg.data is not empty
    receive() external payable {
        require(msg.value >= mintPrice, "Not enough ETH sent; check price!");
        uint8 readings = uint8(msg.value / mintPrice);
        orderPrayer(msg.sender, readings);
    }

    fallback() external payable {
        require(msg.value >= mintPrice, "Not enough ETH sent; check price!");
        orderPrayer(msg.sender, 1);
    }

    function orderPrayer(address _to, uint8 _numReadings) public payable {
        uint m;
        // for gas savings set deault readings to 5 
        if (_numReadings < 5) {m = 5;} else {m=_numReadings;}
        require(msg.value >= mintPrice*m, "Not enough ETH sent; check price!");
        require(prayersUsed < prayersLoaded, "Prayers are empty, please wait for the Sons of Gilead to write more.");
        require(_numReadings <= maxOrder, "Order too large.");
        ThePrayer memory onePrayer = prayers[prayersUsed];
        prayersUsed++;
        string memory t = onePrayer.prayerType;
        string memory p1= onePrayer.text;
        string memory p2= onePrayer.text2;
        string memory p3= onePrayer.text3;
        string memory author_name = onePrayer.author_name;
        string memory numReadings = Strings.toString(_numReadings);
        string memory theFirstObj = appendString("<svg viewBox='0 0 150 100' xmlns='http://www.w3.org/2000/svg'><style> .small { font: italic 5px sans-serif; fill: white } .med { font: 4px sans-serif; fill: white} .red { font: 20px serif; fill: #e66668; } </style> <rect height='100' width='150' y='0' x='0' fill='#596edd'> </rect><text x='5' y='24' class='red'>", t, "</text> <text x='5' y='40' class='small'>",p1,"</text><text x='5' y='48' class='small'>",p2,"</text><text x='5' y='56' class='small'>",p3,"</text>");
        string memory theObj = string(abi.encodePacked(theFirstObj,"<text x='20' y='64' class='med'>",numReadings,unicode"x</text><rect height='5' width='20' x='0' y='76' fill='#e66668'><animate attributeName='width' begin='0s' dur='18s' fill='freeze' from='0' to='150' /></rect><text x='65' y='80' class='med'>★★★★★</text></svg>"));
        string memory imageURI = svgToImageURI(theObj);
        string memory uri = formatTokenURI(imageURI, t, author_name, string(abi.encodePacked(p1, " ", p2, " ", p3)), numReadings);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, uri);
        
        // if the prayer author is the same as the contract owner do not split payment
        if (onePrayer.sonOfJacob != owner()) {
            uint256 commanderFee = msg.value/4;
            uint256 prayerPayment = msg.value - commanderFee;

            payable(owner()).transfer(commanderFee);
            onePrayer.sonOfJacob.transfer(prayerPayment);
        } else {
            payable(owner()).transfer(msg.value);
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721, ERC721Royalty) 
        returns(bool) 
        {
            return super.supportsInterface(interfaceId);
        }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function transferOwership(address _theAddress) public onlyOwner {
       super.transferOwnership(_theAddress);
    }
}