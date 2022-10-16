// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./token.sol";

contract PlaygroundPass is ERC721A, Ownable {
    bool public isActive = false;

    string private baseURI;
    address private withdrawalAddress;

    address public keyContractAddress;
    address public lockContractAddress;

    uint256 public amountForDevs = 50 - 1;
    bool private devMinted = false;

    Token private keyToken;
    Token private lockToken;

    constructor(
        string memory baseTokenURI,
        address _withdrawalAddress,
        address _keyContractAddress,
        address _lockContractAddress
        ) ERC721A("PlaygroundPass", "PASS")
    {
        baseURI = baseTokenURI;
        withdrawalAddress = _withdrawalAddress;
        keyToken = Token(_keyContractAddress);
        lockToken = Token(_lockContractAddress);
        _mint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setKeyContract(address _keyContractAddress) external onlyOwner {
        keyContractAddress = _keyContractAddress;
    }

    function setLockContract(address _lockContractAddress) external onlyOwner {
        lockContractAddress = _lockContractAddress;
    }

    function toggleStatus() external onlyOwner {
        isActive = !isActive;
    }

    function devMint() external onlyOwner {
        require(!devMinted, "ALREADY MINTED FOR DEVS");
        devMinted = true;
        _mint(msg.sender, amountForDevs);
    }

    function unlockClaim(uint256 keyId, uint256 lockId) external callerIsUser {
        require(isActive, "UNLOCKING IS NOT ACTIVE");
        require(keyId == lockId, "IDS DO NOT MATCH");
        require(
            keyToken.ownerOf(keyId) == msg.sender,
            "YOU DO NOT OWN THIS KEY"
        );
        require(
            lockToken.ownerOf(lockId) == msg.sender,
            "YOU DO NOT OWN THIS LOCK"
        );
        keyToken.burn(keyId);
        lockToken.burn(lockId);
        _mint(msg.sender, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}