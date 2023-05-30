// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

//    __  ______  ____
//   / / / / __ \/  _/
//  / / / / /_/ // /
// / /_/ / _, _// /
// \____/_/ |_/___/

/// @author shawnprice.eth
/// @title URI Handler

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract URIHandler {
    using Strings for uint256;

    function generateURI(
        string memory _name,
        string memory _createdBy,
        string memory _description,
        string memory _aperture,
        uint256 _imageBytes,
        string memory _imageHash,
        uint256 _height,
        string memory _uri,
        uint256 _width,
        uint256 _iso,
        string memory _lensModel,
        string memory _shutterSpeed,
        string memory _camera,
        string memory _format,
        string memory _license,
        uint256 _createdAt
    ) internal pure returns (string memory) {
        bytes memory nameAndDescription = abi.encodePacked(
            '"name":"',
            _name,
            '","created_by":"',
            _createdBy,
            '","description":"',
            _description,
            '"'
        );

        bytes memory attributes = abi.encodePacked(
            '"attributes":[{',
            '"trait_type":"Aperture",',
            '"value":"',
            _aperture,
            '"},{'
            '"trait_type":"Shutter Speed",',
            '"value":"',
            _shutterSpeed,
            '"},{'
            '"trait_type":"ISO",',
            '"value":"',
            _iso.toString(),
            '"},{'
            '"trait_type":"Camera",',
            '"value":"',
            _camera,
            '"},{'
            '"trait_type":"License",',
            '"value":"',
            _license,
            '"},{'
            '"trait_type":"Lens",',
            '"value":"',
            _lensModel,
            '"}]'
        );

        bytes memory imageURIDetails = abi.encodePacked(
            '"image":"',
            _uri,
            '",'
            '"image_url":"',
            _uri,
            '"'
        );

        bytes memory imageDetails = abi.encodePacked(
            '"image_details":{',
            '"bytes":',
            _imageBytes.toString(),
            ',"format":"',
            _format,
            '","sha256":"',
            _imageHash,
            '","created_at":',
            _createdAt.toString(),
            ',"width":',
            _width.toString(),
            ',"height":',
            _height.toString(),
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                nameAndDescription,
                                ",",
                                imageURIDetails,
                                ",",
                                attributes,
                                ",",
                                imageDetails,
                                "}"
                            )
                        )
                    )
                )
            );
    }
}