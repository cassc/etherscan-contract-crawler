// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
                                                 :::
                                             :: :::.
                       \/,                    .:::::
           \),          \`-._                 :::888
           /\            \   `-.             ::88888
          /  \            | .(                ::88
         /,.  \           ; ( `              .:8888
            ), \         / ;``               :::888
           /_   \     __/_(_                  :88
             `. ,`..-'      `-._    \  /      :8
               )__ `.           `._ .\/.
              /   `. `             `-._______m         _,
  ,-=====-.-;'                 ,  ___________/ _,-_,'"`/__,-.
 C   =--   ;                   `.`._    V V V       -=-'"#==-._
:,  \     ,|      UuUu _,......__   `-.__Ʌ_Ʌ_ -. ._ ,--._ ",`` `-
||  |`---' :    uUuUu,'          `'--...____/   `" `".   `
|`  :       \   UuUu:
:  /         \   UuUu`-._
 \(_          `._  uUuUu `-.
 (_3             `._  uUu   `._
                    ``-._      `.
                         `-._    `.
                             `.    \
                               )   ;
                              /   /
               `.        |\ ,'   /
                 ",_Ʌ_/\-| `   ,'
                   `--..,_|_,-'\
                          |     \
                          |      \__
                          |__

        wtf trogdor? https://www.youtube.com/watch?v=90X5NJleYJQ
        ascii sauce: https://github.com/asiansteev/trogdor
*/

contract Burninator {
    mapping(address => mapping(uint256 => uint256)) public offers;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public donations;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    error AlreadyBurned();
    error DonationRequired();
    error InvalidOffer();
    error NoDonationToWithdraw();
    error NotTokenOwner();
    error TransferFailed();

    event Burninated(address indexed tokenAddress, uint256 indexed tokenId, address indexed acceptor);
    event Donation(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);
    event Withdrawal(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);

    /*
        Donate ether to encourage the burnination of a token
    */
    function donate(address tokenAddress, uint256 tokenId) external payable {
        if (msg.value == 0) revert DonationRequired();
        if (IERC721(tokenAddress).ownerOf(tokenId) == BURN_ADDRESS) revert AlreadyBurned();

        offers[tokenAddress][tokenId] += msg.value;
        donations[tokenAddress][tokenId][msg.sender] += msg.value;

        emit Donation(tokenAddress, tokenId, msg.sender, msg.value);
    }

    /*
        If you change your mind, withdraw before offer is accepted.
    */
    function withdraw(address tokenAddress, uint256 tokenId) external {
        if (donations[tokenAddress][tokenId][msg.sender] == 0) revert NoDonationToWithdraw();

        uint256 donation = donations[tokenAddress][tokenId][msg.sender];
        donations[tokenAddress][tokenId][msg.sender] = 0;
        offers[tokenAddress][tokenId] -= donation;

        (bool success, ) = payable(msg.sender).call{value: donation}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(tokenAddress, tokenId, msg.sender, donation);
    }

    /*
        To accept the offer, first call approve or setApprovalForAll on your NFT's contract.

        Set minimumAmount to value of current offer to prevent frontrunning withdrawals.
    */
    function burninate(address tokenAddress, uint256 tokenId, uint256 minimumAmount) external {
        if (IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (offers[tokenAddress][tokenId] < minimumAmount) revert InvalidOffer();
        if (offers[tokenAddress][tokenId] == 0) revert InvalidOffer();

        uint256 amount = offers[tokenAddress][tokenId];
        offers[tokenAddress][tokenId] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        IERC721(tokenAddress).transferFrom(msg.sender, BURN_ADDRESS, tokenId);

        emit Burninated(tokenAddress, tokenId, msg.sender);
    }
}