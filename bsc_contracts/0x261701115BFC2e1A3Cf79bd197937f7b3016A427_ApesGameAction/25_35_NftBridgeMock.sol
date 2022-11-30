// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/SafeMath.sol";

// interface for NFT contract, ERC721 and metadata, only funcs needed by NFTBridge
interface INFT {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    // we do not support NFT that charges transfer fees
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // impl by NFToken contract, mint an NFT with id and uri to user or burn
    function bridgeMint(
        address to,
        uint256 id,
        string memory uri
    ) external;

    function burn(uint256 id) external;
}

contract NftBridgeMock {
    using SafeMath for uint256;
    uint256 counter;
    event Sent(address sender, address srcNft, uint256 id, uint64 dstChid, address receiver);
    
    function sendTo(address _nft,uint256 _id,uint64 _dstChid,address _receiver) external payable{
        require(msg.sender == INFT(_nft).ownerOf(_id), "not token owner");
        INFT(_nft).tokenURI(_id);
        if (_id.mod(2) == 1) {
            // deposit
            INFT(_nft).transferFrom(msg.sender, address(this), _id);
            require(INFT(_nft).ownerOf(_id) == address(this), "transfer NFT failed");
        } else {
            // burn
            INFT(_nft).burn(_id);
        }
        emit Sent(msg.sender, _nft, _id, _dstChid, _receiver);
    }

    function totalFee(uint64 _dstChid,address _nft,uint256 _id) external view returns(uint256){
        string memory uri_ = INFT(_nft).tokenURI(_id);

        return bytes(uri_).length.mul(1e10).add(uint256(_dstChid));
    }
}