// SPDX-License-Identifier: MIT
/*
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii11111111111111111iiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii11111111111111111iiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiii1+iiiiiiiiiiiiiiiiiiiiiiii11111111o11111111iiiiiiiiiiiiiiiiiiiii
iiiiiii1111iiii11iiiiiiiiiiiiiiiiiiiiiiiiiiiii111111111111111iii~;;~~~iiiiiiiiiiiiii
iiiiii1ii1iiiiiii11iiiiiiiiiiiiiiiii1iiii!i&&&&%&&&1111111111u+.....+~~3iiiiiiiiiiii
iiii111iiiiiiiiii11111iiiii11iiiiii111iii%&&&&&%33$&&&&1111!+........+~~3iiiiiiiiiii
iii1111iiiiiiii1111111111111iiiii!&&&&&&&&$&$&&&&$$$$$$&&i^..........-+~~iiiiiiiiiii
zzzzzzz11iiiii1111111111111ii&&&&&&&%%$&&&&&&&&&&&&&$&&&8.............+~~~iiiiiiiiii
zzzzzzzz11iiii11111znnvzz&%%&$&&$8&&&&$&%3%$$&&$$$&&&&&&$..............+~~3iiiiiiiii
zzzzzzzzz111111111zzzzznn3z&&%$3^~o;&1;i&8$86%6%$&&&&&&&&%*...........%.+~~iiiiiiiii
zzzzzzzzz11zzz111zzzzzzn&&&&$&u^oooo;;&&$v$^&&&36$&&&&&&&&$v.%%%......%!+~~~iiiii11i
zzzzzzzzzzzzzzzzzzzzzn%n&&u&$o8;uoooo*$!!o1&11^^&86$i$&$$&&~.%%%~~~...%%.+~~iii11111
zzzzzzzzzzzzzzzzzzznn8&&&^^&1!oa&&o*^1&au1611&8!3%%n66&&$$%$&$$~~~~~~%%%1+~~311111az
nnvzzzzzzzzzzzzzzzznz%&8^oou1na&&&&111%&8%u311&$1;66*6616&&%%&~~~~~~%$%%%-~~~aaazzzz
nnnvzzzzzzzzznnnnnnn!$u;611$&&&&&&&&&io&aau318%a81o116&&66&&&%~~~~~~$$$$..+~~aaazzzz
nnnzzzzzznnznnnnnnnn&&1&o%&6*******1*&&**vo&3a*%$&6611686%&&&&&~~~~$$$$~~.+~~1zzzzzz
nnnnnzzzzzzzzzznnnnn!%1i&8***********&%*&*o*6*z&*&&&&&1866%&&&&~~~%$$!~~~~.+~~zzzzzz
~~~~~nnzzzzzzzzzznnn!&n&%************1&**;&******%&&$&&%$&%&&&z~~~$$n~~~~~.+~~zzzzzz
~~~~~~nnzzzzzzzzznnnn&3&&*************$***********&%$&&&&&$&&&&~~$$!~~~~~~.+~~zzzzzz
~~~~~~~~~zzznzzzznnnnz&a&%*%$$$*******&$$%;*$v**%*a&&%&&&&&&&&~~~$$~~~~~~~.+~~zzzzzz
~~~~~~~~~~~nnnnnnnnnnn3%&******************%*i~6****&%&&&&$&&~~~$$~~~~~~~~.+~%!zzzzz
~~~~~~~~~~~nnnnnnnnnnnn%n%68$$$*******88v$$$$8-$$6**&&;$u**~~~~$$3~~~~~~~~~.~%!zznnn
~~~~~~~~~~nnnnnnnnnnnnnannn!3a$$*******$o~au$$i$$***&n&*!*~8$~~$$~~~~~~~~~..~%%znnnn
~~~~~~~~~~~~~onnnnnnnnn&nnn*-8*v********--%*;**-;;**8**&6$6~~~$$~~~~~~~~~~..;%%nnnnn
~~~~~~~~~~~~~~~~nnnnnnnnin8!;;****;******----+;;;;*~$$~~u~!~a~$$~~~~~~~~~...^%%nn~~~
~~~~~~~~~~~~~~~~~~nnnnnnz&nn*****z~~******;;;;;;;*z~$$~$3~~v~$$~~~~~~~~.....+%%nno~~
^^^^~~~;+++*~~~~~~nnnnnnnnnnn*******************i~.8$$z&6~~$~$$~~~~~~~......+%%nnn~~
^^^^^++++++++^o~~nnnnn~~~;na$nn***~vo!********18**.%$$z~$~$~3$$~~~~~~.......+%%~~on~
^^^^^++++++^^^^^^^~~;*~*^^^n%nn~~**********u888***%%$$~%~$~~$$$~~$$%........^%%~~~~~
^^^^^^^^+++++++++^^^^^^^^++++3~~~~^****1~..18;****1%$~3~~~~~$$$$~u%%........;%%~~~~~
^^^^^^^^^++++++....^^+++++++^^~~~~~^^*~^+n~n******~.;~~~~~~v$$%%%%%*........~%%^~~^^
+++^^^^^^^^^^++.^^^+^+^^^^^^^^^^~;~^^-+!i.^*****n.aii.3$~~$$$%%%%%.........+~%i^^^^^
+++++^^^^^++++....^^^+++^+++++^^^^!..iiii*..**+.iu1u!ii.n-~$$%%%%..........+~%^^+^^^
....+++^+++-...+^^^^+++..+++++^^i.-.iiii3ii..iii3!.1ii.u..i.^$$............+%%+++++^
.....++....+..-++^++.+++..++++++i~3iiiii3iiiiiiiiiiii.u~3....n~~...........~%%++++++
..........................+...+n..i6iiiiiiiiiiiiiiiiii3in.viz^~~~.........+~%6++++++
...............................iii3iiiiiiiiiiiiiiiiii8ii..v~.-v~~.........+~%.-+....
...............................ii3iiiiii.v-.ii.....ii83ii..i.!zo~........-~%%.......
..............................!ii!iiiiii+iiiiii1~~..^3iiiiiiiii%v........+~%8.......
...............................1i333iiiiiiiiii.^i...i8uiiiiii.^6~........*~~........
..............................3^.i33*+++++++++i3333338niiii1~!^~~.......+~~~........
...............................n;i^^$$$a$+~3~+$$n$$$$;3oii!!~.!8~.......+~~.........
*/
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./ReentrancyGuard.sol";

error ErrorContractMintDenied();
error ErrorPulicSaleNotStarted();
error ErrorBurnNotStarted();
error ErrorBurnTokenIds();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();
error ErrorPorvideWrongTokenids();

contract SoulSailS2Clan is ERC2981, ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Address for address payable;
    using Strings for uint256;

    uint256 public _maxSupplyForPublic = 8500;
    uint256 public _maxSupplyForBurn = 1500;
    uint256 public _burnNumber;

    uint256 public _mintPrice = 0.0066 ether;
    uint256 public _walletLimit = 10;

    bool public _publicStarted = false;
    uint256 public _mintStartTime = 1687370400;

    bool public _revealed = false;
    string public _metadataURI = "";
    string public _uriSuffix = ".json";
    string public _hiddenMetadataUri;

    mapping (address => uint256) public walletMinted;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    IERC721 public _s1FlagContract;

    constructor() ERC721A("Soul Sail S2-Clan", "SSC") {
        _setDefaultRoyalty(owner(), 750);
    }

    function Burn(uint256[] memory tokenIds) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if ( _totalMinted() < _maxSupplyForPublic) revert ErrorBurnNotStarted();
        if (block.timestamp < _mintStartTime) revert ErrorBurnNotStarted();
        if (tokenIds.length < 1)  revert ErrorPorvideWrongTokenids();
        if (tokenIds.length + _totalMinted() > _maxSupplyForBurn + _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        if (tokenIds.length + _burnNumber > _maxSupplyForBurn) revert ErrorExceedMaxSupply();

        uint256 burnNumber = tokenIds.length;

        for (uint256 i = 0; i < burnNumber; ) {
            if(_s1FlagContract.ownerOf(tokenIds[i]) == msg.sender){
                _s1FlagContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
                unchecked {
                    i++;
                }
            }else{
                burnNumber--;
            } 
        }
        if (burnNumber < 1)  revert ErrorBurnTokenIds();
        
        _safeMint(msg.sender, burnNumber);
        _burnNumber += burnNumber;
    }

    function pulicMint(uint256 amount) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_publicStarted) revert ErrorPulicSaleNotStarted();
        if (block.timestamp < _mintStartTime) revert ErrorPulicSaleNotStarted();
        if (amount + _totalMinted() > _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        if (walletMinted[msg.sender] >= _walletLimit) revert ErrorExceedWalletLimit();
        if (walletMinted[msg.sender] + amount > _walletLimit) revert ErrorExceedWalletLimit();
        if (msg.value < amount * _mintPrice) revert ErrorInsufficientFund();
        
        _safeMint(msg.sender, amount);
        walletMinted[msg.sender] += amount;
    }
    
    function devMint(address to, uint256 amount) external onlyOwner {
        if (amount + _totalMinted() > _maxSupplyForBurn + _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        _safeMint(to, amount);
    }
    
    struct State {
        uint256 mintPrice;
        uint256 walletLimit;
        uint256 maxSupplyForPublic;
        uint256 maxSupplyForBurn;
        uint256 totalMinted;
        bool revealed;
        bool publicStarted;
        uint256 mintStartTime; 
    }

    function _state() external view returns (State memory) {
        return
            State({
                mintPrice: _mintPrice,
                walletLimit: _walletLimit,
                maxSupplyForPublic: _maxSupplyForPublic,
                maxSupplyForBurn: _maxSupplyForBurn,
                totalMinted: uint256(ERC721A._totalMinted()),
                revealed: _revealed,
                publicStarted: _publicStarted,
                mintStartTime: _mintStartTime
            });
    }

    function setBurnTokenContract(address s1FlagContract) external onlyOwner {
        _s1FlagContract = IERC721(s1FlagContract);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    } 

    function setPublicStarted(bool publicStarted) external onlyOwner {
        _publicStarted = publicStarted;
    }

    function setMintStartTime(uint256 mintStartTime) public onlyOwner {
        _mintStartTime = mintStartTime;
    }

    function setWalletLimit(uint256 walletLimit) public onlyOwner {
        _walletLimit = walletLimit;
    } 

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }
    
    function setMaxSupplyForPublic(uint256 maxSupplyForPublic) public onlyOwner {
        _maxSupplyForPublic = maxSupplyForPublic;
    } 

    function setMaxSupplyForBurn(uint256 maxSupplyForBurn) public onlyOwner {
        _maxSupplyForBurn = maxSupplyForBurn;
    } 

    function setRevealed(bool revealed) public onlyOwner {
        _revealed = revealed;
    }

    function setUriSuffix(string memory uriSuffix) external onlyOwner {
        _uriSuffix = uriSuffix;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setHiddenMetadataUri(string memory hiddenMetadataUri) public onlyOwner {
        _hiddenMetadataUri = hiddenMetadataUri;
    }
    
    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (_revealed == false) {
            return _hiddenMetadataUri;
        }

        string memory baseURI = _metadataURI;
        string memory uriSuffix = _uriSuffix;
        return string(abi.encodePacked(baseURI, tokenId.toString(), uriSuffix));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    } 
  
    function withdraw() external onlyOwner nonReentrant{
        payable(msg.sender).transfer(address(this).balance);
    }

	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}
  
}