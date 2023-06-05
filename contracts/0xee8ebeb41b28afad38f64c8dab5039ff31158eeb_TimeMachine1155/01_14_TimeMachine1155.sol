// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TimeMachine1155 is Ownable, ERC1155Supply {
    using Strings for uint256;
    using ECDSA for bytes32;

    address private signer = 0xF489952211c7c8070a3E3f3e0243E36f727db7F8;
    address private modifyingContract;

    string public baseTokenURI;
    string public name = "CC Time Machine Potion";

    bool public isClaimOpen = false;

    mapping(address => mapping(uint256 => uint256)) public modifiersMinted;

    event MintTimeMachine(address indexed _owner, uint indexed _tokenId, uint _count);

    constructor()
        ERC1155("") {
    }

    modifier claimIsOpen {
        require(isClaimOpen, "Claim not open");
        _;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    function claim(uint256 _tokenId, uint256 _count, bytes memory _signature) external claimIsOpen {
        address _claimer = _msgSender();
        require(modifiersMinted[_claimer][_tokenId] == 0, "Already claimed");

        address _signer = verifyClaim(_claimer, _tokenId, _count, _signature);
        require(signer == _signer, "Not authorized to claim");

        for (uint256 i = 0; i < _count; i++) {
            _mint(_claimer, _tokenId, 1, "");
        }
        modifiersMinted[_claimer][_tokenId] += _count;

        emit MintTimeMachine(_claimer, _tokenId, _count);
    }

    function verifyClaim(address _claimer, uint256 _tokenId, uint256 _count, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(keccak256(abi.encode(_claimer, _tokenId, _count)), _signature);
    }

    function setModifyingContract(address _addr) external onlyOwner {
        modifyingContract = _addr;
    }

    function burnTimeMachine(address _from, uint256 _tokenId, uint256 _amount) external {
        require(msg.sender == modifyingContract, "Invalid burner address");
        _burn(_from, _tokenId, _amount);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setClaimOpen(bool _isClaimOpen) external onlyOwner {
        isClaimOpen = _isClaimOpen;
    }

    function setSigner(address _addr) external onlyOwner {
        signer = _addr;
    }
}