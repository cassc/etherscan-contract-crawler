// SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.2;

//echoes echo echoes
/*
              .::.                                                    .----                                                                                                 
             :====:                                                   .====                                                                                                 
             .----.                                                   .====                                                                                                 
                                          .:::::.         .:::::.     .====  .:::.         ..::::.           .::::..        .:::::..                                        
                                        -=========:     :=========-   .====-=======-     :=========-.     .-========-.    :=========-.                                      
    .-==-.   .-==-.   .-==-.          .====:...:===-   -===-...:====  .====-...:====:   -===-...:====:   :===-:...-===:  :===-   .====.                                     
    :====:   :====:   :====:          -===:     -===: :===-     ::::. .====     -===-  :===-      ====. .====.    .====  :===-:..                                           
     .::.     .::.     .::.           ==============: -===:           .====     :===-  -===:      -===: :==============   .-=======-:                                       
                                      ====:.......... :===-           .====     :===-  :===-      ====. .====..........      ..::-====.                                     
              ....                    :====:    .::    ====:   .====. .====     :===-  .====:   .-===-   -===-.    .-.   ====     -===:                                     
             :====:                    .-==========-   .-==========.  .====     :===-   .-==========:     :===========.  .====---====-                                      
             .-==-.                      .:-----::       .:-----:.     ----     :---:     .:-----:.         .:-----:.      .:-----::                        
    */
    
    
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./base64.sol";

contract Echoes is ERC721 {
    
    //all those arrays are basically used to store the echoes data
    address private _owner;
    address private _whitelistedAddress;
    string[] private echoes;
    string[] private contributors;
    string[] private signers;
    string[] private dates;
    string[] private colors;
    
    string[] private submission;

    string[12] monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"];
    string[2] color=["#F27F7F","#000000"];
    
    
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() ERC721("Echoes by Nahiko", "ECHOES") {
        //init the whitelisted addy as sender
        _whitelistedAddress = _msgSender();
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    //_________________________________________________________________________________
    //functions that are utils for the ERC721

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint i;
        bytes memory json;
        //concat data and return the json as a string
        bytes memory loopedValues;
        for(i= tokenId*6+0; (i < tokenId*6+(echoes.length - tokenId*6)) && (i < tokenId*6 +6) ; i++){
            loopedValues = abi.encodePacked(loopedValues," <rect class='tab' y='",uint2str(296+(700*(i%6))),"px'/> <text class='name' y='",uint2str(610+(700*(i%6))),"px' x='450px'>",contributors[i]," \u00B7<tspan class='signature' dx='30px' dy='-10px'>",echoes[i],"</tspan> <tspan class='date' text-anchor='end' x='93%' dy='-200px'>",dates[i],"</tspan> <tspan class='signed' text-anchor='end' x='93%' dy='-170px'>signed by 0x",signers[i],"</tspan> <tspan class='dot' style='fill:",colors[i],";' x='92.5%' dy='400px'>\u00B7</tspan> </text>");
        }
        
        json = abi.encodePacked("<svg width='5000px' height='5000px' xmlns='http://www.w3.org/2000/svg'> <style type='text/css'> .tab{ width: 4452px; height: 496px; fill:#FFFFFF; x:274px; border-radius: 70px; rx:70px; dy:160px; margin-left:274px; filter: drop-shadow( 0px 23px 42px rgba(137, 151, 188, 0.23)); } .name{font-weight:bold;} .signature{font-weight:lighter !important;font-size:120px;} .text{fill:#1a1a1a;font-size:160px;font-family:sans-serif;} .date{fill:#A6AEBB;font-size:50px;} .signed{fill:#A6AEBB;font-size:50px;font-weight:lighter !important;} .dot{font-size:700px;fill:#000000;} </style> <rect width='100%' height='100%' fill='#F3F5F9'/> <g class='text' y='296px'>",
        loopedValues,
        "<text style='fill:red;font-weight: bold;font-size: 122px;fill:#F27F7F' x='50%' y='98%' text-anchor='middle'>\u2E2D echoes</text> </g> </svg>");
        return string(abi.encodePacked('data:application/json;utf8,{"description":"Echoes is a 100% on chain blank slate. The owner can whitelist people to sign a message.","background_color": "F3F5F9","name": "Echoes ',uint2str(tokenId),'","image": "data:image/svg+xml;base64,',Base64.encode(json),'"}'));
     }
    
    
    function contractURI() public pure returns (string memory) {
        return 'data:application/json;utf8,{"description":"The Echoes Smart Contract enables its owner to allow whitelisted addresses to sign the Echoes token. Each token is 100% generated on chain. There is NO image, only code.","name": "Echoes Smart Contract","image": "ipfs://QmXw3Ug5ub53xckjT9T6xE3EU45bqUMsGnswzMYGertENa","seller_fee_basis_points": 500,"fee_recipient": "0x9E57A685F5843090A79A01ce6947a82eAdA9EDf1"}';
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) public virtual {
        require(_msgSender() == _owner,"only the owner transfer ownership");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function getWhitelistedAddress() public view returns(address){
        return _whitelistedAddress;
    }
    
    function setWhitelistedAddress(address newWhitelistedAddress) external {
        require(_msgSender() == _owner,"you are not the owner of the contract"); 
        _whitelistedAddress = newWhitelistedAddress;
    }

    function echo(string memory newEcho,string memory signedBy) public{
        require(_msgSender() == _whitelistedAddress,"you are not whitelisted"); 
        require(isValid(newEcho) && isValid(signedBy),"please make sure to keep it simple");
        require(abi.encodePacked(newEcho,signedBy).length < 100,"max total length is 100 bytes");
        
        //push everything to the submission array
        submission.push(newEcho);
        submission.push(signedBy);
        submission.push(string(abi.encodePacked("0x",toAsciiString(_msgSender()))));
        submission.push(getCurrentDate(block.timestamp));
        submission.push(color[random()]);
        
        _whitelistedAddress = _owner;
    }
    
    function validateSubmittedEcho(bool ok) public{
        require(_msgSender() == _owner,"only the owner can refuse an echo");
        
        if(ok == true){ 
            
            if(echoes.length%6 == 0){  //making sure to mint a token every 6th echo as needed
            _mint(msg.sender,echoes.length/6); 
            }
            echoes.push(submission[0]); //update the new echo data
            contributors.push(submission[1]);
            signers.push(submission[2]);
            dates.push(submission[3]);
            colors.push(submission[4]);
        }
        delete submission; //refresh the submission array

    }
    
    function getEchoes() public view returns(string[] memory,string[] memory,string[] memory,string[] memory,string[] memory){
        return (echoes,contributors,signers,dates,colors);
    }
    
    function getSubmission() public view returns(string[] memory){
        return submission;
    }
    
    
    ////////////utils////////////
    
    
    //this part is code picked from bokkypoobah's github. Thank you for leaving this as MIT license <3
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    int constant OFFSET19700101 = 2440588;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
    
 
    
    function getCurrentDate(uint timestamp) internal view returns (string memory date) {
        uint yearint;
        uint monthint;
        uint dayint;
        
        (yearint,monthint,dayint) = _daysToDate(timestamp / SECONDS_PER_DAY);
        date=string(abi.encodePacked(monthNames[monthint-1]," ",uint2str(dayint)," ",uint2str(yearint)));
        return date;
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
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%2;
    }
    
    function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    
    //function coming from Seedlings project. ty @dievardump
   function isValid(string memory str) public pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 1) return false;
        if (strBytes.length > 100) return false; // Cannot be longer than 100 bytes
        if (strBytes[0] == 0x20) return false; // Leading space
        if (strBytes[strBytes.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar;
        bytes1 char2;
        uint8 charCode;

        for (uint256 i; i < strBytes.length; i++) {
            char2 = strBytes[i];
            if (char2 == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces
            charCode = uint8(char2);

            if (
                !(charCode >= 97 && charCode <= 122) && // a - z
                !(charCode >= 65 && charCode <= 90) && // A - Z
                !(charCode >= 48 && charCode <= 57) && // 0 - 9
                !(charCode == 32) && // space
                !(charCode == 44) && // ,
                !(charCode == 39) && // '
                !(charCode == 63) && // ?
                !(charCode == 33) && // !
                !(charCode == 64) && // @
                !(charCode == 59) && // ;
                !(charCode == 45) // -
            ) {
                return false;
            }

            lastChar = char2;
        }

        return true;
    }

    
    
}