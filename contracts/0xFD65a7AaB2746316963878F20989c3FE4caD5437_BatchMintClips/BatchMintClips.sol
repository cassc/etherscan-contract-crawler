/**
 *Submitted for verification at Etherscan.io on 2023-05-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface Clip {
    function mintClips() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0x21CD24Ef618e5890a0C7640429fe9DB0c247628B);
        clip.mintClips();
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    constructor() {
        owner = msg.sender;
    }

    function batchMint(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0x21CD24Ef618e5890a0C7640429fe9DB0c247628B);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 95 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}