// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___                    ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\                  /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\                 \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\                 \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\            _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\          /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/          \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~            \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\                 \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\                 \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/                  \__\/         \__\/                   \__\/
//
//
//   OpenERC165
//   (supports)
//       |
//       ———————————————————————
//       |        |            |
//       |   OpenERC173    OpenCloner
//       |    (ownable)        |
//       |        |            |
//       ———————————————————————
//       |
// OpenNFTsFactoryV3 —— IOpenNFTsFactoryV3
//
pragma solidity ^0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/OpenCloner/OpenCloner.sol";

import "OpenNFTs/contracts/interfaces/IERC165.sol";
import "OpenNFTs/contracts/interfaces/IOpenCloneable.sol";
import "OpenNFTs/contracts/interfaces/IOpenRegistry.sol";
import "../interfaces/IOpenNFTsFactoryV3.sol";
import "../interfaces/IOpenNFTsV4.sol";
import "../interfaces/IOpenAutoMarket.sol";

/// @title OpenNFTsFactoryV3 smartcontract
/// @notice Factory for NFTs contracts: ERC721 or ERC1155
/// @notice Create new NFTs Collections smartcontracts by cloning templates
contract OpenNFTsFactoryV3 is IOpenNFTsFactoryV3, OpenERC173, OpenCloner {
    /// @notice Named Templates

    mapping(string => uint256) private _numTemplates;
    address[] public templates;

    address public nftsResolver;

    address private _treasury;
    uint96 private _treasuryFee;

    constructor(
        address initialOwner_,
        address treasury_,
        uint96 treasuryFee_
    ) {
        OpenERC173._transferOwnership(initialOwner_);
        setTreasury(treasury_, treasuryFee_);
    }

    /// @notice clone template
    /// @param name name of Clone collection
    /// @param symbol symbol of Clone collection
    /// @return clone_ Address of Clone collection
    function clone(
        string memory name,
        string memory symbol,
        string memory templateName,
        bytes memory params
    ) external override(IOpenNFTsFactoryV3) returns (address clone_) {
        clone_ = clone(template(templateName));

        IOpenCloneable(clone_).initialize(name, symbol, msg.sender, abi.encode(params, _treasury, _treasuryFee));

        IOpenRegistry(nftsResolver).addAddress(clone_);

        emit Clone(templateName, clone_, name, symbol);
    }

    function countTemplates() external view override(IOpenNFTsFactoryV3) returns (uint256 count) {
        count = templates.length;
    }

    function setTreasury(address treasury_, uint96 treasuryFee_) public override(IOpenNFTsFactoryV3) onlyOwner {
        _treasury = treasury_;
        _treasuryFee = treasuryFee_;
    }

    function setResolver(address resolver_) public override(IOpenNFTsFactoryV3) onlyOwner {
        nftsResolver = resolver_;

        emit SetResolver(nftsResolver);
    }

    /// @notice Set Template by Name
    /// @param templateName_ Name of the template
    /// @param template_ Address of the template
    function setTemplate(string memory templateName_, address template_) public override(IOpenNFTsFactoryV3) onlyOwner {
        require(IERC165(template_).supportsInterface(type(IOpenCloneable).interfaceId), "Not OpenCloneable");
        require(IOpenCloneable(template_).initialized(), "Not initialized");
        require(template_.code.length != 45, "Clone not valid template");

        uint256 num = _numTemplates[templateName_];
        if (num >= 1) {
            templates[num - 1] = template_;
        } else {
            templates.push(template_);
            num = templates.length;

            _numTemplates[templateName_] = num;
        }

        IOpenRegistry(nftsResolver).addAddress(template_);

        emit SetTemplate(templateName_, template_, num);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC173, OpenCloner) returns (bool) {
        return interfaceId == type(IOpenNFTsFactoryV3).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Get Template
    /// @param  templateName : template name
    /// @return template_ : template address
    function template(string memory templateName) public view override(IOpenNFTsFactoryV3) returns (address template_) {
        uint256 num = _numTemplates[templateName];
        require(num >= 1, "Invalid Template");

        template_ = templates[num - 1];
        require(template_ != address(0), "No Template");
    }
}