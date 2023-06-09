//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CryptoMonksV2
/// @notice 1155 for alternative to sequential token ids
contract CryptoMonksV2 is ERC1155, Ownable, ReentrancyGuard {
    /**
    * @dev Total MONKS
    **/
    uint256 public constant MONKS = 500;
    
    /**
    * @dev Migration Bridge Contract
    **/
    address public BRIDGE;

    string public BASEURI;

    mapping(uint256 => uint256) private TOKENIDS;

    /**
    * @dev Security to prevent resizing collection
    **/
    uint8 public lockseed = 0;

    uint256 public migrated;
    string public name;
    string public symbol;

    constructor(
         address _bridge
    ) ERC1155("") {
         BRIDGE = _bridge;
        name = "Monks of Crypto v2";
        symbol = "CRYPTOMONKS";
    }

    /**
    * @dev minting possible only by the migration bridge
    */
    function mintMachine(address _owner, uint256 _tokenId) external  returns (uint256) {
        require(msg.sender == BRIDGE, "Not Bridge");
        require(_tokenId > 0 && _tokenId <= MONKS, "Token out of bound");
        require(migrated <= MONKS, "Max supply reached");
        require(TOKENIDS[_tokenId] == 0, "Exists");
        TOKENIDS[_tokenId] = 1;
        migrated++;
        _mint(_owner, _tokenId, 1, "");
        return(1);
    }

    /**
    * @dev seed
    */
    function seed(address[] calldata _address,  uint256[] calldata _ids) external onlyOwner {
        require(lockseed < 2, "Locked");
        for (uint256 i = 0; i < _address.length; i++) {
            TOKENIDS[_ids[i]] = 1;
            migrated++;
            lockseed++;
            _mint(_address[i], _ids[i], 1, "");
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        BASEURI = _baseURI;
    }
    
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    function contractURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
     function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string[2] memory parts;
       
        parts[0] = BASEURI;

        parts[1] = toString(_tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        
        return output;
     }
     

}