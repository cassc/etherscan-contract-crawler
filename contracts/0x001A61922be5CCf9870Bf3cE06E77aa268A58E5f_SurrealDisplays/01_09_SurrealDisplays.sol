// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../lib/ERC721.sol";
import "../lib/Owned.sol";
import "../lib/StringsMinified.sol";
import "../lib/Base64.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   ███████╗ ██╗   ██╗ ██████╗  ██████╗  ███████╗  █████╗  ██╗        //
//   ██╔════╝ ██║   ██║ ██╔══██╗ ██╔══██╗ ██╔════╝ ██╔══██╗ ██║        //
//   ███████╗ ██║   ██║ ██████╔╝ ██████╔╝ █████╗   ███████║ ██║        //
//   ╚════██║ ██║   ██║ ██╔══██╗ ██╔══██╗ ██╔══╝   ██╔══██║ ██║        //
//   ███████║ ╚██████╔╝ ██║  ██║ ██║  ██║ ███████╗ ██║  ██║ ███████╗   //
//   ╚══════╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚══════╝   //
//                                                                     //
//                              surr.app                               //
//                   A magic bag for your web3 loot                    //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

contract SurrealDisplays is DefaultOperatorFilterer, ERC721, Owned {

    using Strings for uint256;

    //// UNCHANGEABLE ////

    uint256[10] _displayTotalSupply;

    //// PRIVATE STORAGE ////

    string private _baseURI;
    string private _imgBaseURI;
    bool private _offchainMetadata;
    string[10] private _displayTypes;
    mapping(bytes32 => bool) private _operatorHashUsed;

    //// PUBLIC STORAGE ////

    uint256 public maxSupply = 1111;
    address public operator;
    uint256 public totalMinted;
    uint256[10] public totalMintedByType;
    mapping(uint256 => uint256) public idToDisplayType;
    mapping(address => uint256) public mintedTo;

    //// CONSTRUCTOR ////
    constructor(string memory imgBaseURI, address operator_, address owner)
        DefaultOperatorFilterer()
        ERC721("Displays by Surreal", "DSPM")
        Owned(owner) {

        _imgBaseURI = imgBaseURI;
        operator = operator_;

        _displayTotalSupply[0] = 99;
        _displayTotalSupply[1] = 152;
        _displayTotalSupply[2] = 42;
        _displayTotalSupply[3] = 88;
        _displayTotalSupply[4] = 142;
        _displayTotalSupply[5] = 111;
        _displayTotalSupply[6] = 77;
        _displayTotalSupply[7] = 168;
        _displayTotalSupply[8] = 90;
        _displayTotalSupply[9] = 142;

        _displayTypes[0] = "DSP";
        _displayTypes[1] = "JX";
        _displayTypes[2] = "QAS";
        _displayTypes[3] = "OX";
        _displayTypes[4] = "VCR";
        _displayTypes[5] = "XB";
        _displayTypes[6] = "LLP";
        _displayTypes[7] = "KD";
        _displayTypes[8] = "SMP";
        _displayTypes[9] = "TT";
    }

    //// MINTER ////

    function mint(
        address to,
        uint256 displayType,
        bytes32 operatorMessageHash,
        bytes memory operatorSignature)
    payable public {

        require(displayType < _displayTotalSupply.length, "SurrealDisplays: Invalid displayType");
        require(totalMintedByType[displayType] < _displayTotalSupply[displayType], "SurrealDisplays: Exceeds total supply for displayType");

        if(msg.sender != owner) {
            require(mintedTo[to] == 0, "SurrealDisplays: Not eligible for mint");

            if(msg.value == 0) {
                verifyFreeMintSignature(operatorMessageHash, operatorSignature);
                _operatorHashUsed[operatorMessageHash] = true;
            } else {
                require(msg.value == 100000000000000000, "SurrealDisplays: Not enough Eth provided for the mint");
            }
        }

        uint256 totalMinted_ = totalMinted + 1;

        totalMintedByType[displayType]++;
        idToDisplayType[totalMinted_] = displayType;
        mintedTo[to] = totalMinted_;
        totalMinted = totalMinted_;

        _mint(to, totalMinted_);
    }

    //// URI GETTER ////

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id > 0 && id <= totalMinted, "SurrealDisplays: Nonexistent Display");

        if(_offchainMetadata) return string.concat(_baseURI, id.toString());

        uint256 _type = idToDisplayType[id];
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "', _displayTypes[_type], '-', id.toString(),
            '", "external_url": "https://www.surr.app"',
            ', "description": "This module displays key parameters on your journey, such as what loot is in your bag. Also, it gives you early access to the iOS beta and unlocks special features in the app."',
            ', "image": "', _imgBaseURI, _displayTypes[_type], '.png"',
            ', "attributes": [{"trait_type": "Type", "value": "', _displayTypes[_type], '"}, {"trait_type": "V", "value": "1"}]',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    //// OWNER ONLY ////

    function withdraw() onlyOwner external {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent, "SurrealDisplays: Withdrawal error");
    }

    function updateURI(
        string memory baseURI,
        string memory imgBaseURI,
        bool offchainMetadata
    ) onlyOwner external {
        _offchainMetadata = offchainMetadata;
        _baseURI = baseURI;
        _imgBaseURI = imgBaseURI;
    }

    function updateOperator(address operator_) onlyOwner external {
        operator = operator_;
    }

    //// PRIVATE ////

    function verifyFreeMintSignature(bytes32 hash, bytes memory signature) private view {
        require(signature.length == 65, "SurrealDisplays: Invalid signature - invalid signature length");

        // Signature reentrancy check
        require(_operatorHashUsed[hash] == false, "SurrealDisplays: Signature verification fail - hash has been used");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "SurrealDisplays: Invalid signature - invalid S parameter");
        require(v == 27 || v == 28, "SurrealDisplays: Invalid signature - invalid V parameter");

        require(ecrecover(hash, v, r, s) == operator, "SurrealDisplays: Invalid signature - signer is not Operator");
    }
}