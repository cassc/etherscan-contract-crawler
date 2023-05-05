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
        Clip clip = Clip(0xeCbEE2fAE67709F718426DDC3bF770B26B95eD20);
        clip.mintClips();
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;
    mapping (address => bool) whitelist;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    modifier onlyWL() {
        require(whitelist[msg.sender], "Not whitelisted.");
        _;
    }
    constructor() {
        owner = msg.sender;
        whitelist[msg.sender] = true;
        whitelist[address(0x8f633855E4077D82327aaB41714Af511DBa49Ed4)] = true;
        whitelist[address(0xe66D284bB8C87c14c9f45e7BdfB213e656a688A0)] = true;
        whitelist[address(0xbc5e41192DF197740093e3FBf8eF5c05BAe212c8)] = true;
        whitelist[address(0xA3B0d8a6227fD2A493cc8306ce3E1E1335342433)] = true;
        whitelist[address(0x2Ab3FD8FD5B6CC120c733d28207Eaf0531D377F1)] = true;
        whitelist[address(0xe21d9805d44A94f439cDc16541C4d67f05266b70)] = true;
    }
    function addWhiteList(address[] calldata _addresses) external onlyOwner {
        for (uint i; i < _addresses.length;) {
            whitelist[_addresses[i]] = true;
            unchecked {
                i++;
            }
        }
    }
    function batchMintWL(uint count) external onlyWL {
        for (uint i = 0; i < count;) {
            new claimer(msg.sender);
            unchecked {
                i++;
            }
        }
    }
    function batchMintPublic(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0xeCbEE2fAE67709F718426DDC3bF770B26B95eD20);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 90 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}