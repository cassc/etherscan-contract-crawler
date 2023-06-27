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

    (phase 3)
    
    vision: @DadMod_xyz & @galtoshi
    art: @thompsonNFT
    devs: @JofaMcBender & @0xSomeGuy

    with the support of:
    sartoshi: 0xF95752fD023fD8802Abdd9cbe8e9965F623F8A84
    mfer community: 0x79FCDEF22feeD20eDDacbB2587640e45491b757f

*/


/*
    Note - Some modificaitons made to ERC721:
        updated _currentIndex
            uint256 private _currentIndex = 10021;
        remove currentIndex from constructor
            //_currentIndex = _startTokenId();
        blocked setApprovalForAll function
        blocked Approve function
*/
import "./ERC721A-OCMfers.sol";
import "./extras/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


error ReallyWantToClaimThisForYouButTheFundsArentRight();
error WhoaFriendCantUpdateGoodiesForTokensYouDontOwn();
error WhyYouTryingToClaimOtherPeoplesTokens();
error YouWereTheLastToClaimThisTokenAlready();
error SorryCouldntWithdrawYourFundsDude();
error UmmDontThinkThisIsAnOgTokenId();
error WeDontDoThatAroundHere();
error WeSoulBoundFam();

// all tokens in this contract are soul-bound, non-tradeable tokens
// they map back to the original mfer contract

contract OnChainMfers is ERC721A, Ownable, ReentrancyGuard
{

    //-------------------------------------------------------------------------
    //
    //      contract shiz
    //
    //-------------------------------------------------------------------------

    constructor() ERC721A("OnChainMfers", "SHDW")
    {
        JeffFromAccounting = msg.sender;
        // nothing else to see here folks 👇
    }

    // claim price
    uint256 public ClaimPrice;
    // update claim price, will attempt to always keep claim price at ~$69 USD
    function updateClaimPrice(uint256 _newPrice) external onlyOwner
    {
        ClaimPrice = _newPrice;
    }
    
    // maps token index to its mfer dna
    mapping (uint256 => uint256) public TokenToDnaMap;
    // maps dna to bool if claimed to avoid duplicates
    mapping (uint256 => bool) public DnaToClaimedMap;
    // maps og token to claimed status
    mapping (uint256 => bool) public OgTokenToClaimedMap;
    // maps last claim address to token
    mapping (uint256 => address) public OgTokenToLastClaimedMap;
    
    // original mfer contract
    IOgMferContract private OgMferContract;
    // update mfer contract address
    function setOgMferContractAddress(address _newAddress) external onlyOwner
    {
        OgMferContract = IOgMferContract(address(_newAddress));
    }
    // contract address for the layer contract to pull/read trait assets
    IMferLayers private MferLayerContract;
    // update layer contract address
    function setLayerContractAddress(address _newAddress) external onlyOwner
    {
        MferLayerContract = IMferLayers(address(_newAddress));
    } 



    //-------------------------------------------------------------------------
    //
    //      erc721-ish functions
    //
    //-------------------------------------------------------------------------

    // claim og mfer (transfers token to current og mfer owner)
    function claimOgMfer(uint256 _tokenId) public payable
    {
        // check if token exists
        if(!_exists(_tokenId)) revert UmmDontThinkThisIsAnOgTokenId();

        // get og owner
        address ogOwner = OgMferContract.ownerOf(_tokenId);

        // check if sender is not contract owner
        if(msg.sender != owner())
        {
            // check if sender is og owner
            if(msg.sender != ogOwner) revert WhyYouTryingToClaimOtherPeoplesTokens();
            
            // check payment
            if(!OgTokenToClaimedMap[_tokenId] && msg.value != ClaimPrice) revert ReallyWantToClaimThisForYouButTheFundsArentRight();
        }

        // check if already claimed, set to claimed
        if(!OgTokenToClaimedMap[_tokenId])
        {   
            // update claimed map
            OgTokenToClaimedMap[_tokenId] = true;
        } 

        // get last claimed address
        address originAddress = OgTokenToLastClaimedMap[_tokenId];

        // update last claimed address
        OgTokenToLastClaimedMap[_tokenId] = ogOwner;

        // revert if last claimed is same as current owner
        if(originAddress == ogOwner) revert YouWereTheLastToClaimThisTokenAlready();
        
        // claim token
        emit Transfer(originAddress, ogOwner, _tokenId);   
    }

    // onwer of override
    function ownerOf(uint256 _tokenId) public view override returns (address)
    {
        // check if token exists
        if(!_exists(_tokenId)) revert UmmDontThinkThisIsAnOgTokenId();

        // return og owner
        return OgMferContract.ownerOf(_tokenId);
    }

    // dont allow OG transfers
    function transferFrom(address from, address to, uint256 tokenId) public payable override
    {
        revert WeSoulBoundFam();
    }

    // dont allow approvals
    function approve(address to, uint256 tokenId) public payable override
    {
        revert WeDontDoThatAroundHere();
    }

    // dont allow operator approvals
    function setApprovalForAll(address operator, bool approved) public override
    {
        revert WeDontDoThatAroundHere();
    }

    function _exists(uint256 tokenId) internal view override returns (bool)
    {
        return tokenId < 10021;
    }
    

    

    //-------------------------------------------------------------------------
    //
    //      erc721 metadata functions
    //
    //-------------------------------------------------------------------------


    function tokenURI(uint256 _tokenId) public view override returns(string memory)
    {
        // check token exists
        if(!_exists(_tokenId)) revert UmmDontThinkThisIsAnOgTokenId();

        // check if og token and has not been claimed
        if(!OgTokenToClaimedMap[_tokenId])
        {
            // return unclaimed metadata
            return string.concat(UnclaimedMetadata[0], _toString(_tokenId), UnclaimedMetadata[1], MferLayerContract.readLayerString(UnclaimedLayerData[0], UnclaimedLayerData[1]), UnclaimedMetadata[2]);
        }

        // get dna
        uint256 tokenDNA = TokenToDnaMap[_tokenId];

        // check for goodies
        bool GoodiesAreOn = (GoodiesEnabled && TokenToGoodiesMap[_tokenId]);

        // get temporary variables
        IMferLayers.Trait memory trait;
        IMferLayers.Layer memory layer;
        uint256 attIndex;
        bool firstTraitFound;
        bool surpriseFound;

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
            if(i == GoodiesPosition && GoodiesAreOn)
            {
                // add goodies
                svg = string.concat(
                    svg,
                    DaGoodies[0]
                );
            }

            // get attribute index
            attIndex = getTraitIndex(tokenDNA, 14-i);

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
                        getSurpriseString(0)
                    );
                    surpriseFound = true;
                } else if(attIndex == 2)
                {
                    svg = string.concat(
                        svg,
                        getSurpriseString(1)
                    );
                    surpriseFound = true;
                }
            }

            // check if goodies should be added
            if(i == GoodiesPosition && GoodiesAreOn)
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
            surpriseFound ? SurpriseStuff : '',
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

    function getLayerSvg(IMferLayers.Layer memory _layer) private view returns(string memory)
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

    string[7] private SvgStrings;
    function updateSvgStrings(uint256 _index, string memory _newString) external onlyOwner
    {
        SvgStrings[_index] = _newString;
    }

    string[8] private MetadataStrings;
    function updateMetadataStrings(uint256 _index, string memory _newString) external onlyOwner
    {
        MetadataStrings[_index] = _newString;
    }

    uint256[2] private UnclaimedLayerData;
    function updateUnclaimedLayerData(uint256 _traitIndex, uint256 _layerIndex) external onlyOwner
    {
        UnclaimedLayerData[0] = _traitIndex;
        UnclaimedLayerData[1] = _layerIndex;
    }

    string[3] private UnclaimedMetadata;
    // update unlciamed metadata
    function updateUnclaimedMetadata(uint256 _index, string memory _newString) external onlyOwner
    {
        UnclaimedMetadata[_index] = _newString;
    }

    string private SurpriseStuff;
    function updateSurpriseStuff(string memory _newString) external onlyOwner
    {
        SurpriseStuff = _newString;
    }
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
                    "' visibility='hidden' href='data:image/png;charset=utf-8;base64,",
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
                "' visibility='hidden' href='data:image/png;charset=utf-8;base64,",
                readPointerArray(tempLayer.pointers),
                SvgStrings[5]
            );
    }

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
    //      more functions
    //
    //-------------------------------------------------------------------------    

    // get mapped trait from dna
    function getTraitIndex(uint256 _intDna, uint256 _traitIndex) private pure returns(uint256)
    {
        uint256 bitMask = 255 << (8 * _traitIndex);
        uint256 value = (_intDna & bitMask) >> (8 * _traitIndex);
        return value;
    }
    
    // goodies go before this trait index
    uint256 public GoodiesPosition;
    // update goodies position
    function updateGoodiesPosition(uint256 _index) external onlyOwner
    {
        GoodiesPosition = _index;
    }
    // goodie string
    string[2] public DaGoodies;
    // update the goodies string
    function updateTheGoodies(uint256 _index, string memory _newString) external onlyOwner
    {
        DaGoodies[_index] = _newString;
    }
    // bool to enable or disable goodies in contract
    bool public GoodiesEnabled;
    // toggle goodies enabled for contract
    function toggleGoodiesEnabled() external onlyOwner
    {
        GoodiesEnabled = !GoodiesEnabled;
    }
    
    // maps token index to goodies enabled for individual tokens
    mapping(uint256 => bool) public TokenToGoodiesMap;
    // allows token owners to decide if they want goodies in their image
    function toggleTokenGoodies(uint256 _tokenId) public
    {
        // check if token exists
        if(!_exists(_tokenId)) revert UmmDontThinkThisIsAnOgTokenId();

        // ensure that msg.sender is token owner
        if(msg.sender != ownerOf(_tokenId)) revert WhoaFriendCantUpdateGoodiesForTokensYouDontOwn();

        // update goodies
        TokenToGoodiesMap[_tokenId] = !TokenToGoodiesMap[_tokenId];
    }



    //-------------------------------------------------------------------------
    //
    //      other functions
    //
    //-------------------------------------------------------------------------

    // function to set og dnas
    function setOgDna(uint256 _tokenId, uint256 _dna) external onlyOwner
    {
        // map token index to dna
        TokenToDnaMap[_tokenId] = _dna;
        // set dna claimed to true
        DnaToClaimedMap[_dna] = true;
    }



    //-------------------------------------------------------------------------
    //
    //      custom functions
    //
    //-------------------------------------------------------------------------

    // withdraw address
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

    function getTrait(uint256 _traitIndex) external view returns(Trait memory);
    function getLayer(uint256 _traitIndex, uint256 _layerIndex) external view returns(Layer memory);
    function readLayerString(uint256 _traitIndex, uint256 _layerIndex) external view returns(string memory);
    function ownerOf(uint256) external view returns(address);
}


interface IOgMferContract
{
    function ownerOf(uint256) external view returns(address);
}