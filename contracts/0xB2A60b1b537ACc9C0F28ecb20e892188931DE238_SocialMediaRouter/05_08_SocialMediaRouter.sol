pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SocialMediaRouter is Ownable {
    address public bondSigner;

    struct Account {
        address payable ownerAddress;
        uint256 nonce;
    }

    mapping(string => mapping(string => Account)) public accounts;

    function getAccount(string calldata serviceId, string calldata userId)
        public
        view
        returns (Account memory)
    {
        return accounts[serviceId][userId];
    }

    function getAddress(string calldata serviceId, string calldata userId)
        public
        view
        returns (address)
    {
        return accounts[serviceId][userId].ownerAddress;
    }

    function addAccount(
        bytes memory signature,
        address accountAddress,
        string memory serviceId,
        string memory userId,
        uint256 nonce
    ) public {    
        bytes32 _hash = keccak256(
            abi.encodePacked(accountAddress, nonce, serviceId, userId)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(_hash);
        address receivedAddress = ECDSA.recover(message, signature);
        require(
            receivedAddress != address(0) && receivedAddress == bondSigner,
            "Bond Signer not verified"
        );
        require(nonce > accounts[serviceId][userId].nonce, "Nonce is too low");
        accounts[serviceId][userId] = Account(payable(accountAddress), nonce);
    }

    function setBondSigner(address _bondSigner) public onlyOwner {
        bondSigner = _bondSigner;
    }
}