/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "../interface/IErcForgeERC721Mintable.sol";
import "../interface/IErcForgeERC1155Mintable.sol";

contract ErcForgeMinter {
    address owner;

    uint256 public fee = 700000000000000 wei;
    uint256 public referrerReward = 70000000000000 wei;

    uint256 public totalReferrerFunds;
    mapping(address => uint256) private _referrerFunds;

    bool public isPaused = false;

    error NotOwner();
    error Paused();
    error NotEnoughFunds();

    event ContractCreated(address contractAddress);

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) public {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        owner = _owner;
    }

    function setFee(uint256 _fee) public {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        fee = _fee;
    }

    function setReferrerReward(uint256 _referrerReward) public {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        referrerReward = _referrerReward;
    }

    function setIsPaused(bool _isPaused) public {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        isPaused = _isPaused;
    }

    function _beforeMint(address referrer) private {
        if (isPaused) {
            revert Paused();
        }
        if (msg.value < fee) {
            revert NotEnoughFunds();
        }

        if (referrer != address(0)) {
            _referrerFunds[referrer] += referrerReward;
            totalReferrerFunds += referrerReward;
        }
    }

    function mintERC721(
        address to,
        address contractAddress,
        address referrer
    ) external payable {
        _beforeMint(referrer);

        IErcForgeERC721Mintable token = IErcForgeERC721Mintable(
            contractAddress
        );
        token.mint{value: msg.value - fee}(to);
    }

    function mintERC1155(
        address to,
        address contractAddress,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address referrer,
        bytes calldata data
    ) external payable {
        _beforeMint(referrer);

        IErcForgeERC1155Mintable token = IErcForgeERC1155Mintable(
            contractAddress
        );
        token.mint{value: msg.value - fee}(to, ids, amounts, data);
    }

    function withdraw() public {
        uint256 funds;
        if (msg.sender == owner)
            funds = address(this).balance - totalReferrerFunds;
        else {
            funds = _referrerFunds[msg.sender];
            totalReferrerFunds -= funds;
            _referrerFunds[msg.sender] = 0;
        }
        payable(msg.sender).transfer(funds);
    }

    function getBalance(address user) public view returns (uint256) {
        if (user == owner) return address(this).balance - totalReferrerFunds;
        else return _referrerFunds[user];
    }
}