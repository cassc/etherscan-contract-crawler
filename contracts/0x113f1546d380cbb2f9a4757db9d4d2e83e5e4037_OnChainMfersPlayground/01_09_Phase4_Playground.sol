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

    (phase 4)
    
    vision: @DadMod_xyz & @galtoshi
    art: @thompsonNFT
    devs: @JofaMcBender & @0xSomeGuy

    with the support of:
    sartoshi: 0xF95752fD023fD8802Abdd9cbe8e9965F623F8A84
    mfer community: 0x79FCDEF22feeD20eDDacbB2587640e45491b757f

*/


import "./extras/SSTORE2.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


error WhoaFriendCantUpdateGoodiesForTokensYouDontOwn();
error NaahhhhhhhhhhThisIndexNeedsMoreThanEightBits();
error DaaaaaaaaangThisMferIsAlreadyTaken();
error SorryCouldntWithdrawYourFundsDude();
error NeedTheRightFundsToMintHomie();
error ThisTokenIsLostInSpace();
error PartyIsDeadAtTheMoment();
error ThisDnaIsNoGoodAmigo();
error NoFreeMintsHomie();


contract OnChainMfersPlayground is ERC721A, Ownable, ReentrancyGuard
{

    //-------------------------------------------------------------------------
    //
    //      contract shiz
    //
    //-------------------------------------------------------------------------

    constructor() ERC721A("OnChainMfersPlayground", "FAFO")
    {
        JeffFromAccounting = msg.sender;
        // nothing else to see here folks 👇
    }

    // mint status
    bool public IsPartyStarted;
    // toggle mint status
    function letsGetThisPartyStarted() external onlyOwner
    {
        IsPartyStarted = !IsPartyStarted;
    }

    // mint price
    uint256 public PlaygroundMintPrice;
    // update mint price, will attempt to always keep mint price at ~$69 USD
    function updateMintPrice(uint256 _newPrice) external onlyOwner
    {
        PlaygroundMintPrice = _newPrice;
    }
    
    // maps token index to dna
    mapping (uint256 => uint256) public TokenToDnaMap;
    // maps dna to claimed status to avoid dupes
    mapping (uint256 => bool) public PlaygroundDnaToClaimedMap;
    // maps address to number of free claims
    mapping (address => uint256) public AddressToFreebiesMap;
    // maps token to special status
    mapping (uint256 => bool) public TokenToIsSpecialMap;
    // maps token to special pointers
    mapping (uint256 => address[]) public TokenToSpecialPointersMap;
    // maps token index to goodies enabled for individual tokens
    mapping(uint256 => bool) public TokenToGoodiesMap;

    // svg strings
    string[7] public SvgStrings;
    // metadata strings
    string[8] public MetadataStrings;
    // trait counts for dna check
    uint256[14] public TraitCounts;
    // infinity symbol
    string public InfinityString;
    // sartoshi signature
    string public SartoshiString;
    // goodies go before this trait index
    uint256 public GoodiesPosition;
    // goodie string
    string[2] public DaGoodies;
    // bool to enable or disable goodies in collection
    bool public GoodiesEnabled;
    
    // contract address for the layer contract to pull/read trait assets
    IMferLayers private MferLayerContract = IMferLayers(address(0x5377c667acc68ea7cc5768D75388d7a97af5492c));
    // update layer contract address
    function setLayerContractAddress(address _newAddress) external onlyOwner
    {
        MferLayerContract = IMferLayers(address(_newAddress));
    }
    // on chain mfers contract to check if og dnas are trying to be used
    IOgChainContract private OgChainContract = IOgChainContract(address(0xF647f29860335E064fAc9f1Fe28BC8C9fd5331b0));
    // update chain contract address
    function setChainContractAddress(address _newAddress) external onlyOwner
    {
        OgChainContract = IOgChainContract(address(_newAddress));
    }



    //-------------------------------------------------------------------------
    //
    //      erc721 functions
    //
    //-------------------------------------------------------------------------

    // start token id override
    function _startTokenId() internal view override returns (uint256)
    {
        return 10021;
    }

    // free mint
    function freePlaygroundMint(uint256 _dna) public
    {
        // check if free mints available
        if(AddressToFreebiesMap[msg.sender] == 0) revert NoFreeMintsHomie();

        // decrease free mint count
        AddressToFreebiesMap[msg.sender]--;

        // mint
        mintOnChainMfer(_dna);
    }

    // paid mint
    function paidPlaygroundMint(uint256 _dna) public payable
    {
        // check payment
        if(msg.value != PlaygroundMintPrice) revert NeedTheRightFundsToMintHomie();

        // mint
        mintOnChainMfer(_dna);
    }

    // mint mint
    function mintOnChainMfer(uint256 _dna) private nonReentrant
    {
        // check if mint is active
        if(!IsPartyStarted) revert PartyIsDeadAtTheMoment();
        
        // check if dna is valid
        if(!isDnaValid(_dna)) revert ThisDnaIsNoGoodAmigo();
        
        // check if og dna taken
        if(OgChainContract.DnaToClaimedMap(_dna)) revert DaaaaaaaaangThisMferIsAlreadyTaken();

        // check if dna is already minted
        if(PlaygroundDnaToClaimedMap[_dna]) revert DaaaaaaaaangThisMferIsAlreadyTaken();

        // update token to dna map
        TokenToDnaMap[_nextTokenId()] = _dna;
        
        // update dna claimed map
        PlaygroundDnaToClaimedMap[_dna] = true;

        // mint that thing!
        _mint(msg.sender, 1);
    }

    // mint for da ownersssss
    function bossMint(uint256 _dna, bool _isSpecial) external onlyOwner
    {
        // check if minting special token
        if(!_isSpecial)
        {
            // check if og dna taken
            if(OgChainContract.DnaToClaimedMap(_dna)) revert DaaaaaaaaangThisMferIsAlreadyTaken();
            
            // check if dna is already minted
            if(PlaygroundDnaToClaimedMap[_dna]) revert DaaaaaaaaangThisMferIsAlreadyTaken();

            // check if dna is valid
            if(!isDnaValid(_dna)) revert ThisDnaIsNoGoodAmigo();
            
            // update token to dna map
            TokenToDnaMap[_nextTokenId()] = _dna;
            
            // update dna claimed map
            PlaygroundDnaToClaimedMap[_dna] = true;
        } else
        {
            // update special mappings
            TokenToIsSpecialMap[_nextTokenId()] = true;
        }
        
        // mint that thing!
        _mint(msg.sender, 1);
    }

    // you get a mint, you get a mint
    function bestowMintsGratis(address _addy, uint256 _numMints) external onlyOwner
    {
        AddressToFreebiesMap[_addy] += _numMints;
    }
    


    //-------------------------------------------------------------------------
    //
    //      erc721 metadata functions
    //
    //-------------------------------------------------------------------------

    // token uri
    function tokenURI(uint256 _tokenId) public view override returns(string memory)
    {
        // check token exists
        if(!_exists(_tokenId)) revert ThisTokenIsLostInSpace();

        // check if token is special
        if(TokenToIsSpecialMap[_tokenId])
        {
            return readPointerArray(TokenToSpecialPointersMap[_tokenId]);
        }
        
        // check for goodies
        bool GoodiesAreOn = (GoodiesEnabled && TokenToGoodiesMap[_tokenId]);

        if(GoodiesAreOn)
        {
            return goodieURI(_tokenId);
        } else
        {
            return nonGoodieURI(_tokenId);
        }
    }

    // get non goodie metadata
    function nonGoodieURI(uint256 _tokenId) private view returns(string memory)
    {
        // get dna
        uint256 tokenDna = TokenToDnaMap[_tokenId];

        // get temporary variables
        IMferLayers.Trait memory trait;
        IMferLayers.Layer memory layer;
        uint256 attIndex;
        bool firstTraitFound;
        
        // metadata
        string memory metadata = string.concat(
            MetadataStrings[0],
            _toString(_tokenId),
            MetadataStrings[1]
        );

        // start the svg image
        string memory svg = SvgStrings[0];

        // loopty loop
        for(uint256 i=0; i<15; i++)
        {
            // get attribute index
            attIndex = getTraitIndex(tokenDna, i);

            // check if trait is blank
            if(attIndex == 0)
            {
                // blank trait, keep it moving
                continue;
            }

            // get trait from layer contract
            trait = MferLayerContract.getTrait(i);
            // get the attribute index
            attIndex = attIndex-1;
            // get layer from trait
            layer = trait.layers[attIndex];
            // append layer to svg
            svg = string.concat(
                svg,
                getLayerSvg(layer)
            );

            // check for surprise
            if(i == 2)
            {
                if(attIndex == 6)
                {
                    svg = string.concat(
                        svg,
                        getSurpriseString(0),
                        SurpriseStuff
                    );
                } else if(attIndex == 2)
                {
                    svg = string.concat(
                        svg,
                        getSurpriseString(1),
                        SurpriseStuff
                    );
                }
            }

            // update metadata
            metadata = string.concat(
                metadata,
                firstTraitFound ? MetadataStrings[2] : MetadataStrings[3],
                trait.name,
                MetadataStrings[4],
                layer.name,
                MetadataStrings[5]
            );
            // update trait exists for correct metadata
            firstTraitFound = true;
        }

        // complete the svg
        svg = string.concat(
            svg,
            _tokenId > 10024 ? InfinityString : '',
            getTraitIndex(tokenDna, 1) == 0 ?  SartoshiString : "",
            SvgStrings[6]);
        // complete the metadata
        metadata = string.concat(
            metadata,
            MetadataStrings[6],
            svg,
            MetadataStrings[7]
        );
        
        // return that shizzle!
        return metadata;
    }

    // get goodie metadata
    function goodieURI(uint256 _tokenId) private view returns(string memory)
    {
        // get dna
        uint256 tokenDna = TokenToDnaMap[_tokenId];

        // get temporary variables
        IMferLayers.Trait memory trait;
        IMferLayers.Layer memory layer;
        uint256 attIndex;
        bool firstTraitFound;
        
        // metadata
        string memory metadata = string.concat(
            MetadataStrings[0],
            _toString(_tokenId),
            MetadataStrings[1]
        );

        // start the svg image
        string memory svg = SvgStrings[0];

        // loopty loop
        for(uint256 i=0; i<15; i++)
        {
            // check if goodies should be added
            if(i == GoodiesPosition)
            {
                // add goodies
                svg = string.concat(
                    svg,
                    DaGoodies[0]
                );
            }

            // get attribute index
            attIndex = getTraitIndex(tokenDna, i);

            // check if trait is blank
            if(attIndex == 0)
            {
                // check if no type trait for sartoshi signature
                if(i == 1)
                {
                    svg = string.concat(
                        svg,
                        SartoshiString
                    );
                }

                // blank trait, keep it moving
                continue;
            }

            // get trait from layer contract
            trait = MferLayerContract.getTrait(i);
            // get the attribute index
            attIndex = attIndex-1;
            // get layer from trait
            layer = trait.layers[attIndex];
            // append layer to svg
            svg = string.concat(
                svg,
                getLayerSvg(layer)
            );

            // check for surprise
            if(i == 2)
            {
                if(attIndex == 6)
                {
                    svg = string.concat(
                        svg,
                        getSurpriseString(0),
                        SurpriseStuff
                    );
                } else if(attIndex == 2)
                {
                    svg = string.concat(
                        svg,
                        getSurpriseString(1),
                        SurpriseStuff
                    );
                }
            }

            // check if goodies should be added
            if(i == GoodiesPosition)
            {
                // add goodies
                svg = string.concat(
                    svg,
                    DaGoodies[1]
                );
            }

            // update metadata
            metadata = string.concat(
                metadata,
                firstTraitFound ? MetadataStrings[2] : MetadataStrings[3],
                trait.name,
                MetadataStrings[4],
                layer.name,
                MetadataStrings[5]
            );
            // update trait exists for correct metadata
            firstTraitFound = true;
        }

        // complete the svg
        svg = string.concat(
            svg,
            _tokenId > 10024 ? InfinityString : '',
            getTraitIndex(tokenDna, 1) == 0 ?  SartoshiString : "",
            SvgStrings[6]);
        // complete the metadata
        metadata = string.concat(
            metadata,
            MetadataStrings[6],
            svg,
            MetadataStrings[7]
        );
        
        // return that shizzle!
        return metadata;
    }
    
    // allows token owners to decide if they want goodies in their image
    function toggleTokenGoodies(uint256 _tokenId) public
    {
        // check if token exists
        if(!_exists(_tokenId)) revert ThisTokenIsLostInSpace();

        // ensure that msg.sender is token owner
        if(msg.sender != ownerOf(_tokenId)) revert WhoaFriendCantUpdateGoodiesForTokensYouDontOwn();

        // update goodies
        TokenToGoodiesMap[_tokenId] = !TokenToGoodiesMap[_tokenId];
    }
    
    // get layer svg
    function getLayerSvg(IMferLayers.Layer memory _layer) public view returns(string memory)
    {
        return string.concat(
            SvgStrings[1],
            _layer.name,
            SvgStrings[2],
            _toString(_layer.x),
            SvgStrings[3], 
            _toString(_layer.y),
            SvgStrings[4],
            readPointerArray(_layer.pointers),
            SvgStrings[5]
        );
    }
    
    // get the suuuuuurprise string
    function getSurpriseString(uint256 _index) private view returns(string memory)
    {
        IMferLayers.Layer memory tempLayer;
        if(_index == 0)
        {
            tempLayer = MferLayerContract.getLayer(2, 2);
            return string.concat(
                    SvgStrings[1],
                    tempLayer.name,
                    SvgStrings[2],
                    _toString(tempLayer.x),
                    SvgStrings[3], 
                    _toString(tempLayer.y),
                    SurpriseFiller,
                    readPointerArray(tempLayer.pointers),
                    SvgStrings[5]
                );
        }

        tempLayer = MferLayerContract.getLayer(2, 6);
        return string.concat(
                SvgStrings[1],
                tempLayer.name,
                SvgStrings[2],
                _toString(tempLayer.x),
                SvgStrings[3], 
                _toString(tempLayer.y),
                SurpriseFiller,
                readPointerArray(tempLayer.pointers),
                SvgStrings[5]
            );
    }

    // read array of pointers
    function readPointerArray(address[] memory _pointers) public view returns(string memory)
    {
        // if complex shape not loaded, return empty string
        if(_pointers.length == 0)
        {
            return "";
        }

        // return layer string
        uint256 i;
        string memory output;
        unchecked
        {
            do
            {
                output = string.concat(output, string(SSTORE2.read(_pointers[i])));
                ++i;
            } while(i<_pointers.length);
        }
        return output;
    }



    //-------------------------------------------------------------------------
    //
    //      extra tings
    //
    //-------------------------------------------------------------------------    
    
    // update svg strings
    function updateSvgStrings(uint256 _index, string memory _newString) external onlyOwner
    {
        SvgStrings[_index] = _newString;
    }

    // update metadata strings
    function updateMetadataStrings(uint256 _index, string memory _newString) external onlyOwner
    {
        MetadataStrings[_index] = _newString;
    }

    // toggle special token
    function toggleSpecialStatus(uint256 _tokenId) external onlyOwner
    {
        TokenToIsSpecialMap[_tokenId] = !TokenToIsSpecialMap[_tokenId];
    }
    
    // update special pointers
    function addSpecialTokenPointer(uint256 _tokenId, address _pointer) external onlyOwner
    {
        TokenToSpecialPointersMap[_tokenId].push(_pointer);
    }

    // reset special token pointers
    function resetSpecialTokenPointers(uint256 _tokenId) external onlyOwner
    {
        delete TokenToSpecialPointersMap[_tokenId];
    }

    // update infinity string
    function setInfinityString(string memory _newString) external onlyOwner
    {
        InfinityString = _newString;
    }
    
    // update sartoshi string
    function setSartoshiString(string memory _newString) external onlyOwner
    {
        SartoshiString = _newString;
    }
    
    // update goodies position
    function updateGoodiesPosition(uint256 _index) external onlyOwner
    {
        GoodiesPosition = _index;
    }
    
    // update the goodies string
    function updateTheGoodies(uint256 _index, string memory _newString) external onlyOwner
    {
        DaGoodies[_index] = _newString;
    }
    
    // toggle goodies enabled for contract
    function toggleGoodiesEnabled() external onlyOwner
    {
        GoodiesEnabled = !GoodiesEnabled;
    }

    // get surprise stuffs
    string private SurpriseStuff;
    function updateSurpriseStuff(string memory _newString) external onlyOwner
    {
        SurpriseStuff = _newString;
    }
    string private SurpriseFiller;
    function setSurpriseFiller(string memory _newString) external onlyOwner
    {
        SurpriseFiller = _newString;
    }



    //-------------------------------------------------------------------------
    //
    //      other functions
    //
    //-------------------------------------------------------------------------

    // set token dna
    function setTokenDna(uint256 _tokenId, uint256 _dna) external onlyOwner
    {
        // check if dna is valid
        if(!isDnaValid(_dna)) revert ThisDnaIsNoGoodAmigo();

        // get current token dna
        uint256 curDna = TokenToDnaMap[_tokenId];

        // check if dna for this token exists
        if(curDna != 0)
        {
            // clear dna to claimed map
            PlaygroundDnaToClaimedMap[curDna] = false;
        }

        // update token to dna map
        TokenToDnaMap[_tokenId] = _dna;
        // update dna claimed map
        PlaygroundDnaToClaimedMap[_dna] = true;
    }

    // update trait counts for dna check
    function updateTraitCount(uint256 _index, uint256 _count) external onlyOwner
    {
        TraitCounts[_index] = _count;
    }



    //-------------------------------------------------------------------------
    //
    //      for your enjoyment
    //
    //-------------------------------------------------------------------------

    // get trait index from dna
    function getTraitIndex(uint256 _intDna, uint256 _traitIndex) public pure returns(uint256)
    {
        // check if trait index is too high
        if(_traitIndex > 14) revert("trait index too high");
        // get trait index
        uint256 bitTraitIndex = 14-_traitIndex;
        uint256 bitMask = 255 << (8 * bitTraitIndex);
        uint256 value = (_intDna & bitMask) >> (8 * bitTraitIndex);
        return value;
    }

    // check if dna is valid
    function isDnaValid(uint256 _dna) public view returns(bool)
    {
        // check if > than 15 8-bit nubers
        if(_dna > ((1 << 120)-1))
        {
            return false;
        }

        // check for 0 dna
        if(_dna == 0)
        {
            return false;
        }

        // get 1/1 trait index
        uint256 attIndex = getTraitIndex(_dna, 14);

        // check if 1/1 trait used
        if(attIndex != 0)
        {
            // 1/1s are special!
            return false;
        }
        
        // loopty loop to check individual trait values
        for(uint256 i=0; i<14; i++)
        {
            // get trait index at position i
            attIndex = getTraitIndex(_dna, i);

            // check if trait index is valid
            if(attIndex > TraitCounts[i])
            {
                return false;
            }
        }

        // all good
        return true;
    }

    // convert uint256[15] into uint256 dna for anyone who wants it
    function arrayToDna(uint256[15] memory _dnaArray) public pure returns(uint256)
    {
        // leggo
        uint256 intDna = 0;
        
        // loop through trait array
        for (uint256 i = 0; i < 15; i++)
        {
            // get trait index
            uint256 value = _dnaArray[i];
            
            // make sure its 8-bit
            if(value >255) revert NaahhhhhhhhhhThisIndexNeedsMoreThanEightBits();
            
            // shift the value to the appropriate position and add trait index
            intDna = (intDna << 8) | value;
        }
        
        // all done!
        return intDna;
    }



    //-------------------------------------------------------------------------
    //
    //      da rest
    //
    //-------------------------------------------------------------------------

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


// interface for the goodblocks contract
interface IMferLayers
{
    // trait data struct
    struct Trait
    {
        string name;
        Layer[] layers;
    }

    // layer data struct
    struct Layer
    {
        uint256 x;
        uint256 y;
        uint256 width;
        uint256 height;
        string name;
        address layerOwner;
        address[] pointers;
    }

    function getTrait(uint256 _traitIndex) external view returns(Trait memory);
    function getLayer(uint256 _traitIndex, uint256 _layerIndex) external view returns(Layer memory);
    function readLayerString(uint256 _traitIndex, uint256 _layerIndex) external view returns(string memory);
    function ownerOf(uint256) external view returns(address);
}

interface IOgChainContract
{
    function DnaToClaimedMap(uint256 key) external view returns (bool);
}


///////////////////////////////////////////////////////////////
//  do good ❤  ///////////////////////////////////////////////
///////////////////////////////////////////////////////////////