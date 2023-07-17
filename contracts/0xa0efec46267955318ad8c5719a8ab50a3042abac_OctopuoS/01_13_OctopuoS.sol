// SPDX-License-Identifier: MIT

/*
.-.. .-.. .-.. .-.. ---... -..-. -..-. ..- .-.. .-.. ..- .-.. -. .-.. .-.. -. ..- ..- -. .-.. .-.. ..- ..- ..- ..- .-..
 .-.. ..- ..- .-.. ..- ..- ..- -. .-.. -. .-.. ..- -. .-.. .-.. .-.. .-.. .-.. ..- .-.. -. ..- .-.. ..- .-.. ..- ..-
||             .8888888.   .888888. 88888888888 .8888888.  88888888.  888     888  .8888888.   .888888.              ||
||            8888" "88M8 8888  8888    888    8888" "8888 888   8O88 888     888 8888" "8888 8888  8888             ||
||            888     888 888    888    8R8    888     888 888    888 8S8     888 888     888 8888.                  ||
||            888     888 888           888    888     888 888   8888 888     888 888     888  "88E88.               ||
||            888     888 888           888    888     888 88888888"  888     888 888     888     "8888.             ||
||            888     8B8 888    888    888    888     888 888        888     888 888     888       "888             ||
||            8888. .8888 8888  8888    888    8888. .8888 888        8888. .8888 8888. .8888 8888  8888             ||
||             "8888888"   "888888"     888     "8888888"  888         "8888888"   "8888888"   "888888"              ||
 .. .--. ..-. ... ---... -..-. -..-. --.- -- -.-. .... -- ....- -.-- ..-. ---.. .--. . -.... -. -.. -.. .-.. -. -. .-. 
 --. --.. .... .-. .-. ...- -..- ---.. --.- -.... ..-. .-. ...-- ..- - ...- . --.- -- .-. ...-- .--. --.. -- -. - .--.

                                                            ___
                                                         .-'   `'.
                                                        /         \
                                                        |----8----;
                                                        |         |           ___.--,
                                               _.._     |0) ~ (0) |    _.---'`__.-( (_.
                                        __.--'`_.. '.__.\    '--. \_.-' ,.--'`     `""`
                                       ( ,.--'`   ',__ /./;   ;, '.__.'`    __
                                       _`) )  .---.__.' / |   |\   \__..--""  """--.,_
                                      `---' .'.''-._.-'`_./  /\ '.  \ _.-~~~````~~~-._`-.__.'
                                            | |  .' _.-' |  |  \  \  '.               `~---`
                                             \ \/ .'     \  \   '. '-._)
                                              \/ /        \  \    `=.__`~-.
                                              / /\         `) )    / / `"".`\
                                        , _.-'.'\ \        / /    ( (     / /
                                         `--~`   ) )    .-'.'      '.'.  | (
                                                (/`    ( (`          ) )  '-;
                                                 `      '-;         (-'
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OctopuoS is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 0.048 ether;
    uint256 public maxSupply = 8888; //Awumbquma uif = uifuif
    uint256 public maxMintAmount = 10;

    // 0 = paused, 1 = presale, 2 = live
    uint256 public saleState;       //default is 0
    bool public metadataLocked;     //default is false
    
    // List of addresses that have a number of reserved tokens for presale
    mapping (address => uint256) public preSaleReserved;

    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

  // public Sale
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require( saleState > 1,                             "Sale not live" );                          
        require(_mintAmount > 0,                            "Cant mint 0 tokens");
        require(_mintAmount <= maxMintAmount,               "Exceeds max mint amount" );
        require( supply + _mintAmount <= maxSupply,         "Exceeds max supply" );
        require( msg.value >= cost * _mintAmount,           "Amt sent not correct" );
        
        //mint out the required amount
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);              
        }
    }
  
  // Presale minting
  function mintPresale(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 reservedAmt = preSaleReserved[msg.sender];
        require( saleState > 0,                             "Presale not active");
        require(_mintAmount > 0,                            "Cant mint 0 tokens");
        require( reservedAmt > 0,                           "No tokens reserved for address");
        require( _mintAmount <= reservedAmt,                "Exceeds reserved amt");
        require( supply + _mintAmount <= maxSupply,         "Exceeds max supply");
        require( msg.value >= cost * _mintAmount,           "Amt sent not correct");
        
        //reduce the amount reserved for address
        preSaleReserved[msg.sender] = reservedAmt - _mintAmount;
        
        //mint out the required amount
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
  }
  
    function walletOfOwner(address _owner) 
    public
    view
        returns (uint256[] memory)
        {
            uint256 ownerTokenCount = balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        //Awumbquma uif = uifuif
        require( _exists(tokenId),        "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    /*-------------------------------------------------------------------------------------------------
      ||                                           ONLY OWNER                                        ||
      -------------------------------------------------------------------------------------------------
    */
    function ownerMint(uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0,                            "Cant mint 0 tokens");
        require( supply + _mintAmount <= maxSupply,         "Exceeds max supply");

        for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(msg.sender, supply + i);
        }
    }
    
    // Allocate whitelist to array of addresses and for a given
    function setPreSaleWhitelist(address[] memory _a, uint256 _amountToReserve) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            preSaleReserved[_a[i]] = _amountToReserve;
        }
    }

    //this will lock the metadata and disables setBaseURI()
    function lockMetadata() public onlyOwner {
        metadataLocked = true;
    }
    
    // update the price
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    
    // change the max mint amount
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    // change the base URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(metadataLocked != true, "Metadata locked!");

        baseURI = _newBaseURI;
    }
    
    // change base extension
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // change sale state
    function setSaleState(uint256 _saleState) public onlyOwner {
        // 0 = paused, 1 = presale, 2 = live
        saleState = _saleState;
    }
 
    // withdraw contract funds to owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
/*
     ▄▄▄▄▄▄▄ ▄ ▄ ▄    ▄  ▄▄ ▄  ▄▄    ▄ ▄▄▄▄▄▄▄    
     █ ▄▄▄ █ ▀ █▀█▀█▄▀█▄ ▀▄█▄██▀▄▀▄▀ ▄ █ ▄▄▄ █    
     █ ███ █ ▄ █▀ ▄█▄█ █▀▀█▄▀▀█▀▀ ██▀  █ ███ █    
     █▄▄▄▄▄█ █ ▄▀▄▀▄ █▀▄ █ ▄ ▄ █ █ █ █ █▄▄▄▄▄█    
     ▄▄▄  ▄▄ █ ▄▄   ▄▄  ▄█▄▀    █▄▄▀█▄▄▄▄▄  ▄▄    
      █▀▄▄█▄▀▄█  ▄▄▄██ ██ ▄▄▄█▄▀█▀███▀█▀▄▄▄▀▀█    
     ██▀▄▄▀▄▀▀▄█▀█▄█▄█▄█▀█  ▀▄ ▀█▀ ▀▄▀ ▄▄ ▀▄▀     
     ▀▄  █▄▄█▄▀▀ █ █ █ ▄█▀▀██▀▀█▄█▄▄█▀▀▄▀▄▀▄ █    
      ▀ █▄▄▄ ▀▄▄▀▀ ▀▀█ ▀▄▄▄ ▄█  ▄ ▄ ▄█▀▄ ██ ▀▄    
     █▀ ▀▀ ▄█▄█▀██▀ ██▀ █ █▄█▀▄▄▄▀█▄█▀▀▄▀▄▀▄ █    
     ▄▀▄██▄▄▀█▄█▄ █ ▄ █ ▄▄ ▀██  █▄ ▄▄▄▄▄▄ █▄▀▄    
      █▄█ ▄▄ ▀▀▀▄ ▄▄▄   ██  ██  █▄▄▄██▄▀▀   ██    
     ███   ▄█▀▄▀▄▄ ▀▄▄  ▄▀▄ ▄ ▄▀ ▀▄▀ █ ▄  █  ▀    
      ▀▀▄  ▄▀▄█▀█ ▄██▄▄█▄▀ ▄█▄▀▀█▄▄▄█▀█▄█ ▄█ █    
     ▄██ █▀▄█▀▀  ▄▄█▀▄▄█ ▀ ▄▀▄ ▀▀▄  ▀▄▄▄ ▀   ▀    
     ▄██▄▄▄▄▄▄█▄ █ █ █▄██▀ ▄█ ▄▀█▀█ ██▄██▄▀▀ █    
     ▄▄▄ ▀ ▄██ █▀█ █▀▀  ▄█▄ ▀▀▄▀▀█  ███▄▄▄█ ▀▄    
     ▄▄▄▄▄▄▄ ▀ ▄█▀▀ █▄▀ █▀▄▄▄▀▄▀█▀▄  █ ▄ █▄  █    
     █ ▄▄▄ █ ▀█▀█ █ ▄ █ █▄  ▄▄   █  ██▄▄▄██  ▄    
     █ ███ █ ▄▀ ▄ ▄▄▄ █▄██ ▄▄▀ ▄██▄▀█ ▀▄ ██▄▀█    
     █▄▄▄▄▄█ █▀ ▄   ▄▄ █▄▀▄ █▄  █▄ ▀ ██▀▄█▄  ▄  

*/