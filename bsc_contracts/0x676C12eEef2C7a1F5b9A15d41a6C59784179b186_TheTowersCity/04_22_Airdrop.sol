//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop {
    address private owner;
    IERC20 private token;
    bytes32 public merkleRoot;
    mapping(address => bool) public redeemed;
    uint256 public timeout;

    event Redeem(address indexed account, uint256 amount);

    constructor(IERC20 _token, bytes32 _merkleRoot, uint256 _timeout, address _owner) {
        owner = _owner;
        token = _token;
        merkleRoot = _merkleRoot;
        timeout = _timeout;
    }

    function redeem(address _user, uint256 _path, bytes32[] memory _witnesses, uint256 _amount) public {
        require(!redeemed[_user], "Airdrop: already redeemed");
        require(block.timestamp < timeout, "Airdrop: timeout");

        uint256 path = _path;
        bytes32[] memory witnesses = _witnesses;

        bytes32 node = keccak256(abi.encodePacked(uint8(0x00), _user, _amount));
        for (uint16 i = 0; i < witnesses.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(
                    abi.encodePacked(uint8(0x01), witnesses[i], node)
                );
            } else {
                node = keccak256(
                    abi.encodePacked(uint8(0x01), node, witnesses[i])
                );
            }
            path /= 2;
        }

        require(node == merkleRoot, "Airdrop: address not in the whitelist or wrong proof provided");

        redeemed[_user] = true;
        token.transfer(_user, _amount);
        emit Redeem(_user, _amount);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function cancelAirdrop() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Airdrop: only owner can perform this transaction");
        _;
    }
}