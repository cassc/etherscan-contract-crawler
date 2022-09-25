// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract EternalProfilePicture {
    uint256 listingPrice = 0.0075 ether;

    mapping(address => ProfilePicture) private addressToProfilePicture;

    struct ProfilePicture {
        uint256 tokenId;
        IERC721 nftContract;
    }

    event ProfilePictureUpdated(uint256 indexed tokenId, IERC721 nftContract);

    function getProfilePicture(address _owner)
        public
        view
        returns (IERC721, uint256)
    {
        return (
            addressToProfilePicture[_owner].nftContract,
            addressToProfilePicture[_owner].tokenId
        );
    }

    function depositProfilePicture(uint256 _tokenId, IERC721 _nftContract)
        public
        payable
    {
        require(
            msg.value == listingPrice,
            'Please add 0.0075 BNB to your transaction.'
        );

        address logic = 0x9311000Ad2b915b6bf669C31F2611Af637c22Ee7;
        payable(logic).transfer(msg.value);

        _nftContract.transferFrom(msg.sender, address(this), _tokenId);

        addressToProfilePicture[msg.sender].tokenId = _tokenId;
        addressToProfilePicture[msg.sender].nftContract = _nftContract;
    }

    function withdrawProfilePicture() public {
        addressToProfilePicture[msg.sender].nftContract.transferFrom(
            address(this),
            msg.sender,
            addressToProfilePicture[msg.sender].tokenId
        );

        addressToProfilePicture[msg.sender].tokenId = 0;
        addressToProfilePicture[msg.sender].nftContract = IERC721(address(0));
    }
}