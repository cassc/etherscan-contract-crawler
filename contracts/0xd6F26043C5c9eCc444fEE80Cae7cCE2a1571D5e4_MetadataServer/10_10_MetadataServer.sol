// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/*_____________________________________________________________________________________________*/
//   ________  ________  _________  ________  ________  ________  ___  ________  _________     /
//  |\   __  \|\   __  \|\___   ___\\   ____\|\   ____\|\   __  \|\  \|\   __  \|\___   ___\   /
//  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \___|\ \  \___|\ \  \|\  \ \  \ \  \|\  \|___ \  \_|   /
//   \ \   __  \ \   _  _\   \ \  \ \ \_____  \ \  \    \ \   _  _\ \  \ \   ____\   \ \  \    /
//    \ \  \ \  \ \  \\  \|   \ \  \ \|____|\  \ \  \____\ \  \\  \\ \  \ \  \___|    \ \  \   /
//     \ \__\ \__\ \__\\ _\    \ \__\  ____\_\  \ \_______\ \__\\ _\\ \__\ \__\        \ \__\  /
//      \|__|\|__|\|__|\|__|    \|__| |\_________\|_______|\|__|\|__|\|__|\|__|         \|__|  /
//                                    \|_________|                                             /
/*_____________________________________________________________________________________________*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Libraries/StringsBytes32.sol";
import "./Libraries/MetadataBuilder.sol";
import "./Libraries/MetadataJSONKeys.sol";

contract MetadataServer is Ownable {
    using Strings for uint256;

    struct Inscription {
        bytes32 hash;
        string height;
        string difficulty;
        string confirmations;
        string time;
        string nTx;
        string nonce;
        string version;
    }

    struct ContractInfo {
        string title;
        string description;
        string contractURI;
    }

    //token id to inscription
    mapping(uint256 => Inscription) public inscriptions;
    ContractInfo public contractInfo;
    string[3] public endpoints = [
        "https://ordinals.com/content/385fe4f388e772c3abbe6b7a5881266b76f81962dba40db9091857f76352f9a0i0",
        "https://arweave.net/OzGrVu8uTk4eYdoOlyZQqPD-87qpAh80kZPLKFp-WEk",
        "https://artscript.vip/content/385fe4f388e772c3abbe6b7a5881266b76f81962dba40db9091857f76352f9a0i0.html"
    ];
    address public tokenContract;
    uint8 public activeEndpoint = 0;

    error NotAuthorized();
    error AlreadyInscripted(uint256 blockNumber);
    error InvalidBlockNumber(uint256 blockNumber);
    error InvalidEndpoint(uint8 endpoint);

    constructor(ContractInfo memory _contractInfo) {
        contractInfo = _contractInfo;
    }

    function addInscription(uint256 _blockNumber, Inscription memory _inscription) external {
        if (msg.sender != tokenContract) 
            revert NotAuthorized();

        if (!Strings.equal(_blockNumber.toString(), _inscription.height))
            revert InvalidBlockNumber(_blockNumber);

        if (inscriptions[_blockNumber].hash != 0x0)
            revert AlreadyInscripted(_blockNumber);

        inscriptions[_blockNumber] = _inscription;
    }

    function setContractInfo(ContractInfo memory _contractInfo) external onlyOwner {
        contractInfo = _contractInfo;
    }

    function setActiveEndpoint(uint8 _endpoint) external onlyOwner {
        if (_endpoint > 2) 
            revert InvalidEndpoint(_endpoint);

        activeEndpoint = _endpoint;
    }

    function setEndpoint(uint8 _endpoint, string memory _url) external onlyOwner {
        if (_endpoint > 2) 
            revert InvalidEndpoint(_endpoint);

        endpoints[_endpoint] = _url;
    }

    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }

    function serveMetadata(uint256 tokenId) external view returns (string memory) {
        Inscription memory _current = inscriptions[tokenId];

        string memory btcHash = StringsBytes32.toHexString(_current.hash);

        MetadataBuilder.JSONItem[]
            memory items = new MetadataBuilder.JSONItem[](7);
        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(
            contractInfo.title,
            " #",
            Strings.toString(tokenId)
        );
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            contractInfo.description,
            " \\n ",
            _generateQuery(endpoints[activeEndpoint], inscriptions[tokenId])
        );
        items[1].quote = true;

        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = string.concat(
            _generateQuery("https://artscript.vip/api/v1/image/385fe4f388e772c3abbe6b7a5881266b76f81962dba40db9091857f76352f9a0i0.html"
            , inscriptions[tokenId]),
            "&canvas_width=600&canvas_height=600&download=true" //review
        );
        items[2].quote = true;

        MetadataBuilder.JSONItem[]
            memory _endpoints = new MetadataBuilder.JSONItem[](3);
        _endpoints[0].key = "ordinals";
        _endpoints[0].value = endpoints[0];
        _endpoints[0].quote = true;

        _endpoints[1].key = "arweave";
        _endpoints[1].value = endpoints[1];
        _endpoints[1].quote = true;

        _endpoints[2].key = "web";
        _endpoints[2].value = endpoints[2];
        _endpoints[2].quote = true;

        items[3].key = MetadataJSONKeys.keyEndpoints;
        items[3].quote = false;
        items[3].value = MetadataBuilder.generateJSON(_endpoints);

        items[4].key = MetadataJSONKeys.keyAnimationURL;
        items[4].value = string.concat(
            _generateQuery(endpoints[activeEndpoint], inscriptions[tokenId]),
            "&canvas_width=600&canvas_height=600"
        );
        items[4].quote = true;

        items[5].key = "external_url";
        items[5].value = string.concat(
            _generateQuery(endpoints[2], inscriptions[tokenId]),
            "&canvas_width=600&canvas_height=600"
        );
        items[5].quote = true;

        MetadataBuilder.JSONItem[]
            memory properties = new MetadataBuilder.JSONItem[](8);
        properties[0].key = "hash";
        properties[0].value = btcHash;
        properties[0].quote = true;

        properties[1].key = "height";
        properties[1].value = _current.height;
        properties[1].quote = true;

        properties[2].key = "difficulty";
        properties[2].value = _current.difficulty;
        properties[2].quote = true;

        properties[3].key = "confirmations";
        properties[3].value = _current.confirmations;
        properties[3].quote = true;

        properties[4].key = "time";
        properties[4].value = _current.time;
        properties[4].quote = true;

        properties[5].key = "nTx";
        properties[5].value = _current.nTx;
        properties[5].quote = true;

        properties[6].key = "nonce";
        properties[6].value = _current.nonce;
        properties[6].quote = true;

        properties[7].key = "version";
        properties[7].value = _current.version;
        properties[7].quote = true;


        items[6].key = MetadataJSONKeys.keyAttributes;
        items[6].quote = false;
        items[6].value = MetadataBuilder.generateJSON(properties);

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function _generateQuery(string memory  _endpoint, Inscription memory _inscription)
        internal
        pure
        returns (string memory _query)
    {
        return
            string.concat(
                _endpoint,
                "?hash=",
                StringsBytes32.toHexString(_inscription.hash),
                "&height=",
                _inscription.height,
                "&difficulty=",
                _inscription.difficulty,
                "&confirmations=",
                _inscription.confirmations,
                "&time=",
                _inscription.time,
                "&nTx=",
                _inscription.nTx,
                "&nonce=",
                _inscription.nonce,
                "&version=",
                _inscription.version
            );
    }
}