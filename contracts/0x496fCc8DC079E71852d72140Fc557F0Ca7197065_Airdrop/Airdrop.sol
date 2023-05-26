/**
 *Submitted for verification at Etherscan.io on 2023-05-20
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
    function tokenOfOwnerByIndex(address account, uint256 tokenIndex) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Airdrop {
    // Airdrop to Pudgy Penguins, Lil Pudgys, and Pudge Rods holders
    IERC721 constant public PudgyPenguins = IERC721(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8);
    IERC721 constant public LilPudgys = IERC721(0x524cAB2ec69124574082676e6F654a18df49A048);
    IERC721 constant public PudgyPresent = IERC721(0x062E691c2054dE82F28008a8CCC6d7A1c8ce060D);
    // Airdrop to PEPE, LADYS holders
    IERC20 constant public PEPE = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);
    IERC20 constant public LADYS = IERC20(0x12970E6868f88f6557B76120662c1B3E50A646bf);
    // $PUFFY
    IERC20 public PUFFY;
    uint256 constant public amountPerAddr = 75206966752240920000000000;
    uint256 constant public claimDeadline = 1685577600; // Ends at June 1, 2023 00:00:00 UTC

    mapping (address => bool) public hasClaimed;
    address immutable public owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setPuffy(address addr) external onlyOwner {
        require(PUFFY == IERC20(address(0)));
        PUFFY = IERC20(addr);
    }

    function isEligible(address addr) public view returns (bool _isEligible) {
        if (!hasClaimed[addr]) {
            if (
                PEPE.balanceOf(addr) > 0 ||
                LADYS.balanceOf(addr) > 0 ||
                PudgyPenguins.balanceOf(addr) > 0 ||
                LilPudgys.balanceOf(addr) > 0 ||
                PudgyPresent.balanceOf(addr) > 0
            ) {
                return true;
            }
        } else {
            return false;
        }
    }

    function claim() external {
        require(block.timestamp <= claimDeadline, "claim period has ended");

        bool _isEligible = isEligible(msg.sender);

        if (_isEligible) {
            hasClaimed[msg.sender] = true;
            PUFFY.transfer(msg.sender, amountPerAddr);
        }
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > claimDeadline);
        uint256 balance = PUFFY.balanceOf(address(this));
        PUFFY.transfer(owner, balance);
    }
}