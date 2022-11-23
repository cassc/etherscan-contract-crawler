pragma solidity ^0.8.4;

import "./ERC721A.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

//                           .,,,..                                                    
//                         .,,,,,,,,7                         .,,,.                    
//                        .,,.,,,,.,.                       I,,,,,,,I                  
//                        .,,,,,,,,.,.                      ,,.,,,.,.                  
//                        ?,,.,,,,.=IIIIIIIII.      7.IIIIII~..,,,,,,                  
//                         .,,..IIIIIIIIIIIIIII, 7.IIIIIIIIIIIII.,.,:                  
//                           .IIIIIIIIIIIIIIIIIII.?IIIIIIIIIIIIIII.                    
//                         7IIIIIIIIIIIIIIIIIIIIII.?IIIIIIIIIIIIIII,                   
//                         IIIIIIIIIIIIIIIIIIIIIIII.??IIIIIIIIIIIII.~.?                
//                        .IIIIII??=...,,,,,,,,,,,,..??IIIIIIIIIIIIIIIII?              
//                       .IIIII:,,,,,,,.,,,,,,,,,..,,????..,,,,,,,,..~??II             
//                     7IIIIII+,,,,,.,,,,,....,,,,,,,.,,,,,,.......,,,,,,,,.           
//                     IIIIII.,,,,,,,.~~.....=~77I+..,.?7~=....7.=.777II..,,7          
//                    .IIIIIIII:.....7~==...7?.7777777,I7.~=.?.7..777777777.           
//                   :IIIIIIIIIIIIIIIIIII.....=I77?..I.,,,..................           
//                   .IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:........,IIIIIIIII7          
//                  7IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~           
//                  7?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?......IIIIIIIIIIIIII.            
//                  .?IIIIIIIIIIIIIIIIIIIIIIIIIIIII.,,:....::,.IIIIIIIIII.7            
//                  .?IIIIIIIIIIIIIIIIIIIIIIIIIIII.,::,....,::,.IIIIIIIII.             
//                  .??IIIIIIIIIIIIIIIIIIIIIIIIII.,::::,,,:::::,.IIIII??.              
//                  .???IIIIIIIIIIIIIIIIIIIIIIIIII,:::.,,,,::::,.IIIII?I               
//                  7???IIIIIIIIIIIIIIIIIIIIIIIIII,,::::::::::,.IIIIII?I               
//                   ????IIIIIIIIIIIIIIIIIIIIIIIIIII.,,:,,,,,.~IIIIIII?.               
//                   II????IIIIIIIIIIIIIIIIIIIIIIIIIIIIII?IIIIIIIIIII?I7               
//                    II????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?I.                
//                     7.?????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.                 
//                    7.??+.I???????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~                  
//                   7.???????????~..........+IIIIIIIIIIIIIIIIIII?.7                   
//                  7:IIIIIIIIIII???????????????????????~......????I.                  
//                  .IIIIIIIIIIIIIIIIIIIIIIIIII?????????????????IIIII~                 
//                 .IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~                
//                 IIIIIIII?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.               
//                .IIIIIII?:?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII??IIIIIII7              
//               ,IIIIIII?.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.?IIIIII.7             
//               .IIIIII??+?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII???IIIIII.7             
//    ___  ____   ________  ___  ____  ____   ____  ________  _______     ______   ________  
//   |_  ||_  _| |_   __  ||_  ||_  _||_  _| |_  _||_   __  ||_   __ \  .' ____ \ |_   __  | 
//     | |_/ /     | |_ \_|  | |_/ /    \ \   / /    | |_ \_|  | |__) | | (___ \_|  | |_ \_| 
//     |  __'.     |  _| _   |  __'.     \ \ / /     |  _| _   |  __ /   _.____`.   |  _| _  
//    _| |  \ \_  _| |__/ | _| |  \ \_    \ ' /     _| |__/ | _| |  \ \_| \____) | _| |__/ | 
//   |____||____||________||____||____|    \_/     |________||____| |___|\______.'|________|  v 1.1
//
//                                  https://kekverse.io/
//                  Created and drawn by Based Pleb - https://twitter.com/Based_Pleb
//                         Tech stuff by Mr F - https://twitter.com/MrFwashere
//                        Reluctantly redeployed thanks to OpenSea...

contract Kekverse is ERC721A, DefaultOperatorFilterer {
    string public baseURI;

    uint128 public offsetBlock;
    uint128 public offset;

    uint constant supply = 4200;

    uint constant kekPrice = 0.02 ether; 
    uint constant plebPrice = 0.025 ether;
    uint publicPrice = 0.03 ether; // might be lowered

    uint public immutable publicMint;
    address immutable basedPleb;
    address immutable mrF;

    bool public airdropUsed;

    mapping(address => bool) public earlyMinted;

    constructor(string memory _uri, address _pleb, address _mrF) ERC721A("Kekverse", "KEK")  {
        baseURI = _uri;
        basedPleb = _pleb;
        mrF = _mrF;
        publicMint = block.timestamp + 72 hours; // WL mint begins at deployment, public 72h later
    }

    function airdrop(address _oldKek) public {
        require(!airdropUsed);
        require(msg.sender == mrF);
        uint num = IERC721A(_oldKek).totalSupply();
        uint count = 1;
        address owner = IERC721A(_oldKek).ownerOf(1);
        for (uint i = 2; i <= num; i++) {
            address oldOwner = IERC721A(_oldKek).ownerOf(i);
            if (oldOwner != owner) {
              _mint(owner, count);
              earlyMinted[owner] = true;
              count = 0;
              owner = oldOwner;
            }
            count = count + 1;
        }
        _mint(owner, count);
        earlyMinted[owner] = true;
        airdropUsed = true;
    }

    function lowerPrice(uint _price) public { // LAST RESORT
        require(msg.sender == basedPleb);
        require(_price < publicPrice); // price cannot go up
        require(block.timestamp > publicMint + 120 hours); // 7 days after deployment, 5 days after public
        publicPrice = _price;
    }

    function withdraw() public {
        uint bal = address(this).balance;
        uint pleb = bal * 84 / 100;
        basedPleb.call{value: pleb}("");
        mrF.call{value: bal - pleb}("");
    }

    function setBaseURI(string memory _uri) external {
        require(msg.sender == basedPleb);
        baseURI = _uri;
    }

    function initOffset() public {
        require(msg.sender == basedPleb || msg.sender == mrF);
        require(super.totalSupply() == supply);
        offsetBlock = uint128(block.number) + 1;
    }

    function finalizeOffset() external {
        uint128 _offset = offset;
        
        require(_offset == 0, "Starting index is already set");
        require(offsetBlock != 0, "Starting index block must be set");
        require(block.number - offsetBlock < 255, "Must re-init");
        
        _offset = uint128(uint256(blockhash(offsetBlock)) % supply);

        // Prevent default sequence
        if (_offset == 0) {
            _offset = 1;
        }
        
        offset = _offset;
    }

    // minting logic

    function mint(uint num) public payable {
        require(msg.value == publicPrice * num);
        require(block.timestamp >= publicMint);

        uint tokenId = super.totalSupply();

        require(tokenId <= supply);

        if (tokenId + num > supply) {
            uint remaining = supply - tokenId;
            uint excess = num - remaining;
            _mint(msg.sender, remaining);
            payable(msg.sender).transfer(excess * publicPrice); // refund
        } else {
            _mint(msg.sender, num);
        }
    }

    function mintKeklist(uint num, uint8 _v, bytes32 _r, bytes32 _s) public payable {
        require(airdropUsed);
        require(super.totalSupply() < 3000); // reserve some for public
        require(msg.value == kekPrice * num);
        require(!earlyMinted[msg.sender]);
        require(block.timestamp < publicMint);
        require(num <= 7);
        verify("Keklist ", _v, _r, _s); // will revert tx if fails
        _mint(msg.sender, num + 1);
        earlyMinted[msg.sender] = true;
    }

    function mintPleblist(uint num, uint8 _v, bytes32 _r, bytes32 _s) public payable {
        require(airdropUsed);
        require(super.totalSupply() < 3000); // reserve some for public
        require(msg.value == plebPrice * num);
        require(!earlyMinted[msg.sender]);
        require(block.timestamp < publicMint);
        require(num <= 5);
        verify("Pleblist ", _v, _r, _s); // will revert tx if fails
        if (num >= 3) {
            _mint(msg.sender, num + 1);
        } else {
            _mint(msg.sender, num);
        }
        earlyMinted[msg.sender] = true;
    }

    function verify(string memory _type, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        // Confirm the hash was signed by admin
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        string memory checkMessage = string(abi.encodePacked(_type, toString(msg.sender)));
        bytes32 checkHash = keccak256(abi.encodePacked(checkMessage));
        bytes memory message = abi.encodePacked(prefix, checkHash);
        bytes32 prefixedHash = keccak256(message);

        address recoveredAddress = ecrecover(prefixedHash, _v, _r, _s);
        require(recoveredAddress == mrF, string(abi.encodePacked("Recovered address was ", recoveredAddress)));
    }

    // ERC712 things

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (offset == 0) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(0))) : ''; // token 0 is unrevealed metadata
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(((tokenId + offset) % supply) + 1))) : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // token id should start at 1, obviously

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // misc

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // opensea garbage

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}