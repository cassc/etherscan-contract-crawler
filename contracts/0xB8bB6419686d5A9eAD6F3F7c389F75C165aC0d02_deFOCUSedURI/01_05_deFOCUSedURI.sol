// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title deFOCUSed URI Contract
/// @author Matto
/// @notice This contract does the heavy lifting in creating the token metadata and image.
/// @dev The extra functions to retrieve/preview the SVG and return legible URI made main contract too large.
/// @custom:security-contact [email protected]
interface i_deFOCUSedTraits {
	function calculateTraitsArray(uint16[32] memory _hV, uint256 _tokenEntropy)
		external
		view
		returns (uint16[25] memory);

  function calculateTraitsJSON(uint16[25] memory _traitsArray)
  	external
		view
		returns (string memory);
}

interface i_deFOCUSedSVG {
	function assembleSVG(uint16[25] memory _traitsArray, string memory _metaPart, string memory traitsJSON)
		external
		view
		returns (string memory);
}

contract deFOCUSedURI is Ownable {
  using Strings for string;

  address public traitsContract;
  address public svgContract;
  bool public cruncherContractsLocked = false;

  function createHashValPairs(bytes32 _abEntropy)
    public
    pure
    returns (uint16[32] memory)
  {
    uint16[32] memory hV;
    for (uint i = 0; i < 32; i++) {
        hV[i] = uint16(uint(bytes32(bytes1(_abEntropy)) >> 248));
        _abEntropy = _abEntropy << 8;
    }
    return hV;
  }

  function buildMetaPart(uint256 _tokenId, string memory _description, address _artistAddy, uint256 _royaltyBps, string memory _collection, string memory _website, string memory _externalURL)
    external
    view
    virtual
    returns (string memory)
  {
    string memory metaPart = string(abi.encodePacked('{"name":"deFOCUSed #',Strings.toString(_tokenId),'","artist":"Matto","description":"',
      _description,'","royaltyInfo":{"artistAddress":"',Strings.toHexString(uint160(_artistAddy), 20),'","royaltyFeeByID":',Strings.toString(_royaltyBps/100),'},"collection_name":"',
      _collection,'","website":"',_website,'","external_url":"',_externalURL,'","script_type":"Solidity","image_type":"Generative SVG"'));
    return metaPart;
  }

  function buildContractURI(string memory _description, string memory _externalURL, uint256 _royaltyBps, address _artistAddy, string memory _svg)
    external
    view
    virtual
    returns (string memory)
  {
    string memory b64SVG = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(_svg))));
    string memory contractURI = string(abi.encodePacked('{"name":"deFOCUSed","description":"',_description,'","image":"', b64SVG,
      '","external_link":"',_externalURL,'","seller_fee_basis_points":',Strings.toString(_royaltyBps),',"fee_recipient":"',Strings.toHexString(uint160(_artistAddy), 20),'"}'));
    string memory base64ContractURI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(contractURI))));
    return base64ContractURI;
  }

  function buildTokenURI(string memory _metaP, uint256 _tokenEntropy, bytes32 _abEntropy, bool _svgMode)
    external
    view
    virtual
    returns (string memory)
  {
    uint16[32] memory hV = createHashValPairs(_abEntropy);
    uint16[25] memory traitsArray = i_deFOCUSedTraits(traitsContract).calculateTraitsArray(hV, _tokenEntropy);
    string memory traitsJSON = i_deFOCUSedTraits(traitsContract).calculateTraitsJSON(traitsArray);
    string memory svg = i_deFOCUSedSVG(svgContract).assembleSVG(traitsArray, _metaP, traitsJSON);
    if (_svgMode) {
      return svg;
    } else {
      string memory b64SVG = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(svg))));
      string memory legibleURI = string(abi.encodePacked(_metaP,',"image":"',b64SVG,'",',traitsJSON,'}'));
      string memory base64URI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(legibleURI))));
      return base64URI;
    }
  }  

  function updateSVGContract(address _svgContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    svgContract = _svgContract;
  }

	function updateTraitsContract(address _traitsContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    traitsContract = _traitsContract;
  }

  function DANGER_LockCruncherContracts()
    external
    payable
    onlyOwner
  {
    cruncherContractsLocked = true;
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}