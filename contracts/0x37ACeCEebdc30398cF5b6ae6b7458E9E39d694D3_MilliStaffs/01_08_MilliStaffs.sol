// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MilliStaffs is ERC721A, Ownable, Pausable {
    using ECDSA for bytes32;

    string public baseURI;
    uint256 public _tokenSupply;
    address public constant _signer =
        0xdC55Ee0780a776B01ecbE0110daefa30705fE88a;

    event Onboarded(address staff, uint256 quantity);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI)
        ERC721A("Milliway Staffs", "MilliStaff")
    {
        baseURI = initBaseURI;
        _pause();
    }

    function _hash(string calldata salt, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        pure
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function onboard(
        uint256 quantity,
        string calldata salt,
        bytes calldata signature
    ) external {
        require(tx.origin == msg.sender, "Only EOA.");
        require(_verify(_hash(salt, msg.sender), signature), "Invalid token.");

        _safeMint(msg.sender, quantity);

        emit Onboarded(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function reserve(address[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid address");
            _safeMint(recipients[i], 1);
        }
    }
}