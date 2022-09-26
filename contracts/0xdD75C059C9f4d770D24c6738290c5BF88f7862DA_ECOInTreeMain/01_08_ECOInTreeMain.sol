// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import 'erc721a/contracts/interfaces/IERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ECOInTreeMain is IERC721Receiver, ReentrancyGuard, Ownable {

    address public nft_address;
   
    event VoteNFT(uint256 miss_id, uint caller_nft_num);

    // @notice voting struct of every worldmiss
    mapping (uint256 => uint256) public voting;
    mapping (uint256 => address) public voted_ids;
    mapping (address => mapping (uint256 => uint256)) public checkpoints;

    constructor(address _nft_address) {
        nft_address = _nft_address;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external pure override returns(bytes4)
    {
        operator;
        from;
        tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
    }

    function voteNFT(uint256 miss_id) external nonReentrant returns(bool){
        require(miss_id >0 && miss_id <= 108, "out of bounds");
        IERC721AQueryable nft = IERC721AQueryable (nft_address);
        uint256[] memory nfts = nft.tokensOfOwner(msg.sender);
        uint256 nft_num = nfts.length;
        require(nft_num > 0, "No nfts");
        uint256 valid_votes = 0;
        for(uint256 i = 0; i < nft_num; i++){
            uint256 token_id = nfts[i];
            address sender_address = voted_ids[token_id];
            if(sender_address != address(0))
                continue;
                voted_ids[token_id] = msg.sender;
                valid_votes++;
        }
        voting[miss_id] = voting[miss_id] + valid_votes;
        uint256 user_miss_votes = checkpoints[msg.sender][miss_id];
        checkpoints[msg.sender][miss_id] = user_miss_votes + valid_votes;
        emit VoteNFT(miss_id, valid_votes);

        return true;
    }

    function select_votes_info(address user_addr, uint256 miss_total) public view returns(uint256[] memory, uint256[] memory){
        require(user_addr != address(0), "user_addr should not be 0x0.");
        require(miss_total >0 && miss_total <= 108, "out of bounds");
        mapping (uint256 => uint256) storage user_votes = checkpoints[user_addr];
        uint256[] memory user_miss_list = new uint256[](miss_total);
        uint256[] memory user_votes_list = new uint256[](miss_total);
        for(uint256 i = 0; i < miss_total; i++) {
            user_miss_list[uint256(i)] = i;
            user_votes_list[uint256(i)] = user_votes[i];
        }
        return (user_miss_list, user_votes_list);
    }

}