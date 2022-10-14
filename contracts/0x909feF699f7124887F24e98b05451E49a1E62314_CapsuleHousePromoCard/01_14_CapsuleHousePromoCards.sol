// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';


contract CapsuleHousePromoCard is ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    string[] uris;
    using ECDSA for bytes32;
    mapping(address => bool) hasClaimed;

    function initialize(string[] memory _uris)  public initializer {
        __ERC1155_init("");
        __Pausable_init();
        __Ownable_init();
        uris = _uris;
    }

    function mint(
        bytes32 hash,
        bytes memory signature,
        uint256 _time
    ) external payable whenNotPaused{
        require(_verify(hash, signature), "Signature invalid.");
        require(
            _hash(msg.sender, _time) == hash,
            "Hash invalid."
        );
        require(!hasClaimed[msg.sender], "You have already claimed your cards.");
        hasClaimed[msg.sender] = true;

        uint256 id1 = generateRandomNumber(0) ;
        uint256 id2 = generateRandomNumber(id1);
        _mint(msg.sender, id1 % 12, 1, "");
        _mint(msg.sender, id2 % 12, 1, "");
    }

    function isClaimed(address _address) public view returns(bool){
        return hasClaimed[_address];
    }
    
    function generateRandomNumber(uint256 seed) private view returns (uint256) {
        uint256 random = uint256(
			keccak256(
				abi.encodePacked(
					msg.sender,
					block.coinbase,
					block.difficulty,
					block.gaslimit,
					block.timestamp,
                    seed
				)
			)
		);
        return random;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_tokenId < uris.length, "URI query for nonexistent token");
        require(_tokenId > 0, "URI query for nonexistent token");
        
        return uris[_tokenId];
    }

    function setURIs(string[] memory _newURIs) public onlyOwner {
        uris = _newURIs;
    }

    function _hash(address _address, uint256 _time) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _time));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return (_recover(signedHash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.recover(signature);
    }
}