// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

                   ██ 
     ██████       ██
    ██    ██       ██
    ██    ██ █████ 
    ██    ██       
     ██████


     ██████  ███    ██                         
    ██    ██ ████   ██                         
    ██    ██ ██ ██  ██                         
    ██    ██ ██  ██ ██                         
     ██████  ██   ████                         
                                            
                                            
     ██████ ██   ██  █████  ██ ███    ██       
    ██      ██   ██ ██   ██ ██ ████   ██       
    ██      ███████ ███████ ██ ██ ██  ██       
    ██      ██   ██ ██   ██ ██ ██  ██ ██       
     ██████ ██   ██ ██   ██ ██ ██   ████       
                                            
                                            
    ███    ███ ███████ ███████ ██████  ███████ 
    ████  ████ ██      ██      ██   ██ ██      
    ██ ████ ██ █████   █████   ██████  ███████ 
    ██  ██  ██ ██      ██      ██   ██      ██ 
    ██      ██ ██      ███████ ██   ██ ███████

    (phase 2)
    
    vision: @DadMod_xyz & @galtoshi
    art: @thompsonNFT
    devs: @JofaMcBender & @0xSomeGuy

    with the support of:
    sartoshi: 0xF95752fD023fD8802Abdd9cbe8e9965F623F8A84
    mfer community: 0x79FCDEF22feeD20eDDacbB2587640e45491b757f
*/


import "./extras/SSTORE2.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


error OneOfOnesCantBeTransferredTheyAreSpeeeeeeeeeecial();
error ThisIsTheOneOfOneMintHomieWhatYouDoin();
error ThisIsAwkwardYoureEarlyToTheMintParty();
error WouldLoveToMintButTheFundsArentRight();
error SorryCouldntWithdrawYourFundsDude();
error YouDontEvenOwnThisOgOneOfOne();
error WhoaThisTokenIdDoesntExist();
error ThisIsNotAnOgOneOfOneToken();
error YouDontOwnThisTokenThough();
error NoLayersToMintStayTuned();


contract MferLayers is ERC721A, Ownable, ReentrancyGuard
{

    // constructor... like it says...
    constructor() ERC721A("MferLayers", "BASED")
    {
        JeffFromAccounting = msg.sender;
        // nothing else to see here folks 👇
    }



    //-------------------------------------------------------------------------
    //
    //      contract brain cells
    //
    //-------------------------------------------------------------------------
    
    // count to control mints
    uint256 public LayerCount;

    // map token index to trait and layer indexes
    mapping(uint256 => uint256[2]) public TokenToTraitLayerMap;
    // we do a little dark mode up in here
    mapping(uint256 => bool) public TokenToDarkModeMap;

    // mint status
    bool public IsMintPartyLit;
    // toggle mint status
    function togglePartyStatus() external onlyOwner
    {
        IsMintPartyLit = !IsMintPartyLit;
    }
    // mint price
    uint256 CoverPrice = .69 ether;
    // update mint price
    function updateCoverPrice(uint256 _newPrice) external onlyOwner
    {
        CoverPrice = _newPrice;
    }
    
    // map token to 1/1 status
    mapping (uint256 => bool) public TokenToIsOgOneOfOneMap;
    // map token to og 1/1 index (21 total)
    mapping (uint256 => uint256) public TokenToOgOneOfOneIndexMap;
    // og mfer contract for 1/1 ownership
    IOgMferContract private OgMferContract;
    function setOgMferContractAddress(address _newAddress) external onlyOwner
    {
        OgMferContract = IOgMferContract(address(_newAddress));
    }

    // trait data struct
    struct Trait
    {
        string name;            // trait name
        Layer[] layers;         // array of layer structs
    }

    // layer data struct
    struct Layer
    {
        uint256 x;              // x-coordinate on 1000x1000 image
        uint256 y;              // y-coordinate on 1000x1000 image
        uint256 width;          // layer width
        uint256 height;         // layer height
        string name;            // layer name
        string traitName;       // trait name (more accessibility)
        address[] pointers;     // array of addresses in sequential order that retrieve base64 strings
    }

    // array of trait structs, one for each trait group form the mfer collection (including 1/1)
    Trait[15] public Traits;

    // array of strings for metadata in tokenURI
    string[5] public MetadataStrings;
    function updateMetadataString(uint256 _index, string memory _newString) external onlyOwner
    {
        MetadataStrings[_index] = _newString;
    }
    
    // array of strings for svg in tokenURI
    string[7] public SvgStrings;
    function updateSvgString(uint256 _index, string memory _newString) external onlyOwner
    {
        SvgStrings[_index] = _newString;
    }

    // 1/1 indexes from original mfer contract
    uint256[21] public OneOfOneIndexes =
    [
        140,
        781,
        1825,
        2293,
        2506,
        3942,
        4482,
        5476,
        5659,
        5688,
        6551,
        7456,
        7503,
        8434,
        8618,
        9035,
        9205,
        9292,
        9547,
        9860,
        9967
    ];
     


    //-------------------------------------------------------------------------
    //
    //      token stuffs
    //
    //-------------------------------------------------------------------------

    // mint additional layers added to collection
    function mint() external payable
    {
        // check if mint is active
        if(!IsMintPartyLit) revert ThisIsAwkwardYoureEarlyToTheMintParty();

        // check if layers are available to mint
        if(totalSupply() >= LayerCount) revert NoLayersToMintStayTuned();

        // check if price is correct
        if(msg.value != CoverPrice) revert WouldLoveToMintButTheFundsArentRight();

        // mint that suckah!
        _mint(msg.sender, 1);
    }

    // owner mint
    function ownerMint(address _to) external onlyOwner
    {
        // check if layers are available to mint
        if(totalSupply() >= LayerCount) revert NoLayersToMintStayTuned();

        // mint token
        _mint(_to, 1);
    }

    function oneOfOneMint(address _to, uint256 _oneOfOneIndex) external onlyOwner
    {
        // check if layers are available to mint
        if(totalSupply() >= LayerCount) revert NoLayersToMintStayTuned();

        // get original 1/1 owner
        address oneOfOneOwner = OgMferContract.ownerOf(OneOfOneIndexes[_oneOfOneIndex]);

        // check if to is og owner
        if(_to != oneOfOneOwner) revert ThisIsTheOneOfOneMintHomieWhatYouDoin();

        // update is 1/1 mapping
        TokenToIsOgOneOfOneMap[_nextTokenId()] = true;

        // update token to 1/1 index mapping
        TokenToOgOneOfOneIndexMap[_nextTokenId()] = _oneOfOneIndex;

        // mint token
        _mint(_to, 1);
    }

    // update one of one index
    function updateOneOfOneIndex(uint256 _tokenId, uint256 _oneOfOneIndex) external onlyOwner
    {
        TokenToOgOneOfOneIndexMap[_tokenId] = _oneOfOneIndex;
    }

    // update one of one index
    function toggleOneOfOneStatus(uint256 _tokenId) external onlyOwner
    {
        TokenToIsOgOneOfOneMap[_tokenId] = !TokenToIsOgOneOfOneMap[_tokenId];
    }

    // return owner of token
    function ownerOf(uint256 _tokenId) public view override returns (address)
    {
        // check token exists
        if(!_exists(_tokenId)) revert WhoaThisTokenIdDoesntExist();

        // check if token is layer or 1/1
        if(TokenToIsOgOneOfOneMap[_tokenId])
        {
            // get the 1/1 owner from the original contract
            return OgMferContract.ownerOf(TokenToOgOneOfOneIndexMap[_tokenId]);
        }
        
        // else this is a (non 1/1) layer token, get owner as usual
        return _ownershipOf(_tokenId).addr;
    }

    // dont allow 1/1 transfers
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal view override
    {        
        // check if 1/1, then dont transfer
        if(TokenToIsOgOneOfOneMap[startTokenId] && from != address(0)) revert OneOfOnesCantBeTransferredTheyAreSpeeeeeeeeeecial();
    }

    function emitTransferForOgOneOfOne(uint256 _tokenId) public
    {
        // check if token is 1/1
        if(!TokenToIsOgOneOfOneMap[_tokenId]) revert ThisIsNotAnOgOneOfOneToken();

        // check owner
        if(msg.sender != ownerOf(_tokenId)) revert YouDontEvenOwnThisOgOneOfOne();

        // emit event
        emit Transfer(address(this), msg.sender, _tokenId);
    }



    //-------------------------------------------------------------------------
    //
    //      erc721 metadata overrides
    //
    //-------------------------------------------------------------------------

    // see IERC721Metadata-tokenURI
    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        // check if token exists
        if(!_exists(_tokenId)) revert WhoaThisTokenIdDoesntExist();

        // get trait and layer indexes
        uint256[2] memory traitLayer = TokenToTraitLayerMap[_tokenId];

        // get layer
        Layer memory layer = Traits[traitLayer[0]].layers[traitLayer[1]];

        // generate svg
        string memory svg = string.concat(
            SvgStrings[0], // svg intro
            TokenToDarkModeMap[_tokenId] ? SvgStrings[1] : SvgStrings[2], // js, grads, filter
            _toString(_tokenId),
            ' - ',
            layer.name,
            SvgStrings[3],
            addDecimalFromTheRight(5000-((layer.width*10)/2), 2),
            SvgStrings[4],
            addDecimalFromTheRight(5000-((layer.height*10)/2), 2),
            SvgStrings[5],
            getTokenLayerString(_tokenId),
            SvgStrings[6]
        );

        // generate metadata
        string memory metadata = string.concat(
            MetadataStrings[0],
            _toString(_tokenId),
            MetadataStrings[1],
            layer.traitName,
            MetadataStrings[2],
            layer.name,
            MetadataStrings[3],
            svg,
            MetadataStrings[4]
        );

        return metadata;
    }

    // allows owners to update light/dark mode
    function toggleDarkMode(uint256 _tokenId) public
    {        
        // check if caller is owner
        if(msg.sender != ownerOf(_tokenId)) revert YouDontOwnThisTokenThough();

        // do the thing!
        TokenToDarkModeMap[_tokenId] = !TokenToDarkModeMap[_tokenId];
    }



    //-------------------------------------------------------------------------
    //
    //      layer storage
    //
    //-------------------------------------------------------------------------

    // update trait name
    function updateTraitName(uint256 _traitIndex, string memory _name) external onlyOwner
    {
        Traits[_traitIndex].name = _name;
    }

    // add trait layer
    function addTraitLayer(uint256 _traitIndex, string memory _newName, uint256 _x, uint256 _y, uint256 _width, uint256 _height) external onlyOwner
    {
        // generate new layer
        Layer memory newLayer;
        newLayer.name = _newName;
        newLayer.x = _x;
        newLayer.y = _y;
        newLayer.width = _width;
        newLayer.height = _height;
        newLayer.traitName = Traits[_traitIndex].name;

        // update trait with new layer
        Traits[_traitIndex].layers.push(newLayer);

        // update layer count
        LayerCount++;
    }

    // add layer pointer by string
    function addLayerPointer(uint256 _traitIndex, uint256 _layerIndex, address _pointer) external onlyOwner
    {
        Traits[_traitIndex].layers[_layerIndex].pointers.push(_pointer);
    }

    // add layer pointer by string
    function addLayerString(uint256 _traitIndex, uint256 _layerIndex, string memory _newString) external onlyOwner returns(address)
    {
        address pointer = SSTORE2.write(bytes(_newString));
        Traits[_traitIndex].layers[_layerIndex].pointers.push(pointer);
        return pointer;
    }
    
    // update layer info
    function updateLayerInfo(uint256 _traitIndex, uint256 _layerIndex, string memory _newName, uint256 _x, uint256 _y, uint256 _width, uint256 _height) external onlyOwner
    {
        Trait storage trait = Traits[_traitIndex];
        Layer storage layer = trait.layers[_layerIndex];
        layer.name = _newName;
        layer.x = _x;
        layer.y = _y;
        layer.width = _width;
        layer.height = _height;
        layer.traitName = trait.name;
    }

     // add layer pointer by address
    function updateLayerPointer(uint256 _traitIndex, uint256 _layerIndex, uint256 _pointerIndex, address _pointer) external onlyOwner
    {
        Traits[_traitIndex].layers[_layerIndex].pointers[_pointerIndex] = _pointer;
    }

    // reset layer pointers... cause fat fingers
    function resetLayerPointers(uint256 _traitIndex, uint256 _layerIndex) external onlyOwner
    {
        delete Traits[_traitIndex].layers[_layerIndex].pointers;
    }
    
    // update token mapping
    function updateTokenToTraitLayerMap(uint256 _tokenId, uint256 _traitIndex, uint256 _layerIndex) external onlyOwner
    {
        TokenToTraitLayerMap[_tokenId] = [_traitIndex, _layerIndex];
    }



    //-------------------------------------------------------------------------
    //
    //      public layer functions, have fun!
    //
    //-------------------------------------------------------------------------

    // get trait
    function getTrait(uint256 _traitIndex) public view returns(Trait memory)
    {
        return Traits[_traitIndex];
    }

    // get layer
    function getLayer(uint256 _traitIndex, uint256 _layerIndex) public view returns(Layer memory)
    {
        return Traits[_traitIndex].layers[_layerIndex];
    }

    // read layer
    function readLayerString(uint256 _traitIndex, uint256 _layerIndex) public view returns(string memory)
    {
        // if complex shape not loaded, return empty string
        if(Traits[_traitIndex].layers[_layerIndex].pointers.length == 0)
        {
            return "";
        }

        // return layer string
        uint256 i;
        string memory output;
        address[] memory pointers = Traits[_traitIndex].layers[_layerIndex].pointers;

        unchecked
        {
            do
            {
                output = string.concat(output, string(SSTORE2.read(pointers[i])));
                ++i;
            } while(i<pointers.length);
        }
        return output;
    }

    // returns the tokens base64 string
    function getTokenLayerString(uint256 _tokenId) public view returns(string memory)
    {
        // get token layer
        uint256[2] memory traitLayer = TokenToTraitLayerMap[_tokenId];

        // return layer string
        return readLayerString(traitLayer[0], traitLayer[1]);
    }



    //-------------------------------------------------------------------------
    //
    //      other functions
    //
    //-------------------------------------------------------------------------

    // add decimal number from the right
    function addDecimalFromTheRight(uint256 _number, uint256 _sigFigs) public pure returns(string memory)
    {
        // get initial variables
        string memory numString = _toString(_number);
        uint256 length = bytes(numString).length;
        bytes memory decimal = new bytes(_sigFigs);

        unchecked
        {
            // check if sig fig greater thant length (0 padded)
            if(_sigFigs > length)
            {
                uint256 i = _sigFigs-length;
                do
                {
                    if(i < _sigFigs-length)
                    {
                        decimal[i] = bytes("0")[0];
                    } else
                    {
                        decimal[i] = bytes(numString)[i-(_sigFigs-length)];
                    }
                    --i;
                } while(i>0);
                
                decimal[0] = "0";
                // return string
                return string.concat("0", ".", string(decimal));

            // sig figs is = length
            } else if(_sigFigs == length)
            {
                // return string
                return string.concat("0", ".", numString);
            
            // sig figs < length
            } else
            {
                uint256 wholeIndex;
                uint256 decimalIndex;
                uint256 i;
                bytes memory whole = new bytes(length-_sigFigs);
                do
                {
                    if(i < length-_sigFigs)
                    {
                        whole[wholeIndex] = bytes(numString)[i];
                        ++wholeIndex;
                    } else
                    {
                        decimal[decimalIndex] = bytes(numString)[i];
                        ++decimalIndex;
                    }
                    ++i;
                } while(i<length);
                
                // return string
                return string.concat(string(whole), ".", string(decimal));
            }   
        }
    }

    // withdraw address (nod to NN)
    address private JeffFromAccounting;

    // update withdraw address
    function updateAccountant(address _newAddress) external onlyOwner
    {
        JeffFromAccounting = _newAddress;
    }

    // withdraw contract eth
    function moveThatGuap() public
    {
        (bool success, ) = JeffFromAccounting.call{value: address(this).balance}("");
        if(!success) revert SorryCouldntWithdrawYourFundsDude();
    }

}

interface IMferLayerPass
{
    function ownerOf(uint256) external view returns(address);
}

interface IOgMferContract
{
    function ownerOf(uint256) external view returns(address);
}



///////////////////////////////////////////////////////////////
//  giving doesnt make you charitable, it makes you free ❤  //
///////////////////////////////////////////////////////////////