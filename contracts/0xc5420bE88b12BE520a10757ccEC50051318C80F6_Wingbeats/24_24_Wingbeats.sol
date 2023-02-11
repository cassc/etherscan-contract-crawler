// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@polly-tools/core/contracts/modules/Json.sol";
import "@polly-tools/core/contracts/modules/Meta.sol";
import "@polly-tools/core/contracts/modules/Token721.sol";
import "@polly-tools/core/contracts/PollyToken.sol";
import "@polly-tools/core/contracts/Polly.sol";
import "base64-sol/base64.sol";


contract Wingbeats is PollyAux, Ownable {

    // Polly
    Polly public immutable polly;
    Token721 public collection;
    Meta public meta;
    WingbeatsMetadata public metadata;

    bool private _initialised = false;

    uint public max_supply;
    uint public min_time;
    uint public price;
    
    
    constructor(address polly_) {
        polly = Polly(polly_);
        metadata = new WingbeatsMetadata();
    }


    /// UTILS

    function _stringIsEmpty(string memory string_) private pure returns (bool) {
        return keccak256(abi.encodePacked(string_)) == keccak256(abi.encodePacked(''));
    }

    function _stringEquals(string memory a_, string memory b_) private pure returns (bool) {
        return keccak256(abi.encodePacked(a_)) == keccak256(abi.encodePacked(b_));
    }




    /// ADMIN


    /// @notice Initialise the contract
    function initialise(
        uint max_supply_,
        uint min_time_,
        uint price_,
        string memory base_uri_
    ) public onlyOwner {

        // Check if already initialised
        require(!_initialised, 'ALREADY_INITIALISED');
        
        // Params for the Collection module
        Polly.Param[] memory params_ = new Polly.Param[](1);
        params_[0]._address = address(this); // Add this contract as a aux to the collection


        // Deploy the collection
        Polly.Param[] memory rparams_ = polly.configureModule(
            "Token721", // Module name
            1, // Module version
            params_, // Module params
            false, // Save module configuration in the Polly registry?
            '' // Module configuration name if saved
        );


        // Save the token and meta addresses for convenience
        collection = Token721(rparams_[0]._address);
        meta = Meta(rparams_[1]._address);

        // Set the royalty info on token
        collection.getMetaHandler().setUint(0, 'royaltyBase', 1000);
        collection.getMetaHandler().setAddress(0, 'royaltyRecipient', msg.sender);

        // Set collection details - min time, max supply and price
        min_time = min_time_;
        max_supply = max_supply_;
        price = price_;

        // Set the base uri
        meta.setString(0, 'baseUri', base_uri_);

        // Set the collection name and symbol
        meta.setString(0, 'externalLink', 'https://wingbeats.download');
        meta.setString(0, 'externalUrlBase', 'https://wingbeats.download/token');
        meta.setString(0, 'collectionName', 'Wingbeats');
        meta.lockIdKey(0, 'collectionName');
        meta.setString(0, 'collectionSymbol', 'WNGBTS');
        meta.lockIdKey(0, 'collectionSymbol');

        // Grant all privileges of the token and meta address to message sender
        collection.grantRole('admin', msg.sender);
        collection.grantRole('manager', msg.sender);
        meta.grantRole('admin', msg.sender);
        meta.grantRole('manager', msg.sender);

        // Mark as initialised
        _initialised = true;

    }


    /// @notice set the min time if not already open
    function setMinTime(uint min_time_) public onlyOwner {
        require(!open(), 'ALREADY_OPEN');
        min_time = min_time_;
    }

    /// @notice set the metadata contract
    function setMetadata(address metadata_) public onlyOwner {
        metadata = WingbeatsMetadata(metadata_);
    }



    /// HOOKS
    
    /// @notice Get the hooks this contract implements
    function hooks() public view virtual override returns (string[] memory) {
        string[] memory hooks_ = new string[](4);
        hooks_[0] = "filter_Meta_tokenUri";
        hooks_[1] = "filter_Meta_collectionUri";
        hooks_[2] = "action_BeforeMint721";
        hooks_[3] = "action_BeforeCreateToken";
        return hooks_;
    }

    /// @notice Runs before a token is created on the collection
    function action_BeforeCreateToken(uint, Polly.Param[] memory) public pure {
        revert('NO_MANUAL_CREATE');
    }

    /// @notice Runs before a token is minted on the collection
    function action_BeforeMint721(
        address, // to_
        uint id_,
        bool, // premint_
        PollyAux.Msg memory msg_
    ) public view {

        // Check if min time is met
        require(open(), 'MIN_TIME_NOT_REACHED');
        // Check if token has already been minted
        require(!collection.exists(id_), 'TOKEN_ID_ALREADY_MINTED');
        // Check if token id is within range 1 - 97
        require(id_ > 0 && id_ <= max_supply, 'TOKEN_ID_OUT_OF_RANGE');
        // Check if token price is correct
        require(price == msg_._value, 'INVALID_PRICE');

    }

    /// @notice Check if the min time has been reached
    function open() public view returns (bool) {
        return (block.timestamp >= min_time);
    }

    /// @notice Filters the token uri for a given token id in the collection
    function filter_Meta_tokenUri(uint id_, Polly.Param memory param_) public view returns (Polly.Param memory) {

        // Set the token uri on the param struct
        param_._string = metadata.tokenURI(id_);

        return param_;

    }

    /// @notice Filters the contract uri for the collection
    function filter_Meta_collectionUri(uint id_, Polly.Param memory param_) public view returns (Polly.Param memory) {

        if(id_ != 0) return param_; // Return if not the collection id = 0

        // Set the contract uri on the param struct
        param_._string = metadata.contractURI();

        return param_;

    }



}


contract WingbeatsMetadata {

    string public constant NAME = "Wingbeats";
    string public constant DESCRIPTION = "Wingbeats is a collection of 97 unique NFTs, each representing a fraction of a 40-minute experimental composition by the group Paris Peacock. Holding a Wingbeats NFT grants you access to the full music, liner notes and more on the Wingbeats website.";

    function tokenURI(uint id_) public view returns (string memory string_) {

        Wingbeats wingbeats_ = Wingbeats(msg.sender);
        Token721 collection = wingbeats_.collection();

        Json json_ = Json(wingbeats_.polly().getModule("Json", 1).implementation);

        string memory content_base_ = collection.getMeta(0, 'baseUri')._string;
        string memory image_uri_ = string(abi.encodePacked(content_base_, '/jpg/', Strings.toString(id_), '.jpg'));
        string memory audio_uri_ = string(abi.encodePacked(content_base_, '/mp3/', Strings.toString(id_), '.mp3'));
        string memory external_url_ = string(abi.encodePacked(collection.getMeta(0, 'externalUrlBase')._string, '/', Strings.toString(id_)));

        Json.Item[] memory items_ = new Json.Item[](6);

        items_[0]._key = "name";
        items_[0]._type = Json.Type.STRING;
        items_[0]._string = string(abi.encodePacked(NAME, " #", Strings.toString(id_)));

        items_[1]._key = "description";
        items_[1]._type = Json.Type.STRING;
        items_[1]._string = DESCRIPTION;

        items_[2]._key = "image";
        items_[2]._type = Json.Type.STRING;
        items_[2]._string = image_uri_;

        items_[3]._key = "license";
        items_[3]._type = Json.Type.STRING;
        items_[3]._string = "All rights reserved";

        items_[4]._key = "animation_url";
        items_[4]._type = Json.Type.STRING;
        items_[4]._string = audio_uri_;

        items_[5]._key = "external_url";
        items_[5]._type = Json.Type.STRING;
        items_[5]._string = external_url_;


        // Encode JSON and create data uri
        string_ = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(bytes(json_.encode(items_, Json.Format.OBJECT)))
        ));

        return string_;

    }


    function contractURI() public view returns (string memory string_) {

        Wingbeats wingbeats_ = Wingbeats(msg.sender);
        Token721 collection = wingbeats_.collection();

        Json json_ = Json(wingbeats_.polly().getModule("Json", 1).implementation);


        string memory content_base_ = collection.getMeta(0, 'baseUri')._string;


        // {
        //     "name": "OpenSea Creatures",
        //     "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
        //     "image": "external-link-url/image.png",
        //     "external_link": "external-link-url",
        //     "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
        //     "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
        // }

        Json.Item[] memory items_ = new Json.Item[](4);

        items_[0]._key = "name";
        items_[0]._type = Json.Type.STRING;
        items_[0]._string = NAME;

        items_[1]._key = "description";
        items_[1]._type = Json.Type.STRING;
        items_[1]._string = DESCRIPTION;

        items_[2]._key = "image";
        items_[2]._type = Json.Type.STRING;
        items_[2]._string = string(abi.encodePacked(content_base_, '/collection.jpg'));

        items_[3]._key = "external_link";
        items_[3]._type = Json.Type.STRING;
        items_[3]._string = collection.getMeta(0, 'externalLink')._string;

        // Encode JSON and create data uri
        string_ = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(bytes(json_.encode(items_, Json.Format.OBJECT)))
        ));

        return string_;

    }

}