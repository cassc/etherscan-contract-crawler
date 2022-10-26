// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LTNTFont.sol";
import "base64-sol/base64.sol";


//////////////////////////////////
//
//
// LTNT
// Passport NFTs for Latent Works
//
//
//////////////////////////////////


/// @title LTNT
/// @author troels_a

contract LTNT is ERC721, Ownable {
    
    struct Param {
        uint _uint;
        address _address;
        string _string;
        bool _bool;
    }

    struct IssuerInfo {
        string name;
        string image;
    }

    struct Issuer {
        address location;
        Param param;
    }

    event Issued(uint indexed id, address indexed to);
    event Stamped(uint indexed id, address indexed stamper);

    LTNT_Meta private _ltnt_meta;

    address[] private _issuers; ///@dev array of addresses registered as issuers
    mapping(uint => mapping(address => bool)) private _stamps; ///@dev (ltnt => (issuer => is stamped?))
    mapping(uint => mapping(address => Param)) private _params; ///@dev (ltnt => (issuer => stamp parameters));
    mapping(uint => Issuer) private _issuer_for_id; ///@dev (ltnt => issuer) - the Issuer for a given LTNT
    
    uint private _ids; ///@dev LTNT _id counter

    /// @dev pass address of onchain fonts to the constructor
    constructor(address regular_, address italic_) ERC721("Latents", "LTNT"){

        LTNT_Meta ltnt_meta_ = new LTNT_Meta(address(this), regular_, italic_);
        _ltnt_meta = LTNT_Meta(address(ltnt_meta_));

    }




    /// @notice Require a given address to be a registered issuer
    /// @param caller_ the address to check for issuer privilegies
    function _reqOnlyIssuer(address caller_) private view {
        require(isIssuer(caller_), 'ONLY_ISSUER');
    }



    /// @notice Issue a token to the address
    /// @param to_ the address to issue the LTNT to
    /// @param param_ a Param struct of parameters associated with the token
    /// @param stamp_ boolean determining wether the newly issued LTNT should be stamped by the issuer
    /// @return uint the id of the newly issued LTNT
    function issueTo(address to_, Param memory param_, bool stamp_) public returns(uint){ _reqOnlyIssuer(msg.sender);
        
        _ids++;
        _safeMint(to_, _ids);
        _issuer_for_id[_ids] = Issuer(msg.sender, param_);

        emit Issued(_ids, to_);
        
        if(stamp_)
            _stamp(_ids, msg.sender, param_);

        return _ids;

    }



    /// @dev Lets a registered issuer stamp a given LTNT
    /// @param id_ the ID of the LTNT to stamp
    /// @param param_ a Param struct with any associated params
    function stamp(uint id_, Param memory param_) public { _reqOnlyIssuer(msg.sender);
        _stamp(id_, msg.sender, param_);
    }



    /// @dev internal stamping mechanism
    /// @param id_ the id of the LTNT to stamp
    /// @param issuer_ the address of the issuer stamping the LTNT
    /// @param param_ a Param struct with stamp parameters
    function _stamp(uint id_, address issuer_, Param memory param_) private {
        _stamps[id_][issuer_] = true;
        _params[id_][issuer_] = param_;
        emit Stamped(_ids, issuer_);
    }

    /// @dev checks if a given id_ is stamped by address_
    /// @param id_ the ID of the LTNT to check
    /// @param address_ the address of the stamper
    /// @return bool indicating wether LTNT is stamped
    function hasStamp(uint id_, address address_) public view returns(bool){
        return _stamps[id_][address_];
    }

    /// @dev get params for a given stamp on a LTNT
    /// @param id_ the id of the LTNT
    /// @param address_ the address of the stamper
    /// @return Param the param to return
    function getStampParams(uint id_, address address_) public view returns(Param memory){
        return _params[id_][address_];
    }

    /// @dev Get the addresses of the issuers that have stamped a given LTNT
    /// @param id_ the ID of the LTNT to fetch stamps for
    /// @return addresses an array of issuer addresses that have stamped the LTNT
    function getStamps(uint id_) public view returns(address[] memory){
        
        // First count the stamps
        uint count;
        for(uint i = 0; i < _issuers.length; i++){
            if(_stamps[id_][_issuers[i]])
                ++count;
        }

        // Init a stamps_ array with the right length from count_
        address[] memory stamps_ = new address[](count);

        // Loop over the issuers and save stampers in stamps_
        count = 0;
        for(uint i = 0; i < _issuers.length; i++){
            if(_stamps[id_][_issuers[i]]){
                stamps_[count] = _issuers[i];
                ++count;
            }
        }

        return stamps_;

    }

    /// @dev list all issuer addresses
    /// @return addresses list of all issuers
    function getIssuers() public view returns(address[] memory){
        return _issuers;
    }

    /// @dev get the issuer of a LTNT
    function getIssuerFor(uint id_) public view returns(LTNT.Issuer memory){
        return _issuer_for_id[id_];
    }

    /// @dev set the meta contract
    /// @param address_ the address of the meta contract
    function setMetaContract(address address_) public onlyOwner {
        _ltnt_meta = LTNT_Meta(address_);
    }

    /// @dev get the meta contract
    /// @return LTNT_Meta the meta contract currently in use
    function getMetaContract() public view returns(LTNT_Meta) {
        return _ltnt_meta;
    }

    /// @notice register an issuer address
    /// @param address_ the address of the issuer to add
    function addIssuer(address address_) public onlyOwner {
        _issuers.push(address_);
    }
    

    /// @notice determine if an address is a LW project
    /// @param address_ the address of the issuer
    /// @return bool indicating wether the address is an issuer or not
    function isIssuer(address address_) public view returns(bool){
        for(uint i = 0; i < _issuers.length; i++) {
            if(_issuers[i] == address_)
                return true;
        }
        return false;
    }


    /// @notice the ERC721 tokenURI for a given LTNT
    /// @param id_ the id of the LTNT
    /// @return json_ base64 encoded data URI containing the JSON metadata
    function tokenURI(uint id_) public view override returns(string memory json_){
        return _ltnt_meta.getJSON(id_, true);
    }


}


/// @title A title that should describe the contract/interface
/// @author troels_a
/// @dev Handles meta for this contract
contract LTNT_Meta {

    LTNT public immutable _ltnt;

    ///@dev latent fonts
    XanhMonoRegularLatin public immutable _xanh_regular;
    XanhMonoItalicLatin public immutable _xanh_italic;

    constructor(address ltnt_, address regular_, address italic_){

        _ltnt = LTNT(ltnt_);
        _xanh_regular = XanhMonoRegularLatin(regular_);
        _xanh_italic = XanhMonoItalicLatin(italic_);

    }

    /// @notice return image string for id_
    /// @param id_ the id of the LTNT to retrieve the image for
    /// @param encode_ encode output as base64 uri
    /// @return string the image string
    function getImage(uint id_, bool encode_) public view returns(string memory){

        LTNT.Issuer memory issuer_for_id_ = _ltnt.getIssuerFor(id_);
        LTNT.IssuerInfo memory issuer_info_ = LTNTIssuer(issuer_for_id_.location).issuerInfo(id_, issuer_for_id_.param);
        LTNT.IssuerInfo memory stamper_;
        LTNT.Param memory stamp_param_;
        address[] memory issuers_ = _ltnt.getIssuers();

        bytes memory stamps_svg_;
        string memory delay_;
        uint stamp_count_;
        bool has_stamp_;

        for(uint i = 0; i < issuers_.length; i++) {

            delay_ = Strings.toString(i*150);
            stamp_param_ = _ltnt.getStampParams(id_,issuers_[i]);
            stamper_ = LTNTIssuer(issuers_[i]).issuerInfo(id_, stamp_param_);
            has_stamp_ = _ltnt.hasStamp(id_, issuers_[i]);

            stamps_svg_ = abi.encodePacked(stamps_svg_, '<text class="txt italic" fill-opacity="0" y="',Strings.toString(25*i),'">',stamper_.name,' <animate attributeName="fill-opacity" values="0;',has_stamp_ ? '1' : '0.4','" dur="500ms" repeatCount="1" begin="',delay_,'ms" fill="freeze"/></text>');
            if(has_stamp_)
                ++stamp_count_;

        }

        bytes memory image_;
        image_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 1000" preserveAspectRatio="xMinYMin meet">',
                '<defs><style>', _xanh_regular.fontFace(), _xanh_italic.fontFace(),' .txt {font-family: "Xanh Mono"; font-size:20px; font-weight: normal; letter-spacing: 0.01em; fill: white;} .italic {font-style: italic;} .large {font-size: 55px;} .small {font-size: 12px;}</style><rect ry="30" rx="30" id="bg" height="1000" width="600" fill="black"/></defs>',
                '<use href="#bg"/>',
                '<g transform="translate(65, 980) rotate(-90)">',
                    '<text class="txt large italic">Latent Works</text>',
                '</g>',
                '<g transform="translate(537, 21) rotate(90)">',
                    '<text class="txt large italic">LTNT #',Strings.toString(id_),'</text>',
                '</g>',
                '<g transform="translate(517, 22) rotate(90)">',
                    '<text class="txt small">Issued by ',issuer_info_.name,unicode' · ', Strings.toString(stamp_count_) , stamp_count_ > 1 ? ' stamps' : ' stamp', '</text>',
                '</g>'
                '<g transform="translate(25, 25)">',
                    '<image width="300" href="', issuer_info_.image, '"/>',
                '</g>',
                '<g transform="translate(343, 41)">',
                    stamps_svg_,
                '</g>',
                '<g transform="translate(509, 980)">',
                    '<text class="txt small">latent.works</text>',
                '</g>',
            '</svg>'
        );

        if(encode_)
            image_ = abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(image_));

        return string(image_);

    }


    /// @notice return base64 encoded JSON metadata for id_
    /// @param id_ the id of the LTNT to retrieve the image for
    /// @param encode_ encode output as base64 uri
    /// @return string the image string
    function getJSON(uint id_, bool encode_) public view returns(string memory) {
        
        LTNT.Issuer memory issuer_for_id_ = _ltnt.getIssuerFor(id_);
        LTNT.IssuerInfo memory issuer_info_ = LTNTIssuer(issuer_for_id_.location).issuerInfo(id_, issuer_for_id_.param);

        bytes memory json_ = abi.encodePacked(
            '{',
                '"name":"LTNT #',Strings.toString(id_),'", ',
                '"image": "', getImage(id_, true),'", ',
                '"description": "latent.works",',
                '"attributes": [',
                    '{"trait_type": "Stamps", "value": ',Strings.toString(_ltnt.getStamps(id_).length),'},',
                    '{"trait_type": "Issuer", "value": "', issuer_info_.name, '"}',
                ']',
            '}'
        );

        if(encode_)
            json_ = abi.encodePacked('data:application/json;base64,', Base64.encode(json_));
        
        return string(json_);

    }


}


/// @title LTNTIssuer
/// @author troels_a
/// @dev LTNTIssuers implement this contract and use issuerInfo to pass info to LTNT main contract
abstract contract LTNTIssuer {
    function issuerInfo(uint id_, LTNT.Param memory param_) external virtual view returns(LTNT.IssuerInfo memory);
}