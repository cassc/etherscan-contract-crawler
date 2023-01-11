// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Base64} from "base64-sol/base64.sol";
import {IFileSystemAdapter} from "../fileSystemAdapters/interfaces/IFileSystemAdapter.sol";
import {IHTMLRenderer} from "./interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "./storage/HTMLRendererStorageV1.sol";
import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {VersionedContract} from "../VersionedContract.sol";

contract HTMLRenderer is
    IHTMLRenderer,
    HTMLRendererStorageV1,
    UUPS,
    Ownable2StepUpgradeable,
    VersionedContract
{
    address immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /// @notice set the owner of the contract
    function initilize(address owner) external initializer {
        _transferOwnership(owner);
    }

    /**
     * @notice Construct an html URI from the given script and imports.
     */
    function generateURI(
        FileType[] calldata imports,
        string calldata script
    ) public view returns (string memory) {
        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '<html><head><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>',
                            generateManyFileImports(imports),
                            script,
                            "</head><body><main></main></body></html>"
                        )
                    )
                )
            );
    }

    /// @notice Returns the HTML for the given imports
    function generateManyFileImports(
        FileType[] calldata _imports
    ) public view returns (string memory) {
        string memory imports = "";

        for (uint256 i = 0; i < _imports.length; i++) {
            imports = string.concat(imports, generateFileImport(_imports[i]));
        }

        return imports;
    }

    /// @notice Returns the HTML for a single import
    function generateFileImport(
        FileType calldata script
    ) public view returns (string memory) {
        if (script.fileType == FILE_TYPE_JAVASCRIPT_PLAINTEXT) {
            return
                string.concat(
                    "<script>",
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    "</script>"
                );
        } else if (script.fileType == FILE_TYPE_JAVASCRIPT_BASE64) {
            return
                string.concat(
                    '<script src="data:text/javascript;base64,',
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    '"></script>'
                );
        } else if (script.fileType == FILE_TYPE_JAVASCRIPT_GZIP) {
            return
                string.concat(
                    '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    '"></script>'
                );
        }

        revert("Invalid file type");
    }

    /// @notice check if the upgrade is valid
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        if (
            !ITokenFactory(factory).isValidUpgrade(
                _getImplementation(),
                newImpl
            )
        ) {
            revert ITokenFactory.InvalidUpgrade(newImpl);
        }
    }
}