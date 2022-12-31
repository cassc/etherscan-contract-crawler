// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**          

      `7MM"""Mq.                     mm           
        MM   `MM.                    MM           
        MM   ,M9  ,pW"Wq.   ,pW"Wq.mmMMmm ,pP"Ybd 
        MMmmdM9  6W'   `Wb 6W'   `Wb MM   8I   `" 
        MM  YM.  8M     M8 8M     M8 MM   `YMMMa. 
        MM   `Mb.YA.   ,A9 YA.   ,A9 MM   L.   I8 
      .JMML. .JMM.`Ybmd9'   `Ybmd9'  `MbmoM9mmmP' 

      E D I T I O N S
                
      https://roots.samking.photo/editions

*/

import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {REAL_ID_MULTIPLIER} from "./Constants.sol";
import {IMetadata} from "./IMetadata.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Roots Editions Metadata
 * @notice A simple metadata contract that uses a base URI per ID
 */
contract Metadata is IMetadata, Owned {
    using Strings for uint256;

    /// @notice The base URI strings per ID
    mapping(uint256 => string) public baseURIs;

    constructor(address owner) Owned(owner) {}

    /**
     * @notice
     * Admin function to set a base URI for a given ID
     *
     * @param id The artwork id
     * @param baseURI The base URI to use
     */
    function setBaseURI(uint256 id, string memory baseURI) external onlyOwner {
        baseURIs[id] = baseURI;
    }

    /**
     * @notice
     * ERC-721-like token URI function to return the correct baseURI
     *
     * @dev
     * Reverts if there is no base URI set for the token
     *
     * @param realId The real token ID to render metadata for
     */
    function tokenURI(uint256 realId) public view override returns (string memory) {
        uint256 id = realId / REAL_ID_MULTIPLIER;

        string memory baseURI = baseURIs[id];
        require(bytes(baseURI).length > 0, "NO_BASE_URI_SET");

        return string(abi.encodePacked(baseURI, "/", realId.toString()));
    }
}