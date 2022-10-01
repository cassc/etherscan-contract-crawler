pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library BondTransfer {
    using Address for address payable;

    function _transferInToken(
        address _token,
        uint256 _amount,
        address _sender
    ) internal {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function _transferOutToken(
        address _token,
        uint256 _amount,
        address recipient
    ) internal {
        IERC20(_token).transfer(recipient, _amount);
    }

    function _transferInPosiNFT(
        address _nonFungibleToken,
        uint256 _tokenID,
        address _sender
    ) internal {
        IERC721(_nonFungibleToken).safeTransferFrom(
            _sender,
            address(this),
            _tokenID
        );
    }

    function _transferInPosiNFTs(
        address _nonFungibleToken,
        uint256[] memory _posiNFTsID,
        address _sender
    ) internal {
        for (uint256 i = 0; i < _posiNFTsID.length; i++) {
            IERC721(_nonFungibleToken).safeTransferFrom(
                _sender,
                address(this),
                _posiNFTsID[i]
            );
        }
    }

    function _transferOutPosiNFT(
        address _nonFungibleToken,
        uint256[] storage _posiNFTsID,
        address _sender
    ) internal {
        for (uint256 i = 0; i < _posiNFTsID.length; i++) {
            IERC721(_nonFungibleToken).safeTransferFrom(
                address(this),
                _sender,
                _posiNFTsID[i]
            );
        }
    }

    function _transferOutEther(address _recipient, uint256 _amount) internal {
        payable(_recipient).sendValue(_amount);
    }
}