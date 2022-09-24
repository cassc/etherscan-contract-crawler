// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

contract Portugal is AdminControl, IIdentityVerifier, ICreatorExtensionTokenURI {
    using Strings for uint256;

    address _marketplace;
    uint _listingId;
    address _creator;
    uint _tokenId;
    string _animationURI;
    string _imageURI;

    uint public _unlockTime;
    address public _bidder;
    uint public _bidderIndex;

    struct Customizations {
      uint palette;
      uint style;
      uint spread;
      uint inverse;
    }

    Customizations public _customization;

    function configure(address marketplace, uint listingId, Customizations calldata customization, string memory animationURI, string memory imageURI) public adminRequired {
        _marketplace = marketplace;
        _listingId = listingId;
        _customization = customization;
        _animationURI = animationURI;
        _imageURI = imageURI;
    }
    
    function mint(address creator) public adminRequired {
      _creator = creator;
      _tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override returns (bool) {
        require(msg.sender == _marketplace && listingId == _listingId, "Can only be verified by the marketplace");
        require(block.timestamp > _unlockTime, "Bidding is locked.");

        _unlockTime = block.timestamp + 300;
        _bidder = identity;
        if (_bidderIndex > 3) {
          _bidderIndex = 1;
        } else {
          _bidderIndex++;
        }

        return true;
    }

    function verifyView(uint40, address, address, uint256, uint24, uint256, address, bytes calldata) external view returns (bool) {
        return block.timestamp > _unlockTime;
    }

    function customize(uint input) public {
      require(msg.sender == _bidder, "Must be current bidder");
      require(block.timestamp < _unlockTime, "Must customize within time.");

      if (_bidderIndex == 1) {
        _customization.palette = input;
      } else if (_bidderIndex == 2) {
        _customization.style = input;
      } else if (_bidderIndex == 3) {
        _customization.spread = input;
      } else {
        _customization.inverse = input;
      }

      // Unlock
      _unlockTime = block.timestamp-1;
    }


    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && tokenId == _tokenId, "Invalid token");
        return string(
          abi.encodePacked('data:application/json;utf8,',
            '{"name":"memories of portugal","created_by":"yungwknd","description":"good memories",',
            '"animation":"',
            string(abi.encodePacked(_animationURI, "style=", _customization.style.toString(), "&spread=", _customization.spread.toString(), "&inverse=", _customization.inverse.toString(), "&palette=", _customization.palette.toString())),
            '","animation_url":"',
            string(abi.encodePacked(_animationURI, "style=", _customization.style.toString(), "&spread=", _customization.spread.toString(), "&inverse=", _customization.inverse.toString(), "&palette=", _customization.palette.toString())),
            '","image":"',
            _imageURI,
            '","image_url":"',
             _imageURI,
            '"}'
          )
        );
    }
}