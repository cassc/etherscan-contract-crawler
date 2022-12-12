// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

library CompliancyChecker {

    bytes4 public constant _INTERFACE_ID_IERC165 = 0x01ffc9a7;
    bytes4 public constant _INTERFACE_ID_IERC721 = 0x80ac58cd;
    bytes4 public constant _INTERFACE_ID_IERC721ENUMERABLE = 0x780e9d63;
    bytes4 public constant _INTERFACE_ID_IERC1155 = 0xd9b67a26;

    function check165Compliancy(address _contract) public view returns (bool) {
        try IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC165) returns (bool supported)  {
            return supported;
        }  catch {
            return false;
        }
    }

    function check1155Compliancy(address _contract) public view returns (bool) {
        if (check165Compliancy(_contract) == false) {
            return false;
        }
        
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC1155)) {
            try IERC1155(_contract).balanceOf(0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a, 0) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
    }

    function check721Compliancy(address _contract) public view returns (bool) {
        if (check165Compliancy(_contract) == false) {
            return false;
        }

        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC721)) {
            try IERC721(_contract).balanceOf(0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
    }

    function check721EnumerableCompliancy(address _contract) public view returns (bool) {
        address owner_example;

        if (check721Compliancy(_contract) == false) {
            return false;
        }

        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_IERC721ENUMERABLE)) {
            try IERC721Enumerable(_contract).tokenByIndex(0) returns (uint256 _id_example)  {
                owner_example = IERC721Enumerable(_contract).ownerOf(_id_example);
            }  catch {
                return false;
            }

            try IERC721Enumerable(_contract).tokenOfOwnerByIndex(owner_example, 0) returns (uint256)  {
                return true;
            }  catch {
                return false;
            }
        } else {
            return false;
        }
    }
}