// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTStorage is Ownable, IERC721Receiver {
    address public immutable acceptedNFT;
    address public immutable claimableNFT;

    mapping(uint256 => bool) public claimedNFT;

    constructor(address _acceptedNFT, address _claimableNFT) {
        acceptedNFT = _acceptedNFT;
        claimableNFT = _claimableNFT;
    }

    function checkClaimed(uint256[] memory _tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory status = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            status[i] = claimedNFT[_tokenIds[i]];
        }
        return status;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function claimableNFTBalance() public view returns (uint256) {
        return IERC721(claimableNFT).balanceOf(address(this));
    }

    function withdrawNFT(uint256[] memory _tokenIds) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(claimableNFT).transferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }
    }

    function claimNFT(
        uint256 _acceptedTokenId,
        uint256[] memory _claimableTokenId
    ) public {
        require(
            IERC721(acceptedNFT).ownerOf(_acceptedTokenId) == msg.sender,
            "You do not own this NFT"
        );
        require(
            claimedNFT[_acceptedTokenId] == false,
            "This NFT has already been claimed"
        );
        if (1 <= _acceptedTokenId && _acceptedTokenId <= 154) {
            // send 2 claimable NFTs
            IERC721(claimableNFT).transferFrom(
                address(this),
                msg.sender,
                _claimableTokenId[0]
            );
            IERC721(claimableNFT).transferFrom(
                address(this),
                msg.sender,
                _claimableTokenId[1]
            );
        } else if (155 <= _acceptedTokenId && _acceptedTokenId <= 200) {
            // send 5 claimable NFTs
            for (uint256 i = 0; i < 5; i++) {
                IERC721(claimableNFT).transferFrom(
                    address(this),
                    msg.sender,
                    _claimableTokenId[i]
                );
            }
        }
        claimedNFT[_acceptedTokenId] = true;
    }
}